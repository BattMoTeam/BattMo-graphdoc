function [jExternal, jFaceExternal] = setupExternalCoupling(model, phi, phiExternal, conductivity)

    coupterm = model.externalCouplingTerm;

    jExternal = phi*0.0; %NB hack to initialize zero ad

    faces = coupterm.couplingfaces;
    bcval = phiExternal;
    [t, cells, sgn] = model.G.getBcHarmFace(conductivity, faces);
    current = t.*(bcval - phi(cells));
    jExternal = subsetPlus(jExternal, current, cells);
    G = model.G;
    nf = G.topology.faces.num;
    zeroFaceAD = model.AutoDiffBackend.convertToAD(zeros(nf, 1), phi);
    jFaceExternal = zeroFaceAD;
    jFaceExternal = subsasgnAD(jFaceExternal, faces, -sgn.*current);

    %assert(~any(isnan(sgn(faces))));

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
