function cons = assembleConservationEquation(model, flux, bcsource, source, accum)
    
    if nargin < 5
        accum = 0;
    end
        
    op = model.operators;
    
    cons = accum + (op.Div(flux) - bcsource) - source;
    
end
