classdef ConcentrationReactionThermalModel < BaseModel

    properties

        ConcReac
        Thermal
        
    end
    
    methods

        function model = ConcentrationReactionThermalModel()

            model.ConcReac = ConcentrationReactionModel();
            model.Thermal  = ThermalModel();
            
        end

        function model = registerVarAndPropfuncNames(model)
            
            %% Declaration of the Dynamical Variables and Function of the model

            model = registerVarAndPropfuncNames@BaseModel(model);

            fn = @ConcentrationReactionThermalModel.updateOCP;
            inputnames = {{'ConcReac', 'Reaction', 'c_s'}, {'Thermal', 'T'}};
            model = model.registerPropFunction({{'ConcReac', 'Reaction', 'OCP'}, fn, inputnames});

            fn = @ConcentrationReactionThermalModel.updateThermalSource;
            inputnames = {{'ConcReac', 'Reaction', 'R'}};
            model = model.registerPropFunction({{'Thermal', 'source'}, fn, inputnames});
            
        end

    end
    
end
