%clear all
%% Pick source JSON files for generating model 

%JSON file cases
casenames = {'p1d_40',
             'p2d_40'};
casenames = casenames{2};

% casenames = {'3d_demo_case'};
% casenames = {'4680_case'};

%JSON file folder

battmo_folder    = battmoDir();
battmo_jl_folder = fullfile(battmo_folder, '..', BattMo.jl');
jsonfolder       = fullfile(battmo_jl_folder, 'test','battery','data','jsonfiles');

%% Setup model from Matlab

%If true a reference solution will be generated. 
generate_reference_solution = true;
export = setupMatlabModel(casenames, jsonfolder, generate_reference_solution);

%% Setup Julia server

man = ServerManager('debug', true);

%% Call Julia 

%Set up keyword arguments. See run_battery in mrst_utils.jl for details
kwargs =struct('use_p2d'     , true , ...
               'extra_timing', false, ...
               'general_ad'  , true);

man.load('data'         , export  , ...
         'kwargs'       , kwargs  , ...
         'inputType'    , 'Matlab', ...
         'use_state_ref', generate_reference_solution);

result = man.run_battery();
result = result{1}; 

%% Plot results

figure()
% Results generated by BattMo.jl
voltage = cellfun(@(x) x.Phi, {result.states.BPP}); 
time = cumsum(result.extra.timesteps); 
plot(time, voltage, "DisplayName", "BattMo Julia (Matlab model)", LineWidth = 2)

if generate_reference_solution
    hold on
    E = cellfun(@(state) state.Control.E, export.states); 
    time = cellfun(@(state) state.time, export.states); 
    plot(time, E, "DisplayName", "BattMo Matlab", LineWidth = 2, LineStyle = " -- ")
end

legend
grid on

