classdef Electrode_ < CompositeModel

    methods

        function model = Electrode_(name)
            
            model = model@CompositeModel(name);
            
            names = {model.names{:}, ...
                     'T' };
            
            model.SubModels{1} = ActiveElectroChemicalComponent_('eac');
            model.SubModels{2} = ElectronicComponent_('cc');

            % Add potential coupling between the two
            
            inputnames = {VarName({'..', 'eac'}, 'phi'), ...
                          VarName({'..', 'cc'}, 'phi')};
            fn = @Electrode.setupCoupling;
            fnmodel = {'..'};
            model = model.addPropFunction({'eac', 'jBcSource'}, fn, inputnames, fnmodel);
            model = model.addPropFunction({'cc', 'jBcSource'}, fn, inputnames, fnmodel);

            inputnames = {VarName({'..'}, 'T')};
            fn = @Electrode.updateT;
            fnmodel = {'..'};
            model = model.addPropFunction({'eac', 'T'}, fn, inputnames, fnmodel);
            model = model.addPropFunction({'cc', 'T'}, fn, inputnames, fnmodel);
            
        end
        
    end
    
end

