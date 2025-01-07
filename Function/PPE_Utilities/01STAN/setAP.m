function setAP(varargin)
% SETAP set axes properties stored on MATLAB instance axes property
% clipboard.
%
% Syntax:
%   setAP
%   setAP(hAxes)
%   setAP(hAxes,bTextChange)
%
% Inputs:
%            ha - axes handle
%   bTextChange - boolean (1x1) if text string property shall be changed as
%                 well
%
% Outputs:
%
% Example: 
%   setAP
%   setAP(hAxes)
%
% Subfunctions: setLine, setString
%
% See also: gof
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2009-06-01

% get axes handle
if nargin == 0
    % operate on currrent axis
    ha = gca;
else
    ha = varargin{1};
    if ~(ishandle(ha) && strcmpi('axes',get(ha,'Type')))
        ha = gca;
    end
end
if nargin == 2
    bTextChange = varargin{2};
else
    bTextChange = true;
end
xTarget = get(ha); % get properties of target axes

% get clipboard axes properties
if isappdata(0,'AxesPropertiesClipboard')
    xProp = getappdata(0,'AxesPropertiesClipboard');
end

% set figure size
set(gof(ha),'Units',xProp.Figure.Units...
           ,'Position',xProp.Figure.Position);

% set all axes element properties
set(ha,'Box',xProp.Axes.Box...
      ,'XGrid',xProp.Axes.XGrid...
      ,'YGrid',xProp.Axes.YGrid...
      ,'ZGrid',xProp.Axes.ZGrid...
      ,'XScale',xProp.Axes.XScale...
      ,'YScale',xProp.Axes.YScale...
      ,'ZScale',xProp.Axes.ZScale...
      ,'YLim',xProp.Axes.YLim...
      ,'ZLim',xProp.Axes.ZLim);

% set axis and title properties
setString(xTarget.XLabel,xProp.XLabel,bTextChange);
setString(xTarget.YLabel,xProp.YLabel,bTextChange);
setString(xTarget.ZLabel,xProp.ZLabel,bTextChange);
setString(xTarget.Title,xProp.Title,bTextChange);

% set line children properties
for k = 1:length(xProp.Line)
    if k <= length(xTarget.Children)
        if strcmpi(get(xTarget.Children(k),'Type'),'line')
            setLine(xTarget.Children(k),xProp.Line(k),bTextChange);
        end
    end
end
return

% =========================================================================

function setString(h,xProp,bTextChange)
% setString - set basic axes string properties.
% 
% Input variables:
% h     - handle of an axes string 
% prop  - struct of handle properties of axes string 
% 
% Exampe calls:
% setString(h,prop)

set(h,'FontAngle',xProp.FontAngle...
     ,'FontName',xProp.FontName...
     ,'FontSize',xProp.FontSize...
     ,'FontWeight',xProp.FontWeight...
     ,'HorizontalAlignment',xProp.HorizontalAlignment...
     ,'Interpreter',xProp.Interpreter);
 
 if bTextChange
     set(h,'String',xProp.String);
 end
 return

% =========================================================================

function setLine(h,xProp,bTextChange)
% setString - set basic line properties.
% 
% Input variables:
% h     - handle of an line
% prop  - struct of handle properties of line
% 
% Exampe calls:
% setLine(h,prop)

set(h,'LineStyle',xProp.LineStyle...
     ,'LineWidth',xProp.LineWidth...
     ,'Color',xProp.Color...
     ,'Marker',xProp.Marker...
     ,'MarkerSize',xProp.MarkerSize...
     ,'MarkerEdgeColor',xProp.MarkerEdgeColor...
     ,'MarkerFaceColor',xProp.MarkerFaceColor);
 
if bTextChange
     set(h,'DisplayName',xProp.DisplayName);
end
return