% model = ConcentrationReactionModel();
% model = ReactionThermalModel();
model = ConcentrationReactionThermalModel();
cgp = model.cgp;
cgt = model.cgt;
cgp.plot();
