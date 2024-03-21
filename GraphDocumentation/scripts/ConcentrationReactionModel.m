classdef ConcentrationReactionModel < BaseModel

    properties

        Reaction
        ConcS
        ConcE
        
    end
    
    methods

        function model = ConcentrationReactionModel()

            model.Reaction = ReactionModel();
            model.ConcS    = ConcentrationModel();
            model.ConcE    = ConcentrationModel();
            
        end
        
        function model = registerVarAndPropfuncNames(model)
            
            %% Declaration of the Dynamical Variables and Function of the model

            model = registerVarAndPropfuncNames@BaseModel(model);

            fn = @ConcentrationReactionModel.updateConcentrationSource;
            inputnames = {{'Reaction', 'R'}};
            model = model.registerPropFunction({{'ConcS', 'source'}, fn, inputnames});
            model = model.registerPropFunction({{'ConcE', 'source'}, fn, inputnames});
            
            fn = @ConcentrationReactionModel.updateReactionConcentrationE;
            inputnames = {{'ConcE', 'c'}};
            model = model.registerPropFunction({{'Reaction', 'c_e'}, fn, inputnames});

            fn = @ConcentrationReactionModel.updateReactionConcentrationS;
            inputnames = {{'ConcS', 'c'}};
            model = model.registerPropFunction({{'Reaction', 'c_s'}, fn, inputnames});

        end

    end
    
end
