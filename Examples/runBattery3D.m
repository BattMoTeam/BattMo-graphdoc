% Include presentation of the test case (use rst format)

% load MRST modules
mrstModule add ad-core multimodel mrst-gui battery mpfa

% The input parameters can be given in json format. The json file is read and used to populate the paramobj object.
jsonstruct = parseBatmoJson('JsonDatas/lithiumbattery.json');
paramobj = BatteryInputParams(jsonstruct);

% Some shortcuts used for the sub-models
ne      = 'NegativeElectrode';
pe      = 'PositiveElectrode';
eac     = 'ElectrodeActiveComponent';
cc      = 'CurrentCollector';
elyte   = 'Electrolyte';
thermal = 'ThermalModel';

%% We setup the battery geometry.
% Here, we use a 3D model and the class BatteryGenerator3D already contains the discretization parameters
gen = BatteryGenerator3D();
paramobj = gen.updateBatteryInputParams(paramobj);

%%  The Battery model is initialized by sending paramobj to the Battery class constructor

model = Battery(paramobj);

%% We compute the cell capacity and chose a discharge rate
C = computeCellCapacity(model);
CRate = 1;
inputI = (C/hour)*CRate; % current 

%% We setup the schedule
% We use different time step for the activation phase (small time steps) and the following discharging phase

% We use exponentially increasing time step for the activation phase
n  = 25;
dt = [];
dt = [dt; repmat(0.5e-4, n, 1).*1.5.^[1 : n]'];
% We choose time steps for the rest of the simulation (discharge phase)
totalTime = 1.4*hour/CRate;
n     = 40; 
dt    = [dt; repmat(totalTime/n, n, 1)]; 
times = [0; cumsum(dt)]; 
tt    = times(2 : end); 
step  = struct('val', diff(times), 'control', ones(numel(tt), 1)); 

% We set up a stopping function. Here, the simulation will stop if the output voltage reach a value smaller than 2. This
% stopping function will not be triggered in this case as we switch to voltage control when E=3.6 (see value of inputE
% below).
pe = 'PositiveElectrode';
cc = 'CurrentCollector';
stopFunc = @(model, state, state_prev) (state.(pe).(cc).E < 2.0); 

tup = 0.1; % rampup value for the current function, see rampupSwitchControl
inputE = 3; % Value when current control switches to voltage control
srcfunc = @(time, I, E) rampupSwitchControl(time, tup, I, E, inputI, inputE);

% we setup the control by assigning a source and stop function.
control = repmat(struct('src', srcfunc, 'stopFunction', stopFunc), 1, 1); 

% This control is used to set up the schedule
schedule = struct('control', control, 'step', step); 

%%  We setup the initial state
initstate = model.setupInitialState(); 

% Setup nonlinear solver 
nls = NonLinearSolver(); 
% Change default maximum iteration number in nonlinear solver
nls.maxIterations = 10; 
% Change default behavior of nonlinear solver, in case of error
nls.errorOnFailure = false; 
% Timestep selector
nls.timeStepSelector = StateChangeTimeStepSelector('TargetProps', ...
                                                  {{'PositiveElectrode', 'CurrentCollector', 'E'}}, ...
                                                  'targetChangeAbs', 0.03);

% Change default tolerance for nonlinear solver
model.nonlinearTolerance = 1e-5; 
% Set verbosity of the solver (if true, value of the residuals for every equation is given)
model.verbose = false;

% Run simulation
[wellSols, states, report] = simulateScheduleAD(initstate, model, schedule, 'OutputMinisteps', true, 'NonLinearSolver', nls); 

%%  We process output and recover the output voltage and current from the output states.
ind = cellfun(@(x) not(isempty(x)), states); 
states = states(ind);
Enew = cellfun(@(x) x.(pe).(cc).E, states); 
Inew = cellfun(@(x) x.(pe).(cc).I, states);
time = cellfun(@(x) x.time, states); 

%% We plot the the output voltage and current

figure
plot((time/hour), Enew, '*-', 'linewidth', 3)
title('Potential (E)')
xlabel('time (hours)')

figure
plot((time/hour), Inew, '*-', 'linewidth', 3)
title('Current (I)')
xlabel('time (hours)')

