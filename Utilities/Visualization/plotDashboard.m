function [fig] = plotDashboard(model, states, varargin)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

%
close all

%% Parse inputs            
defaultStep         = length(states);
defaultTheme        = 'light';
expectedTheme       = {'dark', 'light', 'blue', 'offwhite'};
defaultSize         = 'wide';
expectedSize        = {'A4', 'square', 'wide'};
defaultOrientation  = 'landscape';
expectedOrientation = {'landscape', 'portrait'};

p = inputParser;
validStep = @(x) isnumeric(x) && isinteger(int8(x)) && (x >= 0) && (x <= length(states));
addOptional(p, 'step', defaultStep, validStep);
addOptional(p, 'theme', defaultTheme, ...
    @(x) any(validatestring(x,expectedTheme)));
addOptional(p, 'size', defaultSize, ...
    @(x) any(validatestring(x,expectedSize)));
addOptional(p, 'orientation', defaultOrientation, ...
    @(x) any(validatestring(x,expectedOrientation)));
parse(p, varargin{:});

ne      = 'NegativeElectrode';
pe      = 'PositiveElectrode';
eac     = 'ElectrodeActiveComponent';
cc      = 'CurrentCollector';
elyte   = 'Electrolyte';
thermal = 'ThermalModel';

step = p.Results.step;

fig = figure;

time = zeros(1, length(states));
for i = 1:length(states)
    time(i) = states{i}.time;
end

Enew = cellfun(@(x) x.(pe).(cc).E, states); 
Inew = cellfun(@(x) x.(pe).(cc).I, states);



if step ~= 0
    
    timeBar = [  time(step)/hour, 0; ...
                time(step)/hour, 1000];
    
    if model.G.griddim == 1
        setFigureStyle('theme', p.Results.theme, 'size', p.Results.size, 'orientation', p.Results.orientation, 'quantity', 'single');
        subplot(2,4,1), plotCellData(model.NegativeElectrode.ElectrodeActiveComponent.G, states{step}.NegativeElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000, 'linewidth', 3);
        xlabel(gca, 'Position  /  m')
        title(gca, 'Negative Electrode Concentration  /  mol \cdot L^{-1}')
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)
        
        subplot(2,4,2), plotCellData(model.Electrolyte.G, states{step}.Electrolyte.c ./ 1000, 'linewidth', 3);
        xlabel(gca, 'Position  /  m')
        title(gca, 'Electrolyte Concentration  /  mol \cdot L^{-1}')
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)
        
        subplot(2,4,3), plotCellData(model.PositiveElectrode.ElectrodeActiveComponent.G, states{step}.PositiveElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000, 'linewidth', 3);
        xlabel(gca, 'Position  /  m')
        title(gca, 'Positive Electrode Concentration  /  mol \cdot L^{-1}')
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)
        
        subplot(2,4,4), plot((time/hour), Inew, '-', 'linewidth', 3)
        hold on
        plot(timeBar(:,1), timeBar(:,2), 'k--', 'linewidth', 1);
        hold off
        title('Cell Current  /  A')
        xlabel('Time  /  h')
        xlim([min(time/hour), max(time/hour)]);
        ylim([min(Inew), max(Inew)]);
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)
        
        subplot(2,4,5), plotCellData(model.NegativeElectrode.ElectrodeActiveComponent.G, states{step}.NegativeElectrode.ElectrodeActiveComponent.phi, 'linewidth', 3);
        xlabel(gca, 'Position  /  m')
        title(gca, 'Negative Electrode Potential  /  V')
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)
        
        subplot(2,4,6), plotCellData(model.Electrolyte.G, states{step}.Electrolyte.phi, 'linewidth', 3);
        xlabel(gca, 'Position  /  m')
        title(gca, 'Electrolyte Potential  /  V')
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)
        
        subplot(2,4,7), plotCellData(model.PositiveElectrode.ElectrodeActiveComponent.G, states{step}.PositiveElectrode.ElectrodeActiveComponent.phi, 'linewidth', 3);
        xlabel(gca, 'Position  /  m')
        title(gca, 'Positive Electrode Potential  /  V')
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)
        
        subplot(2,4,8), plot((time/hour), Enew, '-', 'linewidth', 3)
        hold on
        plot(timeBar(:,1), timeBar(:,2), 'k--', 'linewidth', 1);
        hold off
        title('Cell Voltage  /  V')
        xlabel('Time  /  h')
        xlim([min(time/hour), max(time/hour)]);
        ylim([min(Enew), max(Enew)]);
        set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

    elseif model.G.griddim == 2
        plotCellData(model.Electrolyte.G, states{step}.Electrolyte.c ./ 1000, 'edgealpha', 0.1);
        colormap(cmocean('curl'));
        xlabel(gca, 'Position  /  m')
        ylabel(gca, 'Position  /  m')
        title('Concentration  /  mol \cdot L^{-1}')
        cmin = min(states{step}.Electrolyte.c ./ 1000);
        cmax = max(states{step}.Electrolyte.c ./ 1000);
        cnom = mean(states{1}.Electrolyte.c ./ 1000);
        deltac = max(abs(cmin-cnom), abs(cmax-cnom));
        cmin = cnom-deltac;
        cmax = cnom+deltac;
        caxis([cmin, cmax]);
        colorbar;

    elseif model.G.griddim == 3
        plotCellData(model.Electrolyte.G, states{step}.Electrolyte.c ./ 1000, 'edgealpha', 0.1);
        colormap(cmocean('curl'));
        xlabel(gca, 'Position  /  m')
        ylabel(gca, 'Position  /  m')
        zlabel(gca, 'Position  /  m')
        title('Concentration  /  mol \cdot L^{-1}')
        cmin = min(states{step}.Electrolyte.c ./ 1000);
        cmax = max(states{step}.Electrolyte.c ./ 1000);
        cnom = mean(states{1}.Electrolyte.c ./ 1000);
        deltac = max(abs(cmin-cnom), abs(cmax-cnom));
        cmin = cnom-deltac;
        cmax = cnom+deltac;
        caxis([cmin, cmax]);
        colorbar;
        view(45,45)
    end
%     setFigureStyle('theme', p.Results.theme, 'size', p.Results.size, 'orientation', p.Results.orientation, 'quantity', 'single');
else
    for i = 1:length(states)
                
        if i == 1
            cmax_elyte = max(max(states{i}.Electrolyte.c ./ 1000));
            cmin_elyte = min(min(states{i}.Electrolyte.c ./ 1000));
            
            cmax_ne = max(max(states{i}.NegativeElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000));
            cmin_ne = min(min(states{i}.NegativeElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000));
            
            cmax_pe = max(max(states{i}.PositiveElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000));
            cmin_pe = min(min(states{i}.PositiveElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000));
            
            phimax_elyte = max(max(states{i}.Electrolyte.phi));
            phimin_elyte = min(min(states{i}.Electrolyte.phi));
            
            phimax_ne = max(max(states{i}.NegativeElectrode.ElectrodeActiveComponent.phi));
            phimin_ne = min(min(states{i}.NegativeElectrode.ElectrodeActiveComponent.phi));
            
            phimax_pe = max(max(states{i}.PositiveElectrode.ElectrodeActiveComponent.phi));
            phimin_pe = min(min(states{i}.PositiveElectrode.ElectrodeActiveComponent.phi));
            
            xmin = min(model.Electrolyte.G.nodes.coords(:,1));
            xmax = max(model.Electrolyte.G.nodes.coords(:,1));
            if model.G.griddim == 2
                ymin = min(model.Electrolyte.G.nodes.coords(:,2));
                ymax = max(model.Electrolyte.G.nodes.coords(:,2));
            elseif model.G.griddim == 3
                ymin = min(model.Electrolyte.G.nodes.coords(:,2));
                ymax = max(model.Electrolyte.G.nodes.coords(:,2));
                zmin = min(model.Electrolyte.G.nodes.coords(:,3));
                zmax = max(model.Electrolyte.G.nodes.coords(:,3));
            end
        else
            cmax_elyte = max(cmax_elyte, max(max(states{i}.Electrolyte.c ./ 1000)));
            cmin_elyte = min(cmin_elyte, min(min(states{i}.Electrolyte.c ./ 1000)));
            
            cmax_ne = max(cmax_ne, max(max(states{i}.NegativeElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000)));
            cmin_ne = min(cmin_ne, min(min(states{i}.NegativeElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000)));
            
            cmax_pe = max(cmax_pe, max(max(states{i}.PositiveElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000)));
            cmin_pe = min(cmin_pe, min(min(states{i}.PositiveElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000)));
            
            phimax_elyte = max(phimax_elyte, max(max(states{i}.Electrolyte.phi)));
            phimin_elyte = min(phimin_elyte, min(min(states{i}.Electrolyte.phi)));
            
            phimax_ne = max(phimax_ne, max(max(states{i}.NegativeElectrode.ElectrodeActiveComponent.phi)));
            phimin_ne = min(phimin_ne, min(min(states{i}.NegativeElectrode.ElectrodeActiveComponent.phi)));
            
            phimax_pe = max(phimax_pe, max(max(states{i}.PositiveElectrode.ElectrodeActiveComponent.phi)));
            phimin_pe = min(phimin_pe, min(min(states{i}.PositiveElectrode.ElectrodeActiveComponent.phi)));
        end
    end
    
    for i = 1:length(states)
        
        timeBar = [  time(i)/hour, 0; ...
                time(i)/hour, 1000];
        
        if i == 1
            style = setFigureStyle('theme', p.Results.theme, 'size', p.Results.size, 'orientation', p.Results.orientation, 'quantity', 'single'); 
            style.fontSize = 10;
        end
        if model.G.griddim == 1
            subplot(2,4,1), plotCellData(model.NegativeElectrode.ElectrodeActiveComponent.G, states{i}.NegativeElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000, 'linewidth', 3);
            xlabel(gca, 'Position  /  m')
            title(gca, 'Negative Electrode Concentration  /  mol \cdot L^{-1}', 'color', style.fontColor)
            xlim([xmin, xmax])
            ylim([cmin_ne, cmax_ne])
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

            subplot(2,4,2), plotCellData(model.Electrolyte.G, states{i}.Electrolyte.c ./ 1000, 'linewidth', 3);
            xlabel(gca, 'Position  /  m')
            title(gca, 'Electrolyte Concentration  /  mol \cdot L^{-1}', 'color', style.fontColor)
            xlim([xmin, xmax])
            ylim([cmin_elyte, cmax_elyte])
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

            subplot(2,4,3), plotCellData(model.PositiveElectrode.ElectrodeActiveComponent.G, states{i}.PositiveElectrode.ElectrodeActiveComponent.ActiveMaterial.cElectrode ./ 1000, 'linewidth', 3);
            xlabel(gca, 'Position  /  m')
            title(gca, 'Positive Electrode Concentration  /  mol \cdot L^{-1}', 'color', style.fontColor)
            xlim([xmin, xmax])
            ylim([cmin_pe, cmax_pe])
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

            subplot(2,4,4), plot((time/hour), Inew, '-', 'linewidth', 3)
            hold on
            plot(timeBar(:,1), timeBar(:,2),  '--', 'linewidth', 1, 'color', style.fontColor);
            hold off
            title('Cell Current  /  A', 'color', style.fontColor)
            xlabel('Time  /  h')
            xlim([min(time/hour), max(time/hour)]);
            ylim([min(Inew), max(Inew)]);
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

            subplot(2,4,5), plotCellData(model.NegativeElectrode.ElectrodeActiveComponent.G, states{i}.NegativeElectrode.ElectrodeActiveComponent.phi, 'linewidth', 3);
            xlabel(gca, 'Position  /  m')
            title(gca, 'Negative Electrode Potential  /  V', 'color', style.fontColor)
            xlim([xmin, xmax])
            ylim([phimin_ne, phimax_ne])
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

            subplot(2,4,6), plotCellData(model.Electrolyte.G, states{i}.Electrolyte.phi, 'linewidth', 3);
            xlabel(gca, 'Position  /  m')
            title(gca, 'Electrolyte Potential  /  V', 'color', style.fontColor)
            xlim([xmin, xmax])
            ylim([phimin_elyte, phimax_elyte])
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

            subplot(2,4,7), plotCellData(model.PositiveElectrode.ElectrodeActiveComponent.G, states{i}.PositiveElectrode.ElectrodeActiveComponent.phi, 'linewidth', 3);
            xlabel(gca, 'Position  /  m')
            title(gca, 'Positive Electrode Potential  /  V', 'color', style.fontColor)
            xlim([xmin, xmax])
            ylim([phimin_pe, phimax_pe])
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

            subplot(2,4,8), plot((time/hour), Enew, '-', 'linewidth', 3)
            hold on
            plot(timeBar(:,1), timeBar(:,2), '--', 'linewidth', 1, 'color', style.fontColor);
            hold off
            title('Cell Voltage  /  V', 'color', style.fontColor)
            xlabel('Time  /  h')
            xlim([min(time/hour), max(time/hour)]);
            ylim([min(Enew), max(Enew)]);
            set(gca, ...
                'FontSize', style.fontSize, ...
                'FontName', style.fontName, ...
                'color', style.backgroundColor, ...
                'XColor', style.fontColor, ...
                'YColor', style.fontColor, ...
                'GridColor', style.fontColor)

        elseif model.G.griddim == 2
            plotCellData(model.Electrolyte.G, states{i}.Electrolyte.c ./ 1000, 'edgealpha', 0.1);
            colormap(cmocean('curl'));
            xlabel(gca, 'Position  /  m')
            ylabel(gca, 'Position  /  m')
            title('Concentration  /  mol \cdot L^{-1}')
            
            xlim([xmin, xmax]);
            ylim([ymin, ymax]);
            cnom = mean(states{1}.Electrolyte.c ./ 1000);
            deltac = max(abs(cmin-cnom), abs(cmax-cnom));
            cmin = cnom-deltac;
            cmax = cnom+deltac;
            caxis([cmin, cmax]);
            c = colorbar;
            c.Color = style.fontColor;

        elseif model.G.griddim == 3
            plotCellData(model.Electrolyte.G, states{i}.Electrolyte.c ./ 1000, 'edgealpha', 0.1);
            colormap(cmocean('curl'));
            xlabel(gca, 'Position  /  m')
            ylabel(gca, 'Position  /  m')
            zlabel(gca, 'Position  /  m')
            title('Concentration  /  mol \cdot L^{-1}')
            xlim([xmin, xmax]);
            ylim([ymin, ymax]);
            zlim([zmin, zmax]);
            cnom = mean(states{1}.Electrolyte.c ./ 1000);
            deltac = max(abs(cmin-cnom), abs(cmax-cnom));
            cmin = cnom-deltac;
            cmax = cnom+deltac;
            caxis([cmin, cmax]);
            c = colorbar;
            c.Color = style.fontColor;
            view(45,45)
        end
        
        drawnow
        pause(0.1)
    end
end
  
    
end

%{
Copyright 2009-2021 SINTEF Industry, Sustainable Energy Technology
and SINTEF Digital, Mathematics & Cybernetics.

This file is part of The Battery Modeling Toolbox BatMo

BatMo is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

BatMo is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with BatMo.  If not, see <http://www.gnu.org/licenses/>.
%}