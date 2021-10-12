classdef ThermalComponentInputParams < ComponentInputParams

    properties
        
        EffectiveThermalConductivity
        EffectiveHeatCapacity
        couplingTerm
        externalHeatTransferCoefficient % scalar value
        externalTemperature
        
    end
    
    methods

        function paramobj = ThermalComponentInputParams(jsonstruct)
            paramobj = paramobj@ComponentInputParams(jsonstruct);
        end
        
    end
    
    
end
