function [objValue, varargout] = evalObjectiveBattmo(pvec, objFunc, setup, parameters, varargin)
%
% Utility function (for optimization) that simulates a model with parameters obtained from the vector 'pvec' (scaled
% parameters) and computes objective function with the given parameters. The parameters are described with the cell
% array of ModelParameter. if nargout > 1, the function returned also the scaled gradient
%
% SYNOPSIS:
%  objValue                    = evalObjectiveBattmo(p, objFunc, setup, parameters, ['pn', pv, ...]) 
%  [objValue, scaledGradients] = evalObjectiveBattmo(...) 
%
% DESCRIPTION:
%
%  For a given parameter array p, compute mistmach and sensitivities with regards to parameters given  by pvec and described by parameters.
%
% REQUIRED PARAMETERS:
%
%   pvec         - An array containing the parameters' values scaled in unit-interval [0, 1]
%
%   objFunc      - Objective function. The signature of the objective function is
%
%                  objval = objFunc(model, states, schedule, varargin)
%
%                  where optional keyword arguments are
%
%                  - tStep           : if set, only the given time steps are handled. Otherwise, the whole schedule is used.
%                  - ComputePartials : if true, the derivative of the objective functions are also included, see below
%                    
%   setup        - Simulation setup structure containing: state0, model, and schedule.
%    
%   parameters   - cell-array of parameters given as instance of ModelParameter
%
% OPTIONAL PARAMETERS:
%   'gradientMethod'       - Method to calculate the sensitivities/gradient:
%                            'AdjointAD': Compute parameter sensitivities using adjoint simulation  (default)
%                            'PerturbationADNUM': Compute parameter sensitivities using perturbations (first-order forward finite diferences)
%                            'None':              Avoid computing parameters sensitivities
%   'PerturbationSize'     - Cell array with same size as parameters giving size of parameters. If empty default is 1e-7 for all parameters
%   'objScaling'           - scaling value for the objective function objValue/objScaling.
%   'AdjointLinearSolver'  - Subclass of `LinearSolverAD` suitable for solving the
%                            adjoint linear systems.
%   'NonlinearSolver'      - Subclass of `NonLinearSolver` suitable for solving the
%                            non linear systems of the forward model.
%   'Verbose'              - Indicate if extra output is to be printed such as
%                            detailed convergence reports and so on.
%                            detailed convergence reports and so on.
% RETURNS:
%   objValue       - value of the objective function
%   scaledGradient - Scaled gradient of objValue with respect p
%   states         - State at each control step (or timestep if
%                    'OutputMinisteps' is enabled.)
%
% SEE ALSO:
% `evalObjective`, `computeSensitivitiesAdjointAD`, `unitBoxBFGS` 

%{
  Copyright 2009-2021 SINTEF Digital, Mathematics & Cybernetics.

  This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

  MRST is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  MRST is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}

    opt = struct('Verbose'            , mrstVerbose(), ...
                 'gradientMethod'     , 'AdjointAD'  , ...
                 'NonlinearSolver'    , []           , ...
                 'AdjointLinearSolver', []           , ...
                 'PerturbationSize'   , []           , ...
                 'objScaling'         , 1            , ...
                 'enforceBounds'      , true);

    [opt, extra] = merge_options(opt, varargin{:});

    nparam = cellfun(@(x) x.nParam, parameters);
    if opt.enforceBounds
        pvec = max(0, min(1, pvec));
    end
    pvec = mat2cell(pvec, nparam, 1);

    % Create new setup, and set parameter values
    pval = cell(size(parameters));
    setupNew = setup;
    
    for k = 1 : numel(parameters)
        pval{k}  = parameters{k}.unscale(pvec{k});
        setupNew = parameters{k}.setParameter(setupNew, pval{k});
    end

    [wellSols, states] = simulateScheduleAD(setupNew.state0, setupNew.model, setupNew.schedule, ...
                                           'NonLinearSolver', opt.NonlinearSolver             , ...
                                            'Verbose'       , opt.Verbose                     , ...
                                            extra{:});

    objValues = objFunc(setupNew.model, states, setupNew.schedule);
    objValue  = sum(vertcat(objValues{:}))/opt.objScaling ;

    if nargout > 1

        switch opt.gradientMethod
            
          case 'None'

            if nargout > 2
                [varargout{2:3}] = deal(wellSols, states);
            end
            return
            
          case 'AdjointAD'
            
            objh = @(tstep, model, state, computeStatePartial) objFunc(model, states, setupNew.schedule, ...
                                                                       'ComputePartials', computeStatePartial , ...
                                                                       'tStep'          , tstep, ...
                                                                       'state'          , state);
            nms = applyFunction(@(x) x.name, parameters);

            sens = computeSensitivitiesAdjointADBattmo(setupNew, states, parameters, objh, ...
                                                       'LinearSolver', opt.AdjointLinearSolver);            

            gradient = cellfun(@(nm) sens.(nm), nms, 'uniformoutput', false);

            % do scaling of gradient
            for k = 1 : numel(nms)
                scaledGradient{k} = parameters{k}.scaleGradient(gradient{k}, pval{k});
            end
            
            varargout{1} = vertcat(scaledGradient{:})/opt.objScaling;
            
          case 'PerturbationADNUM'
            % Do manual perturbation of the defined control variables
            
            pertsize = opt.PerturbationSize;
            if isempty(pertsize)
                usedefault = true;
                % default value is 1e-7
            else
                usedefault = false;
            end
            
            parfor iparam = 1 : numel(parameters)
                
                if usedefault
                    eps_pert = 1e-7;
                else
                    eps_pert = pertsize{iparam};
                end
                
                np = numel(pvec{iparam});
                val = nan(np, 1);

                    for i = 1 : np
                        pert_pvec =  perturb(pvec, iparam, i, eps_pert);
                        val(i) = evalObjectiveBattmo(pert_pvec, objFunc, setupNew, parameters, ...
                                                     'gradientMethod' , 'None'             , ...
                                                     'NonlinearSolver', opt.NonlinearSolver, ...
                                                     'objScaling'     , opt.objScaling     , ...
                                                     'enforceBounds'  , false);
                    end

                
                scaledGradient{iparam} = (val - objValue)./eps_pert;
                
            end

            varargout{1} = vertcat(scaledGradient{:});
            
          otherwise
            
            error('Greadient method %s is not implemented',opt.gradientMethod);
            
        end
        
        
    end

    if nargout > 2
        [varargout{2:3}] = deal(wellSols, states);
    end

    if nargout > 4
        varargout{4} =  setupNew;
    end
end


% Utility function to perturb the parameter array in coordinate i with eps_pert
function pert_pvec = perturb(pvec, iparam, i, eps_pert)

    pert_pvec = pvec;
    pert_pvec{iparam}(i) = pert_pvec{iparam}(i) + eps_pert;
    pert_pvec = cell2mat(pert_pvec);
    
end


    



%{
Copyright 2021-2023 SINTEF Industry, Sustainable Energy Technology
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
