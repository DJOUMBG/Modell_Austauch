function sCmd = fleCmdToOpenFolderInExplorer(sFolder)
% FLECMDTOOPENFOLDERINEXPLORER creates a Matlab command to open a folder in
% explorer.
%
% Syntax:
%   sCmd = fleCmdToOpenFolderInExplorer(sFolder)
%
% Inputs:
%   sFolder - string: folder to be opend with command in explorer 
%
% Outputs:
%   sCmd - string: Matlab command to open folder in explorer 
%
% Example: 
%   sCmd = fleCmdToOpenFolderInExplorer(sFolder)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-01

%% create command

sCmd = sprintf('system(%s%s %s %s%s);',...
    char(39),'explorer',sFolder,'&',char(39));

return