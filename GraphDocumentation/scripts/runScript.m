set(0, 'defaultlinelinewidth', 3);
set(0, 'defaultaxesfontsize', 15);

model = ReactionModel();
% model = ReactionThermalModel();
% model = ConcentrationReactionModel();
% model = ConcentrationReactionThermalModel();
cgp = model.cgp;
cgt = model.cgt;
h = cgp.plot();
set(h, 'nodefontsize', 14);
set(h, 'linewidth', 3);
set(h, 'arrowsize', 20);

dosave = true;
savedir = '../img';

if dosave
    filename = 'reacmodelgraph.png';
    filename = fullfile(savedir, filename);
    saveas(gcf, filename)
end
    
