function [cap, cap_neg, cap_pos, specificEnergy] = computeCellCapacity(model)

%
%
% SYNOPSIS:
%   function c = computeCellCapacity(model, state)
%
% DESCRIPTION: computes the cell usable capacity in Coulomb
%
% PARAMETERS:
%   model - battery model
%
% RETURNS:
%   c - capacity
%
% EXAMPLE:
%
% SEE ALSO:
%

% We handle the battery and bare battery structure (without current collector)
    
    ne  = 'NegativeElectrode';
    pe  = 'PositiveElectrode';
    eac = 'ElectrodeActiveComponent';
    am  = 'ActiveMaterial';
    
    eldes = {ne, pe};
    
    isBare = false;
    if strcmp(class(model), 'BareBattery')
        isBare = true;
    end
    
    for ind = 1 : numel(eldes)
        
        elde = eldes{ind};
        
        if isBare
            ammodel = model.(elde).(am);
        else
            ammodel = model.(elde).(eac).(am);
        end
        
        n    = ammodel.n;
        F    = ammodel.constants.F;
        G    = ammodel.G;
        cMax = ammodel.Li.cmax;

        switch elde
          case 'NegativeElectrode'
            thetaMax = ammodel.theta100;
            thetaMin = ammodel.theta0;
          case 'PositiveElectrode'
            thetaMax = ammodel.theta0;
            thetaMin = ammodel.theta100;            
          otherwise
            error('Electrode not recognized');
        end
        
        volume_fraction = ammodel.volumeFraction;
        volume_electrode = sum(model.(elde).(eac).G.cells.volumes);
        volume = volume_fraction*volume_electrode;
        
        cap_usable(ind) = (thetaMax - thetaMin)*cMax*volume*n*F;
        
    end
    
    cap_neg = cap_usable(1);
    cap_pos = cap_usable(2);
    
    cap = min(cap_usable); 

    doComputeEnergy = true;
    
    if doComputeEnergy
        
        r = cap_neg/cap_pos;
        
        thetaMinPos = model.(pe).(eac).(am).theta100;
        thetaMaxPos = model.(pe).(eac).(am).theta0;
        thetaMinNeg = model.(ne).(eac).(am).theta0;
        thetaMaxNeg = model.(ne).(eac).(am).theta100;
        
        elde = 'PositiveElectrode';

        ammodel = model.(elde).(eac).(am);
        F = ammodel.constants.F;
        G = ammodel.G;
        n = ammodel.n;
        assert(n == 1, 'not implemented yet');
        cMax = ammodel.Li.cmax;
        
        volume_fraction = ammodel.volumeFraction;
        volume_electrode = sum(model.(elde).(eac).G.cells.volumes);
        volume = volume_fraction*volume_electrode;
        
        func = @(theta) model.(elde).(eac).(am).updateOCPFunc(theta, 298, 1);

        thetaMax = min(thetaMaxPos, thetaMinPos + r*(thetaMaxPos - thetaMinPos));

        theta = linspace(thetaMinPos, thetaMax, 100);
        energy = sum(func(theta(1 : end - 1)).*diff(theta)*volume*F*cMax);
        
        elde = 'NegativeElectrode';        
        
        ammodel = model.(elde).(eac).(am);
        F = ammodel.constants.F;
        G = ammodel.G;
        n = ammodel.n;
        assert(n == 1, 'not implemented yet');
        cMax = ammodel.Li.cmax;
        volume_fraction = ammodel.volumeFraction;
        volume_electrode = sum(model.(elde).(eac).G.cells.volumes);
        volume = volume_fraction*volume_electrode;
        
        func = @(theta) model.(elde).(eac).(am).updateOCPFunc(theta, 298, 1);

        thetaMin = max(thetaMinNeg, thetaMaxNeg - 1/r*(thetaMaxNeg - thetaMinNeg));

        theta = linspace(thetaMin, thetaMaxNeg, 100);
        energy = energy - sum(func(theta(1 : end - 1)).*diff(theta)*volume*F*cMax);
        
        mass = computeCellMass(model);
        
        warning('Adding packing mass in computation of optimal energy');
        specificEnergy = energy/(mass + 10e-3);
        
    else
        
        specificEnergy = [];
        
    end
    
end



%{
Copyright 2009-2021 SINTEF Industry, Sustainable Energy Technology
and SINTEF Digital, Mathematics & Cybernetics.

This file is part of The Battery Modeling Toolbox BatMo

BatMo is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

BatMo is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with BatMo.  If not, see <http://www.gnu.org/licenses/>.
%}