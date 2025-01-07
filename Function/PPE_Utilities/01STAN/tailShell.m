function sOut = tailShell(varargin) 
% TAILSHELL get the last lines of an ASCII file by a system tail function.
% Only single call - no follow option possible!
% (either Linux/Unix standard or Windows Powershell/GNU packs)
%
% Syntax:
%   sOut = tailShell(varargin)
%
% Inputs:
%   sNumber - '-n' with n numbers of lines to be displayed
%     sFile - string with filepath of file to be tailed
%
% Outputs:
%   sOut - string with output of tail function
%
% Example: 
%   sOut = tailShell(varargin)

% See also: strGlue
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-10-17

sCall = strGlue([{'tail'},varargin],' ');
[nStatus,sOut] = system(sCall);
if nStatus
    error('tailShell:errorOnCall',...
        'The following command produced an error: \n  %s\nwith message: \n  %s\n',...
        sCall,sOut)
end
return 
