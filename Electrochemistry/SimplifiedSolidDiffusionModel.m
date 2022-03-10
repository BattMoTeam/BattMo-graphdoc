classdef SimplifiedSolidDiffusionModel < BaseModel

    properties

        % Physical constants
        constants = PhysicalConstants();

        % Physicochemical properties
        volumetricSurfaceArea  % Surface area to volume,       [m2 m^-3]
        rp                     % Particle radius               [m]
        D0                     % Diffusion coefficient         [m]
        EaD                    % 
        
    end

    methods

        function model = SimplifiedSolidDiffusionModel(paramobj)

            model = model@BaseModel();

             % OBS : All the submodels should have same backend (this is not assigned automaticallly for the moment)
            model.AutoDiffBackend = SparseAutoDiffBackend('useBlocks', false);

            fdnames = {'rp'                    , ...
                       'volumetricSurfaceArea' , ...
                       'EaD'                    , ...
                       'D0'};

            model = dispatchParams(model, paramobj, fdnames);

        end
        
        function model = registerVarAndPropfuncNames(model)

            %% Declaration of the Dynamical Variables and Function of the model
            % (setup of varnameList and propertyFunctionList)

            model = registerVarAndPropfuncNames@BaseModel(model);

            varnames = {};
            % concentration
            varnames{end + 1} = 'T';
            % concentration at the surface
            varnames{end + 1} = 'cSurface';
            % concentration (over the whole particle)
            varnames{end + 1} = 'cAverage';
            % Diffusion coefficient
            varnames{end + 1} = 'D';
            % Reaction Rate
            varnames{end + 1} = 'R';
            % Solid diffusion equation
            varnames{end + 1} = 'solidDiffusionEq';
            
            model = model.registerVarNames(varnames);

            fn = @ActiveMaterial.updateDiffusionCoefficient;
            inputnames = {'T'};
            model = model.registerPropFunction({'D', fn, inputnames});

            fn = @ActiveMaterial.assembleSolidDiffusionEquation;
            inputnames = {'cSurface', 'cAverage', 'R', 'D'};
            model = model.registerPropFunction({'solidDiffusionEq', fn, inputnames});
            
        end

        function state = updateDiffusionCoefficient(model, state)

            Tref = 298.15;  % [K]

            T = state.T;

            R   = model.constants.R;
            D0  = model.D0;
            EaD = model.EaD;

            % Calculate solid diffusion coefficient, [m^2 s^-1]
            D = D0.*exp(-EaD./R*(1./T - 1/Tref));

            state.D = D;
            
        end
        
        function state = assembleSolidDiffusionEquation(model, state)
        % We update the surface concentration of the charge carrier in the active material.
        % The surface concentration value is computed following polynomial method, as described in ref1 (see below)

            csurf = state.cSurface;
            caver = state.cAverage;
            D = state.D;
            R = state.R;

            rp = model.rp;
            a = model.volumetricSurfaceArea;
            % We divide with volumetricSurfaceArea because it was added in the definition of R 
            state.solidDiffusionEq = csurf - caver + (rp.*R)./(5*a*D);
            
        end
    
    end
    
end


%{
Copyright 2009-2021 SINTEF Industry, Sustainable Energy Technology
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
    

