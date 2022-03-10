function cons = assembleConservationEquation(model, flux, bcsource, source, accum)
    
    if nargin < 5
        accum = 0;
    end
        
    op = model.operators;
    
    % cons = accum + (op.Div(flux) - bcsource) - source;
    accum = accum - bcsource - source; 
    cons = op.AccDiv(accum, flux);
    %cons = cons - bcsource - source;
    
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
