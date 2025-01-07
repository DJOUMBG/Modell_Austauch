function getAP(varargin)
% GETAP get axes properties and store them with MATLAB instance.
%
% Syntax:
%   getAP
%   getAP(hAxes)
%
% Inputs:
%   ha    - axes handle
%
% Outputs:
%
% Example: 
%   getAP
%   getAP(hAxes)
%
% See also: gof
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2009-06-01

if nargin == 0
    % operate on currrent axis
    ha = gca;
else
    ha = varargin{1};
    if ~(ishandle(ha) && strcmpi('axes',get(ha,'Type')))
        ha = gca;
    end
end

% get all axes element properties
xProp.Figure = get(gof(ha));
xProp.Axes = get(ha);
xProp.XLabel = get(xProp.Axes.XLabel);
xProp.YLabel = get(xProp.Axes.YLabel);
xProp.ZLabel = get(xProp.Axes.ZLabel);
xProp.Title = get(xProp.Axes.Title);
for nIdxChild = 1:length(xProp.Axes.Children)
    if strcmpi('line',get(xProp.Axes.Children(nIdxChild),'Type'))
        xProp.Line(nIdxChild) = get(xProp.Axes.Children(nIdxChild));
    end
end

% store data with MATLAB instance
setappdata(0,'AxesPropertiesClipboard',xProp)

disp('Axes properties stored successful')
return

