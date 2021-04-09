classdef CurrentCollectorInputParams < ElectronicComponentInputParams

    properties
        couplingTerm;
    end
    
    methods
        
        function paramobj = CurrentCollectorInputParams();
            paramobj = paramobj@ElectronicComponentInputParams();
            paramobj.couplingTerm = struct();
            
            % we set 100 here directly just for simplicity for the moment (hacky...)
            paramobj.EffectiveElectronicConductivity = 100;
        end
        
    end

end