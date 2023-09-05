classdef ServerManager < handle 

    properties
        
        options
        base_call
        use_folder
        call_history = {}
        
    end
    
    properties (Hidden)
        
        cleanup
        
    end
    
    methods
        
        function manager    = ServerManager(varargin)
        % Parse inputs

            serverFolder = fileparts(mfilename('fullpath'));

            p = inputParser;
            addParameter(p, 'julia'        , try_find_julia_runtime, @ischar);
            addParameter(p, 'project'      , fullfile(serverFolder , 'RunFromMatlab') , @ischar);
            addParameter(p, 'script_source', fullfile(serverFolder , 'RunFromMatlab','api','DaemonHandler.jl'), @ischar);
            addParameter(p, 'startup_file' , 'no'                  , @ischar);
            addParameter(p, 'threads'      , 'auto'                , @validate_threads);
            addParameter(p, 'procs'        , 2                     , @(x) validateattributes(x, {'numeric'}, {'integer'}));
            addParameter(p, 'cwd'          , serverFolder          , @ischar);
            addParameter(p, 'port'         , 3000                  , @(x) validateattributes(x, {'numeric'}, {'scalar', 'integer', 'positive'}));
            addParameter(p, 'shared'       , true                  , @(x) validateattributes(x, {'logical'}, {'scalar'}));
            addParameter(p, 'print_stack'  , true                  , @(x) validateattributes(x, {'logical'}, {'scalar'}));
            addParameter(p, 'async'        , true                  , @(x) validateattributes(x, {'logical'}, {'scalar'}));
            addParameter(p, 'gc'           , true                  , @(x) validateattributes(x, {'logical'}, {'scalar'}));
            addParameter(p, 'debug'        , false                 , @(x) validateattributes(x, {'logical'}, {'scalar'}));

            parse(p, varargin{:});
            manager.options=p.Results;
            
            % We will save all files related to the execution of the server
            % in a folder on the form Server_id=<port>
            manager.use_folder = fullfile(manager.options.cwd, ['Server_id=', num2str(manager.options.port)]);
            [~, ~] = mkdir(manager.use_folder);
            
            %Save options in file to be read in Julia
            op = manager.options;
            opt_file = fullfile(manager.use_folder, 'options.mat');
            save(opt_file, "op");
       
            % Build DaemonMode call:

            % Manage options
            manager.base_call = [manager.options.julia, ' '                              , ...
                                 '--startup-file='    , manager.options.startup_file, ' ', ...
                                 '--project='         , manager.options.project     , ' ', ...
                                 '--procs='           , num2str(manager.options.procs), ' ', ...
                                 '--threads='         , manager.options.threads];
            
            %Ensure that project is instantiated
            instaniate_call = '"using Pkg; Pkg.instantiate();"';
            manager.DaemonCall(instaniate_call);

            % Start server
            manager.startup();

            % Read options in Julia
            option_call = ['"using Revise, DaemonMode; runargs(', ...
                           num2str(manager.options.port),')" ', manager.options.script_source, ...
                           ' -load_options ', opt_file];
            
            manager.DaemonCall(option_call);

            % Shut down server on cleanup
            manager.cleanup = onCleanup(@() delete(manager));
            
        end
        
        function load(manager, varargin)
            % Load data onto server (requires shared=true to make sense)
            % Add warning if shared is false

            opts = struct('data'         , []      , ...
                          'kwargs'       , []      , ...
                          'inputType'    , 'Matlab', ...
                          'use_state_ref', false   , ...
                          'inputFileName', []);
            opts = merge_options(opts, varargin{:});
            
            data          = opts.data;
            kwargs        = opts.kwargs;
            inputType     = opts.inputType;
            use_state_ref = opts.use_state_ref;
            
            loadingDataFilename = [tempname, '.mat'];
            
            switch opts.inputType
              case 'Matlab'
                inputFileName = loadingDataFilename;
              case 'JSON'
                inputFileName = opts.inputFileName;
              otherwise
                error('inputType not recognized');
            end
            
            save(loadingDataFilename, ...
                 'data'             , ...
                 'kwargs'           , ...
                 'inputType'        , ...
                 'use_state_ref'    , ...
                 'inputFileName');
            
            call_load = ['"using Revise, DaemonMode; runargs(', num2str(manager.options.port), ')" ', manager.options.script_source, ...
                ' -load ', loadingDataFilename];
            if manager.options.debug
                fprintf("Loading data into Julia \n")
            end
            manager.DaemonCall(call_load);
            
        end

        function result = run_battery(manager)

            outputFileName = [tempname,'.json'];

            %Call DaemonMode.runargs 
            call_battery = ['"using Revise, DaemonMode; runargs(',num2str(manager.options.port) ,')" ', manager.options.script_source, ...
                            ' -run_battery ', outputFileName];
            
            if manager.options.debug
                fprintf("Calling run battery \n")
            end
            
            st = manager.DaemonCall(call_battery);
            %Read only if system call completed succesfully
            if st
                % Read julia output
                fid = fopen(outputFileName);
                raw = fread(fid, inf); 
                str = char(raw'); 
                fclose(fid); 
                result = {jsondecode(str)};

                if manager.options.gc
                    delete(outputFileName);
                end
            else
                result=[];
            end
            
        end
        
        function [f,locations]=iterate_values(manager, param_list)
            %Run parameter values as flags to julia script if shared is
            %true. Possible enable same procedure entirely done in Julia
            cmd = ['"using Revise, DaemonMode; runargs(',num2str(manager.options.port),')" ', ...
                manager.options.script_source, ' -matlab-sweep '];
            param_flags = '';
            detach =' &';
            
            locations = manager.parameterSweepInternal(param_list,param_flags,cmd,detach, []);
            
            
            w = waitbar(0,'Please wait ...');
            for idx = 1:length(locations(:,1))
                f(idx) = parfeval(@findFile,1,locations(idx,:),true); 
            end
            afterEach(f,@(~)updateWaitbar(w),0);
            afterAll(f,@(~)delete(w),0);
        end

        function ret = parameterSweepInternal(manager,param_list, param_flags,cmd, detach,out)
            ret=out;
            init = param_flags;
            for i = 1:length(param_list(1).values)
                param_flags = [init , ' ', param_list(1).parameter_name, ' ', num2str(param_list(1).values(i))]; 
                if length(param_list)>1
                    tmp = manager.parameterSweepInternal(param_list(2:end),param_flags,cmd,detach,ret);
                    ret = [ret ; tmp];
                else
                    tmp = [tempname, '.json'];
                    manager.DaemonCall([cmd, tmp, ' ', param_flags, detach]);
                    ret=[ret; tmp];
                end
            end
        end

%         function states = collectParameterSweep(manager,locations, gc)
%             states=[];
%             count = 0;
%             n = length(locations);
%         
%             for i = 1:n
%                 if exist(locations(i),'file')
%                     count = count + 1;
%         
%                     %Read file
%                     fid = fopen(locations(i));
%                     raw = fread(fid, inf); 
%                     str = char(raw'); 
%                     fclose(fid); 
%                     states = [states,jsondecode(str)];
%         
%                     if gc
%                         delete(locations(i));
%                     end
%                 end
%                 waitbar(count/n,"Collecting results...")
%                 pause(0.1);
%             end
%         end

        function startup(manager)
            
            if ~ping_server(manager.options) %If server is already live, do nothing
                % Create DaemonMode.serve call
                startup_call = ['"using Revise, DaemonMode; serve(', ...
                                num2str(manager.options.port), ', ', jl_bool(manager.options.shared), ...
                                ', print_stack=', jl_bool(manager.options.print_stack),')" &'];
                %, ...
                 %               ', async=', jl_bool(manager.options.async),')" &'];
                
                if manager.options.debug
                    fprintf("Starting Julia server \n")
                end

                manager.DaemonCall(startup_call);
                
                % Check if server is active. Ensures that we do not make
                % calls to the server until it is ready
                while ~ping_server(manager.options)
                    pause(0.1);
                end
            end
            
        end

        function shutdown(manager)
        % Close server if active
            kill_call= ['"using Revise, DaemonMode; sendExitCode(', num2str(manager.options.port), ...
                ');"'];
            cmd = [manager.base_call, ' -e ', kill_call];
            system(cmd)
            if manager.options.debug
                fprintf("Shutting down server \n");
            end
            
        end
        
        function restart(manager, varargin)
        % Close server and restart
            
            kill_call= ['"using Revise, DaemonMode; sendExitCode(', num2str(manager.options.port), ...
                ');"'];
            cmd = [manager.base_call, ' -e ', kill_call];
            system(cmd)
            if manager.options.debug
                fprintf("Shutting down server \n");
            end
            manager.startup()
            
        end

        function success = DaemonCall(manager, call)

            cmd = [manager.base_call, ' -e ', call];
            
            if manager.options.debug
                fprintf("Call to julia: %s \n", cmd);
            end

            try 
                st=system(cmd);
                success=true;
            catch
                fprintf("System call failed: \n %s", cmd);
                success=false;
            end
            
            manager.call_history{end+1} = cmd;
            
        end

        function sweep(manager,exper,values,name)
            save_folder = fullfile(manager.use_folder,name);
            [~,~]=mkdir(save_folder);
            options_file = [save_folder,'/',name,'.mat'];
            experiment=exper;
            save(options_file, "save_folder","experiment","values")
            sweep_source = fullfile(fileparts(mfilename('fullpath')), 'RunFromMatlab','api','ParameterSweepControl.jl');
            sweep_call=['"using Revise, DaemonMode; runargs(',num2str(manager.options.port) ,')" ', sweep_source, ' ', options_file, ' &'];
            manager.DaemonCall(sweep_call)
            
        end
    end
end


% Determine correct julia source
function runtime = try_find_julia_runtime()

    % Default value
    runtime = 'julia';

    try
        if isunix
            [st, res] = system('which julia');
        elseif ispc
            [st, res] = system('where julia');
        else
            return % default to 'julia'
        end
        if st == 0
            runtime = strtrim(res);
        end
    catch me
        % ignore error; default to 'julia'
    end

end

function str = jl_bool(bool)

        if bool
            str = 'true';
        else
            str = 'false';
        end
    
end

function succ = ping_server(opts)

    try
        tcpclient('127.0.0.1', opts.port);
        succ = true;
    catch me
        if strcmpi(me.identifier, 'MATLAB:networklib:tcpclient:cannotCreateObject')
            succ = false;
        else
            rethrow(me)
        end
    end

end

function count = checkSweepStatus(locations)
    count = 0;
    n = length(locations);
    read = zeros(n);

    while count < n
        for i = 1:n
            if exist(locations(i),'file') && ~read(i)
                count = count + 1;
                read(i)=true;
            end
        end
        waitbar(count/n,"Parameter sweep progress...")
    end
end

function state = findFile(loc,gc)
    while ~exist(loc,'file')
        pause(0.1);
    end

    %Read file
    fid = fopen(loc);
    raw = fread(fid, inf); 
    str = char(raw'); 
    fclose(fid); 
    state = jsondecode(str);

    if gc
        delete(loc)
    end
end

function updateWaitbar(w)
    % Update a waitbar using the UserData property.

    % Check if the waitbar is a reference to a deleted object
    if isvalid(w)
        % Increment the number of completed iterations 
        w.UserData(1) = w.UserData(1) + 1;

        % Calculate the progress
        progress = w.UserData(1) / w.UserData(2);

        % Update the waitbar
        waitbar(progress,w);
    end
end
