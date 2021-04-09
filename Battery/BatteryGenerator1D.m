classdef BatteryGenerator1D < BatteryGenerator
% setup 1D grid 
    properties
        sepnx  = 30;
        nenx   = 30;
        penx   = 30;
        ccnenx = 20;
        ccpenx = 20;
        
        J = 1;
    end
    
    methods
        
        function gen = BatteryGenerator1D()
          gen = gen@BatteryGenerator();  
        end
            
        function paramobj = updateBatteryInputParams(gen, paramobj)
            paramobj = gen.setupBatteryInputParams(paramobj, []);
            paramobj.J = gen.J; 
        end
        
        function [paramobj, gen] = setupGrid(gen, paramobj, ~)
        % paramobj is instance of BatteryInputParams
        % setup paramobj.G
            sepnx  = gen.sepnx;
            nenx   = gen.nenx;
            penx   = gen.penx;
            ccnenx = gen.ccnenx;
            ccpenx = gen.ccpenx;

            nxs = [ccnenx; nenx; sepnx; penx; ccpenx];

            xlength = 1e-6*[10; 100; 50; 80; 10];
            ylength = 1e-2;

            x = xlength./nxs;
            x = rldecode(x, nxs);
            x = [0; cumsum(x)];

            G = tensorGrid(x);
            G = computeGeometry(G); 

            paramobj.G = G;
            gen.G = G;
            
        end

        function paramobj = setupElectrolyte(gen, paramobj, params)
            
            params.cellind = gen.ccnenx + (1 : (gen.nenx + gen.sepnx + gen.penx))';
            params.sep.cellind = gen.ccnenx + gen.nenx + (1 : gen.sepnx)';
            
            paramobj = setupElectrolyte@BatteryGenerator(gen, paramobj, params);
        end
        
        function paramobj = setupElectrodes(gen, paramobj, params)
            
            sepnx = gen.sepnx; 
            nenx = gen.nenx; 
            penx = gen.penx; 
            ccnenx = gen.ccnenx; 
            ccpenx = gen.ccpenx;     
            
            %% parameters for negative electrode

            params.ne.cellind = (1 : ccnenx + nenx)';
            params.ne.eac.cellind = ccnenx + (1 : nenx)';
            params.ne.cc.cellind = (1 : ccnenx)';
            
            % boundary setup for negative current collector
            params.ne.cc.bcfaces = 1;
            params.ne.cc.bccells = 1;
            
            %% parameters for positive electrode
            
            pe_indstart = ccnenx + nenx + sepnx;
            params.pe.cellind =  pe_indstart + (1 : ccpenx + penx)';
            params.pe.eac.cellind = pe_indstart + (1 : penx)';
            params.pe.cc.cellind = pe_indstart + penx + (1 : ccpenx)';
            
            % boundary setup for positive current collector
            params.pe.cc.bcfaces = ccpenx + 1;
            params.pe.cc.bccells = ccpenx;
            
            paramobj = setupElectrodes@BatteryGenerator(gen, paramobj, params);

        end            I
        
    end
    
end

