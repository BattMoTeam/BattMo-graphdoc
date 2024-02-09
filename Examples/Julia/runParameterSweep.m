clear
close all

%% Setup Julia server

man = ServerManager('debug', true, ...
                    'reset', true, ...
                    'threads', 8);

% Set up keyword arguments to be sent to julia solver. See run_battery for details
kwargs = struct('use_p2d'     , true , ...
                'extra_timing', false, ...
                'general_ad'  , true);

%% Setup model from Matlab

jsonfolder = fullfile(battmoDir(), 'Examples', 'JsonDataFiles');
testCase = 'JSON';

switch testCase

  case 'Matlab'

    casenames = {'p1d_40', ...
                 'p2d_40'};
    casenames = casenames{2};

    % casenames = {'3d_demo_case'};
    % casenames = {'4680_case'};

    % If true a reference solution will be generated.
    generate_reference_solution = true;
    export = setupMatlabModel(casenames, jsonfolder, generate_reference_solution);

    man.load('data'         , export  , ...
             'kwargs'       , kwargs  , ...
             'inputType'    , 'Matlab', ...
             'use_state_ref', generate_reference_solution);

  case 'JSON'

    generate_reference_solution = false;
    inputFileName = fullfile(jsonfolder, 'p2d_40_jl.json');

    man.load('kwargs'       , kwargs, ...
             'inputType'    , 'JSON', ...
             'inputFileName', inputFileName);

  otherwise

    error('testCase not recognized');

end

% This must only be defined ONCE. Must be manually deleted before clear all

%%
massFractions = linspace(0.8, 0.95, 10);
massFractionsNE = massFractions;
massFractionsPE = massFractions;
fprintf('Perform the parameter sweep...\n');
tstart = tic;
f = man.sweep('Example', {massFractionsNE, massFractionsPE}, 'demo');
t = toc(tstart);
fprintf('Parameter sweep took %g s\n', t);

%%
ind = [1, floor(numel(massFractions)/2), numel(massFractions)];
start = tic;
res = man.collect_results(f, ind);
toc(start)

%% Plot results

% Results generated by BattMo.jl
if mrstPlatform('octave')
    matlabStates = 'matlab states';
else
    matlabStates = 'matlabStates';
end

figure;

for i = 1:length(ind)
    E = arrayfun(@(state) state.Control.E, res(i).states.(matlabStates));
    time = arrayfun(@(state) state.time, res(i).states.(matlabStates));
    plot(time, E, 'DisplayName', strcat('Parameters=(', num2str(res(i).parameters(1)), ',', num2str(res(i).parameters(2)), ')'), LineWidth=2)
    hold on
end

if generate_reference_solution
    hold on
    E = cellfun(@(state) state.Control.E, export.states);
    time = cellfun(@(state) state.time, export.states);
    plot(time, E, 'DisplayName', 'BattMo Matlab', LineWidth=2, LineStyle='--')
end

legend
grid on



%{
Copyright 2021-2024 SINTEF Industry, Sustainable Energy Technology
and SINTEF Digital, Mathematics & Cybernetics.

This file is part of The Battery Modeling Toolbox BattMo

BattMo is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

BattMo is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with BattMo.  If not, see <http://www.gnu.org/licenses/>.
%}