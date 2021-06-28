classdef ElectronicComponent_ < CompositeModel

    methods

        function model = ElectronicComponent_(name)

            model = model@CompositeModel(name);
            names = {'T'        , ...
                     'phi'      , ...
                     'jBcSource', ...
                     'eSource'  , ...
                     'j'        , ...
                     'chargeCons'};
            model.names = names;
            
            fn = @ElectronicComponent.updateCurrent;
            inputnames = {'phi'};
            fnmodel = {'.'};
            model = model.addPropFunction('j', fn, inputnames, fnmodel);
            
            fn = @ElectronicComponent.updateChargeConservation;
            inputnames = {'j', 'jBcSource', 'eSource'};
            fnmodel = {'.'};
            model = model.addPropFunction('chargeCons', fn, inputnames, fnmodel);
            
        end
        
    end
    
end

       