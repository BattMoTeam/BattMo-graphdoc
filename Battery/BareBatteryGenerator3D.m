classdef BareBatteryGenerator3D < BareBatteryGenerator
% setup 1D grid 
    properties
        
        sepnx  = 10;
        nenx   = 10;
        penx   = 10;
        fac = 1;
        
    end
    
    methods
        
        function gen = BareBatteryGenerator3D()
          gen = gen@BareBatteryGenerator();  
        end
            
        function paramobj = updateBatteryInputParams(gen, paramobj)
            paramobj = gen.setupBatteryInputParams(paramobj, []);
        end
        
        function [paramobj, gen] = setupGrid(gen, paramobj, ~)
        % paramobj is instance of BatteryInputParams
        % setup paramobj.G
            sepnx = gen.sepnx;
            nenx  = gen.nenx;
            penx  = gen.penx;

            nxs = [nenx; sepnx; penx];

            % following dimension are those from Chen's paper
            xlength = 1e-5*[8.52; 1.2; 7.56];
            ylength = 1.58;
            zlength = 0.065;

            x = xlength./nxs;
            x = rldecode(x, nxs);
            x = [0; cumsum(x)];

            G = tensorGrid(x, [0; ylength], [0; zlength]);
            G = computeGeometry(G); 

            paramobj.G = G;
            gen.G = G;
            
        end

        function gen = applyResolutionFactors(gen)
            
            fac = gen.fac;
            
            gen.sepnx  = gen.sepnx*fac;
            gen.nenx   = gen.nenx*fac;
            gen.penx   = gen.penx*fac;
            
        end
            
        function paramobj = setupElectrolyte(gen, paramobj, params)
            
            params.cellind =  (1 : (gen.nenx + gen.sepnx + gen.penx))';
            params.Separator.cellind = gen.nenx + (1 : gen.sepnx)';
            
            paramobj = setupElectrolyte@BareBatteryGenerator(gen, paramobj, params);
        end
        
        function paramobj = setupElectrodes(gen, paramobj, params)

            ne  = 'NegativeElectrode';
            pe  = 'PositiveElectrode';
            
            sepnx = gen.sepnx; 
            nenx = gen.nenx; 
            penx = gen.penx; 
            
            %% parameters for negative electrode

            params.(ne).cellind = (1 : nenx)';
            
            % boundary setup for negative electrode
            params.(ne).bcfaces = 1;
            params.(ne).bccells = 1;
            
            %% parameters for positive electrode
            
            pe_indstart = nenx + sepnx;
            params.(pe).cellind =  pe_indstart + (1 :  penx)';
            
            % boundary setup for positive electode
            params.(pe).bcfaces = penx + 1;
            params.(pe).bccells = penx;
            
            paramobj = setupElectrodes@BareBatteryGenerator(gen, paramobj, params);

        end            I
                
    end
    
end


