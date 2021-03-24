classdef GraphiteElectrode_ < CompositeModel

    methods

        function model = GraphiteElectrode_(name)

            model = model@CompositeModel(name);

            submodels = {};
            submodels{end + 1} = Graphite_('am');
            model.SubModels = submodels;
        
            model = model.setAlias({'cLi', VarName({'am'}, 'cLi')});

        end
        
        
    end
    
end

       