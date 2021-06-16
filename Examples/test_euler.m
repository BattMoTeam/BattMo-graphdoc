clear all
close all

% setup mrst modules
mrstModule add ad-core multimodel mrst-gui battery mpfa

mrstVerbose off

% We create an instance of BatteryInputParams
paramobj = BatteryInputParams();

% We parse a json input file to populate paramobj
p = mfilename('fullpath');
p = fileparts(p);
filename = fullfile(p, '../Battery/lithiumbattery.json');
paramobj = jsonfileToParams(paramobj, filename);

% some shortcuts
ne      = 'NegativeElectrode';
pe      = 'PositiveElectrode';
eac     = 'ElectrodeActiveComponent';
cc      = 'CurrentCollector';
elyte   = 'Electrolyte';
thermal = 'ThermalModel';

% Setup battery
modelcase = '1D';

switch modelcase

  case '1D'

    gen = BatteryGenerator1D();
    paramobj = gen.updateBatteryInputParams(paramobj);
    paramobj.(ne).(cc).EffectiveElectricalConductivity = 100;
    paramobj.(pe).(cc).EffectiveElectricalConductivity = 100;
    schedulecase = 3;
    
    paramobj.(thermal).externalHeatTransferCoefficient = 1000;
    paramobj.(thermal).externalTemperature = paramobj.initT;

  case '2D'

    gen = BatteryGenerator2D();
    paramobj = gen.updateBatteryInputParams(paramobj);
    schedulecase = 1;

    paramobj.(ne).(cc).EffectiveElectricalConductivity = 1e5;
    paramobj.(pe).(cc).EffectiveElectricalConductivity = 1e5;
    
    paramobj.(thermal).externalTemperature = paramobj.initT;
    paramobj.SOC = 0.99;
    
    tfac = 1; % used in schedule setup
  
  case '3D'

    gen = BatteryGenerator3D();
    
    fac = 1; 
    gen.facx = fac; 
    gen.facy = fac; 
    gen.facz = fac;
    gen = gen.applyResolutionFactors();
    paramobj = gen.updateBatteryInputParams(paramobj);
    
    schedulecase = 5;
    
    paramobj.(thermal).externalTemperature = paramobj.initT;
    
end


%%  The model is setup

model = Battery(paramobj);


%% We setup the schedule

% Value used in rampup function, see currentSource.
tup = 0.1;

switch schedulecase

  case 1

    % Schedule with two phases : activation and operation
    % 
    % Activation phase with exponentially increasing time step
    n = 25; 
    dt = []; 
    dt = [dt; repmat(0.5e-4, n, 1).*1.5.^[1:n]']; 
    % Operation phase with constant time step
    n = 40; 
    dt = [dt; repmat(2e-1*hour, n, 1)]; 
    
    % Time scaling can be adding using variable tfac
    times = [0; cumsum(dt)]*tfac; 
    
  case 2

    % Schedule used in activation test 
    n = 10;
    dt = rampupTimesteps(1.5*tup, tup/n, 10);
    times = [0; cumsum(dt)]; 

  case 3
    
    % Schedule adjusted for 1D case
    dt1 = rampupTimesteps(0.1, 0.1, 5);
    dt2 = 0.1*hour*ones(30, 1);
    dt = [dt1; dt2];
    times = [0; cumsum(dt)]; 

  case 4

    % Schedule with two phases : activation and operation
    % 
    % Activation phase with exponentially increasing time step
    n = 5; 
    dt = []; 
    dt = [dt; repmat(0.5e-4, n, 1).*1.5.^[1:n]']; 
    % Operation phase with constant time step
    %n = 24; 
    %dt = [dt; dt(end).*2.^[1:n]']; 
    %dt = [dt; repmat(dt(end)*1.5, floor(n*1.5), 1)]; 
    
    % Time scaling can be adding using variable tfac
    times = [0; cumsum(dt)]*tfac; 

  case 5

    % Schedule with two phases : activation and operation
    % 
    % Activation phase with exponentially increasing time step
    n = 25; 
    dt = []; 
    dt = [dt; repmat(0.5e-4, n, 1).*1.5.^[1:n]']; 
    % Operation phase with constant time step
    n = 40; 
    dt = [dt; repmat(4e-1*hour, n, 1)]; 
    
    % Time scaling can be adding using variable tfac
    times = [0; cumsum(dt)]; 
    
end


%%  We compute the cell capacity
C = computeCellCapacity(model);
% C Rate
CRate = 1/5;
inputI  = (C/hour)*CRate;
inputE = 3.6;


%% We setup the schedule 

tt = times(2 : end); 

step = struct('val', diff(times), 'control', ones(numel(tt), 1)); 

pe = 'PositiveElectrode';
cc = 'CurrentCollector';
stopFunc = @(model, state, state_prev) (state.(pe).(cc).E < 2.0); 

srcfunc = @(time, I, E) rampupSwitchControl(time, tup, I, E, inputI, inputE);
control = repmat(struct('src', srcfunc, 'stopFunction', stopFunc), 1, 1); 
schedule = struct('control', control, 'step', step); 

%%  We setup the initial state
initstate = model.setupInitialState(); 

% Setup nonlinear solver 

nls = NonLinearSolver(); 

% Change default maximum iteration number in nonlinear solver
nls.maxIterations = 10; 
% Change default behavior of nonlinear solver, in case of error
nls.errorOnFailure = false; 
% Change default tolerance for nonlinear solver
model.nonlinearTolerance = 1e-4;
use_diagonal_ad = false;
if(use_diagonal_ad)
    model.AutoDiffBackend = DiagonalAutoDiffBackend(); 
    model.AutoDiffBackend.useMex = true; 
    model.AutoDiffBackend.modifyOperators = true; 
    model.AutoDiffBackend.rowMajor = true; 
    model.AutoDiffBackend.deferredAssembly = false; % error with true for now
end

use_iterative = false; 
if(use_iterative)
    % nls.LinearSolver = LinearSolverBattery('method', 'iterative'); 
    % nls.LinearSolver = LinearSolverBattery('method', 'direct'); 
    mrstModule add agmg
    nls.LinearSolver = LinearSolverBattery('method', 'agmg', 'verbosity', 1);
    nls.LinearSolver.tol = 1e-3;
    nls.verbose = 10
end
model.nonlinearTolerance = 1e-5; 
model.verbose = false;

% Run simulation

doprofiling = false;
if doprofiling
    profile off
    profile on
end

[wellSols, states, report] = simulateScheduleAD(initstate, model, schedule,...
                                                'OutputMinisteps', true,...
                                                'NonLinearSolver', nls); 
if doprofiling
    profile off
    profile report
end 


%%  Process output

ind = cellfun(@(x) not(isempty(x)), states); 
states = states(ind);
Enew = cellfun(@(x) x.(pe).(cc).E, states); 
Inew = cellfun(@(x) x.(pe).(cc).I, states);
time = cellfun(@(x) x.time, states); 

%%

figure
plot((time/hour), Enew, '*-', 'linewidth', 3)
title('Potential (E)')
xlabel('time (hours)')

figure
plot((time/hour), Inew, '*-', 'linewidth', 3)
title('Current (I)')
xlabel('time (hours)')

return

%% more plotting (case dependent)

switch modelcase
  case '1D'
    % plot1D;
  case '2D'
    plotThermal(model, states);
    plot2Dconc;
  case '3D'
    plot3D;
    plot3Dconc;
    plot3Dphi;
end