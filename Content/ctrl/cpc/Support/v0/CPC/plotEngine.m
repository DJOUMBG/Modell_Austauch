function [engine] = plotEngine(engine, hAxes, bHyp, bAbsFuel, bBemin, bemin_range)
% PLOTENGINE plot engine data
%
% Syntax:  [engine] = plotEngine(engine, hAxes, bHyp, bAbsFuel)
%
% Inputs:
%    engine - [.] Datastructure of diesel engine
%                 engine.kgh_map  - [kg/h] fuel map (m x n)
%                 engine.rpm_map  - [rpm] data points for fuel map (m x n) oder (1 x n)
%                 engine.Nm_map   - [Nm] data points for fuel map (m x n) oder (m x 1)
%                 engine.rpm_fuel - [rpm] measured data points of fuel map (o x 1)
%                 engine.Nm_fuel  - [Nm] measured data points of fuel map (o x 1)
%                 engine.rpm_full - [rpm] full load curve (1 x u) or (2 x u) for TopTorque
%                 engine.Nm_full  - [Nm] full load curve (1 x u)  or (2 x u) for TopTorque
%                 engine.rpm_fric - [rpm] drag / friction curve (1 x v1)
%                 engine.Nm_fric  - [Nm] drag / friction curve (negative values) (1 x v1)
%                 engine.rpm_exh  - [rpm] engine / exhaust brake (1 x v2)
%                 engine.Nm_exh   - [Nm] engine / exhaust brake (negative values) (1 x v2)
%                 engine.rpm_aux  - [rpm] auxiliary curve (1 x w)
%                 engine.Nm_aux   - [Nm] auxiliary curve (1 x w)
%                 engine.rpm_trans_step         - [rpm] Uncharged full load curve (1 x t1)
%                 engine.Nm_trans_step          - [Nm] Uncharged full load curve (1 x t1)
%                 engine.rpm_trans_gradient     - [rpm] torque gradient in transient mode (1 x t2)
%                 engine.Nmps_trans_gradient    - [Nm/s] torque gradient in transient mode (1 x t2)
%     hAxes - [*] Handle of axes (optional)
%      bHyp - [0,1] boolean condition to plot or not to plot power hyperbel (optional, default: 1)
%  bAbsFuel - [0,1] boolean condition to plot or not to plot kgh-fuelmap (optional, default: 0)
%   bBemin  - [0,1] boolean condition to plot or not to plot be_min curve optional, default: 0)
% bemin_range - [%] percentage (double) value to set the additional bemin curves that have higher fc (optional, default: 3)
%
% Outputs:
%    engine - [.] Datastructure of diesel engine
%                (added data description or adjusted fuel map, if possible)
%
% Example:
%    [engine] = plotEngine(engine,hAxes);
%    [engine] = plotEngine(engine,hAxes,bHyp);
%    [engine] = plotEngine(engine,hAxes,bHyp,bAbsFuel);
%    [engine] = plotEngine(engine,[],[],1);
%
% Subfunctions: defLim, plotLine, plotPowerHyp
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also:
%
% Author: ploch37
% Date:   11-Aug-2011
%
% SVN: (wird automatisch gesetzt, wenn Keywords - Eigenschaft gewählt ist)
%   $Rev:: 1091                                                 $
%   $Author: ploch37 $
%   $Date: 2018-09-24 10:27:53 +0200 (Mo, 24. Sep 2018) $
%   $URL: file://emea.corpdir.net/E019/PRJ/TG/LDYNtools/200_svn/analysis/tools/plotEngine.m $

%% ------------- BEGIN CODE --------------
sXLabel = 'speed [rpm]';
sYLabel = 'torque [Nm]';

if ~exist('hAxes', 'var') || isempty(hAxes)
    figure;
    hAxes = axes;
end
if ~exist('bHyp', 'var') || isempty(bHyp)
    bHyp = true;
else
    switch bHyp
        case 'true'
            bHyp = true;
        case 'false'
            bHyp = false;
    end
end
if ~exist('bAbsFuel', 'var') || isempty(bAbsFuel)
    bAbsFuel = false;
else
    switch bAbsFuel
        case 'true'
            bAbsFuel = true;
        case 'false'
            bAbsFuel = false;
    end
end
if ~exist('bBemin', 'var') || isempty(bBemin)
    bBemin = false;
else
    switch bBemin
        case 'true'
            bBemin = true;
        case 'false'
            bBemin = false;
    end
end
if ~exist('bemin_range', 'var') || isempty(bemin_range)
    bemin_range = 3;
end
axes(hAxes); % Achse zur aktuellen Achse machen

hold on


%% fuel map
if isfield(engine, 'rpm_map')

    % g/kWh Lininen
    LineDefinition = [170:200 205:5:220 230:40:390 450:100:550]; % [g/kWh]
%     LineDefinition = unique([170:1:200 200:5:230 230:50:250 250:100:600]); % [g/kWh]
%     LineDefinition = unique([170:5:200 200:15:230 300:200:600]); % [g/kWh]  % om470/471

    % define thickness of line
    LineThickness = 1;
    % define color line of grid (and font)
%     sColorLine = [0.5 0.5 0.5]; % standard ldyn grey
    sColorLine = [0.7 0.7 0.7]; % light grey

    % Bezeichnung
    if ~isfield(engine, 'sMap')
        engine.sMap = 'fuel map';
    end

    % change 1D map to 2D map
    if isvector(engine.rpm_map)
        [engine.rpm_map, engine.Nm_map]  = meshgrid(engine.rpm_map, engine.Nm_map);
    end

    % g/kWh erstellen
    if ~isfield(engine, 'gkWh_map')
        gkWh = engine.kgh_map * 1000 ./ (engine.Nm_map .* engine.rpm_map * pi/30/1000);
        gkWh(isinf(gkWh) | gkWh<=0 ) = nan;
        engine.gkWh_map = gkWh;
    end

    % Muschelkennfeld
    hPlot = findobj(hAxes, 'Tag', 'plotMap');
    if isempty(hPlot)
        % make contour plot for fuelmap
        [C, hPlot] = contour(engine.rpm_map, engine.Nm_map, engine.gkWh_map, LineDefinition);
		% set color of line grid and width of line grid
        set(hPlot,'LineColor',sColorLine,'LineWidth',LineThickness)
        % set fontsize and color of font
        clabel(C,hPlot,'FontName','corpos','FontSize',12,'Color',sColorLine);
        set(hPlot, 'Tag', 'plotMap')
    else
        set(hPlot, 'XData', engine.rpm_map, 'YData', engine.Nm_map, 'ZData', engine.gkWh_map);
    end
    set(hPlot, 'DisplayName', engine.sMap)

    % Messpunkte Kennfeld
    if isfield(engine, 'rpm_fuel')
        [bNew, hPlot] = plotLine(hAxes, engine.rpm_fuel, engine.Nm_fuel, 'k', engine.sMap, 'plotFuel');
        if bNew
            set(hPlot, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 12)
        end
        % xlim([min(engine.rpm_fuel) max(engine.Nm_fuel)])
    end

end
%-- plot absolute fuel map ------------------------------------------------
if isfield(engine, 'rpm_map') && bAbsFuel

    % kg/h lines
    LineDefinition = unique([1 2 10:10:100]); % [kg/h / timestep]

    % define thickness of line
    LineThickness = 1;
    % define color line of grid (and font)
    sColorLine = [0 0.5 0]; % green

    % label
    if ~isfield(engine, 'sMap_kgh')
        engine.sMap_kgh = 'fuel map [kg/h]';
    end

    % kgh-characteristic fuelmap
    hPlot = findobj(hAxes, 'Tag', 'plotMap_kgh');
    if isempty(hPlot)
        % make contour plot for fuelmap
        [C, hPlot] = contour(engine.rpm_map, engine.Nm_map, engine.kgh_map, LineDefinition);
		% set color of line grid and width of line grid
        set(hPlot,'LineColor',sColorLine,'LineWidth',LineThickness)
        % set fontsize and color of font
        clabel(C,hPlot,'FontName','corpos','FontSize',12,'Color',sColorLine);
        set(hPlot, 'Tag', 'plotMap')
    else
        set(hPlot, 'XData', engine.rpm_map, 'YData', engine.Nm_map, 'ZData', engine.kgh_map);
    end
    set(hPlot, 'DisplayName', engine.sMap_kgh)

    % Messpunkte Kennfeld
    if isfield(engine, 'rpm_fuel')
        [bNew, hPlot] = plotLine(hAxes, engine.rpm_fuel, engine.Nm_fuel, 'k', engine.sMap_kgh, 'plotFuel');
        if bNew
            set(hPlot, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 12)
        end
        % xlim([min(engine.rpm_fuel) max(engine.Nm_fuel)])
    end

end


%% Achsengrenzen
dXLim = get(hAxes, 'XLim');
dYLim = get(hAxes, 'YLim');


%% full load torque
if isfield(engine, 'rpm_full')

    % Bezeichnung
    if ~isfield(engine, 'sFull')
        engine.sFull = 'full load torque';
    end

    % Volllastlinie
    bNew = plotLine(hAxes, engine.rpm_full, engine.Nm_full, 'r', engine.sFull, 'plotFull');
    if bNew && bHyp
        hAxes2 = plotPowerHyp(hAxes); % Leistungshyperbeln plotten
    end

    % Achsenlimits
    [dXLim, dYLim] = defLim(dXLim, dYLim, engine.rpm_full, engine.Nm_full + 50); % 50 Nm bei Volllastline draufpacken

end


%% aspiration curve / transient curve
if isfield(engine, 'Nm_trans_step')

    % Bezeichnung
    if ~isfield(engine, 'sTransient')
        engine.sTransient = 'aspiration torque';
    end

    % Sprung- und Steigungskennlinie
    plotLine(hAxes, engine.rpm_trans_step, engine.Nm_trans_step, 'g', engine.sTransient, 'plotStep');
    try  %#ok<TRYNC>
        plotLine(hAxes, engine.rpm_trans_gradient, engine.Nmps_trans_gradient, ':g', engine.sTransient, 'plotGradient');
    end

    % Achsenlimits
    [dXLim, dYLim] = defLim(dXLim, dYLim, engine.rpm_trans_step, engine.Nm_trans_step + 50); % 50 Nm draufpacken

    sYLabel = 'torque [Nm], torque gradient [Nm/s]';

end


%% friction torque
if isfield(engine, 'rpm_fric')

    % Bezeichnung
    if ~isfield(engine, 'sFric')
        engine.sFric = 'friction torque';
    end

    % Schlepplinie
    plotLine(hAxes, engine.rpm_fric, engine.Nm_fric, 'b', engine.sFric, 'plotFric');

    % Achsenlimits
    [dXLim, dYLim] = defLim(dXLim, dYLim, engine.rpm_fric, engine.Nm_fric, 0);

end


%% exhaust brake / jake brake torque
if isfield(engine, 'Nm_exh')

    % Bezeichnung
    if ~isfield(engine, 'sExh')
        engine.sExh = 'exhaust brake torque';
    end

    % Motorbremslinie
    plotLine(hAxes, engine.rpm_exh, engine.Nm_exh, 'k', engine.sExh, 'plotExh');

    % Achsenlimits
    [dXLim, dYLim] = defLim(dXLim, dYLim, engine.rpm_exh, engine.Nm_exh, 0);

end


%% auxiliary torque
if isfield(engine, 'rpm_aux')

    % Bezeichnung
    if ~isfield(engine, 'sAux')
        engine.sAux = 'auxiliary torque';
    end

    % Nebenverbraucher
    % Werte positiv darstellen, da sie vom Verbrennungsmotor überwunden werden sollen
    plotLine(hAxes, engine.rpm_aux, -engine.Nm_aux, 'c', engine.sAux, 'plotAux');

    % Achsenlimits
    [dXLim, dYLim] = defLim(dXLim, dYLim, engine.rpm_aux, -engine.Nm_aux + 5, 0); % 5 Nm draufpacken

end

%% be_min curve

% convert bemin_range from percentage values to scalar
bemin_range = 1 + bemin_range/100;

% plot bemin
if isfield(engine, 'rpm_full') && isfield(engine, 'rpm_map') && bBemin
    
    % set vector of sample points for engine power. At this powers the
    % bemin value will be calculated, so this vector defines the stepsize
    % of the bemin curve [kW]
    kW_Powerhyp = [10:1:max(engine.rpm_full .* engine.Nm_full .*(pi/(30*1000)))];
    
    % build a Powerhyperbel for each kW_Powerhyp. Their rpm and Nm values
    % will be used as sample points for interpolation in the gkWh_map. This
    % provides gkWh values along each generated powerhyperbel.
    for k = 1:length(kW_Powerhyp)
        % Set rpm values for powerhyperbel to 500:1:2500
        rpm_Powerhyp = [500:1:2500]';
        % Calc Nm values for powerhyperbel
        Nm_Powerhyp = (kW_Powerhyp(k)*1000)./((pi/30).*rpm_Powerhyp);
        
        % delete Nm values where the Powerhyperbel is above the engine fullload
        % curve
        
        % therefore calculate Powervalues of fullload curve. Only the
        % section where the fullload Powervalues are above the
        % be_Powerhyperbel is valid.
        kW_fullload = [engine.rpm_full .* engine.Nm_full .*(pi/(30*1000))]';
        % interpolate kW_fullload curve on rpm powerhyperbel sample points
        kW_fullload_interp = interp1(engine.rpm_full,kW_fullload,rpm_Powerhyp);
        % cut out invalid section
        Nm_Powerhyp = Nm_Powerhyp(kW_fullload_interp >= kW_Powerhyp(k));
        rpm_Powerhyp = rpm_Powerhyp(kW_fullload_interp >= kW_Powerhyp(k));
        
        % Interpolate each point of the Powerhyperbel in the gkWh_map to
        % assign be values
        be_Powerhyp = interp2(engine.rpm_map, engine.Nm_map, engine.gkWh_map, rpm_Powerhyp, Nm_Powerhyp);
        % delete nan values
        rpm_Powerhyp = rpm_Powerhyp(~isnan(be_Powerhyp));
        Nm_Powerhyp = Nm_Powerhyp(~isnan(be_Powerhyp));
        be_Powerhyp = be_Powerhyp(~isnan(be_Powerhyp));
        
        % find minimum value on this Powerhyperbel -> This is the bemin value
        % get bemin value index
        [bemin_Powerhyp,bemin_ind] = min(be_Powerhyp);
        % build rpm_bemin vector.
        rpm_bemin(k) = rpm_Powerhyp(bemin_ind);
        % build Nm_bemin vector
        Nm_bemin(k) = Nm_Powerhyp(bemin_ind);
        % build kW_bemin vector
        kW_bemin(k) = rpm_bemin(k) * Nm_bemin(k) * pi /(30*1000);
        % build gkWh_bemin vector
        gkWh_bemin(k) = be_Powerhyp(bemin_ind);
        
        
        % calculate bemin_range
        
        % get bemin_range value
        bemin_bounds = bemin_Powerhyp * bemin_range;
        
        % calc upper bound
        % find index of first value that is below the bemin_range
        index = find(be_Powerhyp <= bemin_bounds, 1, 'first');
        % set rpm and Nm vector of upper bound
        rpm_bemin_ubound(k) = rpm_Powerhyp(index);
        Nm_bemin_ubound(k) = Nm_Powerhyp(index);
        
        % calc lower bound
        % find index of last value that is below the bemin_range
        index = find(be_Powerhyp <= bemin_bounds, 1, 'last');
        % set rpm and Nm vector of lower bound
        rpm_bemin_lbound(k) = rpm_Powerhyp(index);
        Nm_bemin_lbound(k) = Nm_Powerhyp(index);
    end

    
    % plot bemin curve
    hPlot = plot(hAxes, rpm_bemin', Nm_bemin', 'Color', [0.87,0.49,0], 'LineWidth', 3, 'DisplayName', 'bemin','Tag','plotBemin');
    % plot bemin range
    hPlot = plot(hAxes, rpm_bemin_ubound', Nm_bemin_ubound', 'Color', [0.87,0.49,0], 'LineWidth', 3,'LineStyle','--', 'DisplayName', sprintf('bemin + %1.0f%%',(bemin_range-1)*100),'Tag','plotBeminrangeUB');
    hPlot = plot(hAxes, rpm_bemin_lbound', Nm_bemin_lbound', 'Color', [0.87,0.49,0], 'LineWidth', 3,'LineStyle','--', 'DisplayName', sprintf('bemin + %1.0f%%',(bemin_range-1)*100),'Tag','plotBeminrangeLB');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % delete not monotonical increasing rpm values in the bemin curve to enable interpolation
    index = find(diff(rpm_bemin) <= 0);
    while ~isempty(index)
        % delete these values
        rpm_bemin(index+1) = [];
        Nm_bemin(index+1) = [];
        kW_bemin(index+1) = [];
        gkWh_bemin(index+1) = [];
        % new check for decreasing values
        index = find(diff(rpm_bemin) <= 0);
    end
    
    % save bemin curve in engine struct
    engine.rpm_bemin = rpm_bemin;
    engine.kW_bemin = kW_bemin;
    engine.gkWh_bemin = gkWh_bemin;

end

%% Achseneinstellung und -beschriftung
xlim(hAxes, dXLim)
ylim(hAxes, dYLim)
hold(hAxes, 'off')
grid(hAxes, 'on')

% Achsenbeschriftung
xlabel(hAxes, sXLabel)
ylabel(hAxes, sYLabel)

% Motorname
if isfield(engine, 'sName')
    title(hAxes, engine.sName, 'Interpreter', 'none')
end


%% Leerlaufverbrauch
if isfield(engine, 'lph_idle')
    hAnnot = annotation('textbox', [0.7, 0.85, 0.19, 0.06]);
    set(hAnnot, 'String', sprintf('Idle: %.2f l/h', engine.lph_idle));
    set(hAnnot, 'BackgroundColor', 'w');
end


%% Achsbeschriftung von Hyperbeln, wenn vorhanden
% kann erst jetz passieren, da die Grenzen
% xlim und ylim erst jetzt bekannt sind
if exist('hAxes2', 'var')
    hHyperbel = findobj(hAxes2, 'Tag', 'kW_hyperbel');
    xLim = get(hAxes, 'XLim');
    rpm = xLim(2);
    yTickLabel = get(hHyperbel, 'DisplayName');
    yTick = str2double(yTickLabel) * 1000 / (rpm * pi/30);
    [yTick, idx] = sort(yTick);
    yTickLabel = yTickLabel(idx);
    set(hAxes2, 'YTick', yTick, 'YTickLabel', yTickLabel)
end


%% Linie plotten oder bereits vorhandene ersetzen
function [bNew, hPlot] = plotLine(hAxes, x, y, sColor, sDisp, sTagHandle)
bNew = true;
hPlot = findobj(hAxes, 'Tag', sTagHandle);
sStyle = regexprep(sColor, '[a-zA-Z]', '');
sColor = regexprep(sColor, '[^a-zA-Z]', '');
if isempty(sStyle)
    sStyle = '-';
end
if isempty(hPlot)
    hPlot = plot(hAxes, x', y', 'Color', sColor, 'LineWidth', 3, 'LineStyle', sStyle, 'DisplayName', sDisp);
    set(hPlot, 'Tag', sTagHandle)
else
    for k = 1:length(hPlot)
        set(hPlot(k), 'XData', x(k,:)', 'YData', y(k,:)');
    end
    bNew = false;
end


%% Leistungshyperbeln plotten
function [hAxes2] = plotPowerHyp(hAxes)
rpm = [50:50:3000];
kW = [20:20:460]';
Nm = (kW * 1000) * (1./(rpm*pi/30));
Nm(Nm > 3000) = NaN;
% zweite Achse erstellen
hAxes2 = axes(...
    'HandleVisibility', get(hAxes,'HandleVisibility'), ...
    'Units',  get(hAxes,'Units'), ...
    'Position', get(hAxes,'Position'), ...
    'Parent', get(hAxes,'Parent'));
% Leistungshyperbeln plotten
hLine = plot(hAxes2, rpm, Nm, ':m', 'Tag', 'kW_hyperbel');
for k = 1:length(hLine)
    set(hLine(k), 'DisplayName', num2str(kW(k)))
end
% Achse konfigurieren
set(hAxes2, 'YAxisLocation', 'right', 'Color', 'none', ...
    'XGrid', 'off', 'YGrid', 'off', 'Box', 'off', 'HitTest','off');
set(hAxes2, 'XTick', [], 'XTickLabel', 0)
set(hAxes2, 'YColor', 'm')
set(hAxes2, 'Tag', 'AxesHyp')
% Achsen verbinden
linkaxes([hAxes, hAxes2])
% Y-Achsbeschriftung
ylabel(hAxes2, 'power [kW]', 'Color', 'm')
% Standard Achse zur aktuellen Achse machen, damit sich alle späteren
% Befehle auf diese Achse beziehen, aber den Hintergrund wechseln
axes(hAxes)
set(hAxes2, 'Color', get(hAxes, 'Color'))
set(hAxes, 'Color', 'none')


%% X-Y-Limits setzen
function [dXLim, dYLim] = defLim(dXLim, dYLim, x, y, bSetXLim)

% X-Limits setzen, wenn nicht explizit verboten,
% um bereits gesetzte Limits nicht zu überstimmen
if ~exist('bSetXLim', 'var') || isempty(bSetXLim)
    bSetXLim = true;
end

% xlim
if dXLim(1) == 0 % Achsengrenze noch nicht gesetzt
    dXLim(1) = min(x(:));
    dXLim(2) = max(x(:));
end
if bSetXLim
    dXLim(1) = min([dXLim(1) x(:)']);
    dXLim(2) = max([dXLim(2) x(:)']);
end

% ylim
dYLim(1) = min([0 dYLim(1) y(:)']); % 0 Linie sollte immer dabei sein
dYLim(2) = max([dYLim(2) y(:)']);
