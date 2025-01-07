function str = fullfileSL(varargin)
% FULLFILESL creates a simulink block path from single block names.
%
% Syntax:
%   str = fullfileSL(varargin)
%
% Inputs:
%   varargin - strings with blocknames or a cell with strings
%
% Outputs:
%   str - string with Simulink block path
%
% Example: 
%  str = fullfileSL('MyModel','Subsystem','Constant'); % returns 'MyModel/Subsystem/Constant' 
%  str = fullfileSL({'MyModel','Subsystem','Constant'}); % returns 'MyModel/Subsystem/Constant' 
%
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% create homogen cell input
strcell = {};
for k = 1:nargin
    try
        if iscell(varargin{k})
            strcell = [strcell, varargin{k}]; %#ok
        else
            strcell = [strcell, varargin(k)]; %#ok
        end
    catch
        disp(['An error occured with input argument number ' num2str(k)]);
        rethrow(lasterror)
    end
end
   
% remove empty cells
bEmpty = cellfun(@isempty,strcell);
strcell = strcell(~bEmpty);

% create block path
str = strcell{1};
for k = 2:length(strcell)
    str = [str '/' strcell{k}]; %#ok
end
if strcmp(str(end),'/')
    str = str(1:end-1);
end
return
