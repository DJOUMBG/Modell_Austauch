function h = gcl
% GCL get current line. Returns a handle to the first selected line.
%
% Syntax:
%   h = gcl
%
% Inputs:
%
% Outputs:
%   h - handle vector with all selected line handles
%
% Example: 
%   h = gcl
%
% See also: gcbs, gcb
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-07-16

% gcl - get current line. Returns a handle to the first selected line.
h = find_system(gcs,'FindAll','on',...
                    'LookUnderMasks','all',...
                    'selected','on',...
                    'Type','line');
return