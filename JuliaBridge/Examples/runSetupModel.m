clear jlcall_mod
close all

%% Pick source JSON files for generating model 

%JSON file cases
casenames = {'p1d_40',
             'p2d_40'};
casenames = casenames{2};

% casenames = {'3d_demo_case'};
% casenames = {'4680_case'};

%JSON file folder
battmo_folder = fileparts(mfilename('fullpath'));
battmo_jl_folder = fullfile(battmo_folder, '../../../BattMo.jl');
jsonfolder = fullfile(battmo_jl_folder, 'test/battery/data/jsonfiles/');

if exist('setupMatlabModel') == 0
        adddir = fullfile(battmo_folder, '../GenerateModel');
        addpath(adddir);
        fprintf('Added %s to Matlab path in order to run setupMatlabModel', adddir);
end
%% Setup model from Matlab

%If true a reference solution will be generated. 
generate_reference_solution=true;

export=setupMatlabModel(casenames, jsonfolder, generate_reference_solution);

%% Setup Julia server
jlcall('', ...
     'project', strcat(battmo_folder,'/','../Julia_utils/RunFromMatlab'), ... % activate a local Julia Project 
     'setup', strcat(battmo_folder,'/','../Julia_utils/setup.jl'), ...
     'modules', {'RunFromMatlab'}, ... % load a custom module 
     'threads', 'auto', ... % use the default number of Julia threads
     'restart', false, ... % start a fresh Julia server environment
     'debug',true, ...
     'source', '"https://github.com/Erasdna/MATDaemon.jl.git"' ...
     );

%% Call Julia 

%Set up keyword arguments. See run_battery in mrst_utils.jl for details
kwargs=struct('use_p2d',true, ...
    'extra_timing',false, ...
    'general_ad',true, ...
    'info_level',0);
result=jlcall('RunFromMatlab.run_battery_from_matlab', {export,mfilename('fullpath'), generate_reference_solution},kwargs);

%% Plot results

figure()
% Results generated by BattMo.jl
voltage=cellfun(@(x) x.Phi, {result.states.BPP});
time=cumsum(result.extra.timesteps);
plot(time,voltage,"DisplayName","BattMo Julia (Matlab model)", LineWidth=2)

if generate_reference_solution
  hold on
  E    = cellfun(@(state) state.Control.E, export.states); 
  time = cellfun(@(state) state.time, export.states); 
  plot(time,E,"DisplayName","BattMo Matlab", LineWidth=2, LineStyle="--")
end

legend
grid on

