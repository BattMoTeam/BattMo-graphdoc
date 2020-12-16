% 2D test case

clear all
close all

%% Add MRST module
mrstModule add ad-core

% Setup object and run simulation
% delete('temp2.txt');
obj = lithiumIonModel();
obj.J = 0.1;

%% run simulation

[t, y] = obj.p2d();

%% plotting

mrstModule add mrst-gui

fv = obj.fv;


%%  plot of potential

for iy = 1 : size(y, 1)
    yy = y(iy, :)';
    varname = 'E';
    E(iy) = yy(fv.getSlot(varname));
end

figure
plot(t/hour, E)
title('Potential (E)')
xlabel('time (hours)')

return

%% plot of each component

compnames = obj.componentnames;

allstates = {};
Gs = {};

for icn = 1 : numel(compnames)
    
    compname = compnames{icn};
    comp = obj.(compname);

    Gs{icn} = comp.Grid;
    
    allstates{icn}= {};
    
    for iy = 1 : size(y, 1)
        yy = y(iy, :)';
        varname = 'phi';
        fullvarname = sprintf('%s_%s', compname, varname);
        state.(varname) = yy(fv.getSlot(fullvarname));
        if ismember(compname, {'ne', 'pe', 'elyte'})
            varname = 'Li';
            fullvarname = sprintf('%s_%s', compname, varname);
            state.(varname) = yy(fv.getSlot(fullvarname));
            if strcmp(compname, 'elyte')
               state.(varname) = state.(varname)./obj.elyte.eps;
            end
        end
        allstates{icn}{iy} = state;
    end
    
    figure(icn)
    plotToolbar(Gs{icn}, allstates{icn});
    title(compname);
    
end

%% Combined plot for the positive electrod and current collector

% compnames = {'ne', 'ccne', 'pe', 'ccpe'};
% compnames = {'ne', 'ccne'};
compnames = {'pe', 'ccpe'};

states = {};
G = obj.G;
nc = G.cells.num;

for iy = 1 : size(y, 1)

    phi = nan(nc, 1);
    yy = y(iy, :)';
    
    for icn = 1 : numel(compnames)
    
        compname = compnames{icn};
        comp = obj.(compname);
        varname = 'phi';
        fullvarname = sprintf('%s_%s', compname, varname);
        philoc = yy(fv.getSlot(fullvarname));
        
        cellmap = comp.Grid.mappings.cellmap;
        
        phi(cellmap) = philoc;
        
    end

    states{iy}.phi = phi;
    
end

%%

figure
plotToolbar(G, states);
title(join(compnames, ' and '));

