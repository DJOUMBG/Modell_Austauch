function str = bool2str(bool)
% BOOL2STR transfers boolean value to 'on'/'off' for GUI/Simulink usage
%
% Syntax:
%   str = bool2str(bool)
%
% Inputs:
%   bool - boolean (1x1)
%
% Outputs:
%   str - character (1xn) with 'on' or 'off'
%
% Example: 
%   str = bool2str(true)
%   str = bool2str(false)
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2007-06-01

% error on non-integer input
if isinteger(bool) 
    error('only integer values 0 and 1 can be transfered to a GUI switch');
end

% translate to string
if bool == 1
    str = 'on';
elseif bool == 0
    str = 'off';
else
    error(['value is not 0 or 1 but ' num2str(bool)]);
end
return
