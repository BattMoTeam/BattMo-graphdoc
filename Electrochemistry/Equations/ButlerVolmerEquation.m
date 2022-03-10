function res = ButlerVolmerEquation(j0, alpha, n, eta, T)
%BUTLERVOLMER Implements the standard form of the Butler-Volmer equation
%for electrochemical charge-transfer reaction kinetics.
%   Detailed explanation goes here
constants = PhysicalConstants();

res = j0 .* (   exp(  alpha .* n .* constants.F .* eta ./ ( constants.R .* T ) ) - ...
                exp( -(1-alpha) .* n .* constants.F .* eta ./ ( constants.R .* T ) ) );

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
