function varargout = gof(varargin)
% GOF (get object figure) returns the figure handle of an object (uicontrol
% or figure) and of the current callback object.
%
% Syntax:
%   hFigure = gof
%   hFigure = gof(hObject)
%   [hObject,hFigure] = gof(hObject)
%
% Inputs:
%   hObject - handle of object 
%
% Outputs:
%   hFigure - handle of figure containing the specifed object
%   hObject - handle of specifed or current callback object object
%
% Example: 
%   varargout = gof(varargin)
%
% See also: gcf, gcbo
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2006-11-24

if nargin == 0
    hObject = get(0, 'CallbackObject');
    if isempty(hObject)
        hObject = gcf;
    end
else
    hObject = varargin{1};
end

hFigure = hObject;
while ~strcmp(get(hFigure,'Type'),'figure') && ~isempty(get(hFigure,'Parent'))
    hFigure = get(hFigure,'Parent');
end

if nargout < 2
    varargout{1} = hFigure;
else
    varargout{1} = hObject;
    varargout{2} = hFigure;
end
return