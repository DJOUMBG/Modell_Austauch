function [sLinkMsg,sRawMsg] = strMsgWithMatCmdLink(sPre,sMatCmd,sLable,sPost)
% STRMSGWITHMATCMDLINK creates a message string which contains a link
% on a Matlab command, which will be executing when user is clicking on
% link lable. Additional the raw message without link is returned.
%
% Syntax:
%   [sLinkMsg,sRawMsg] = strMsgWithMatCmdLink(sPre,sMatCmd,sLable,sPost)
%
% Inputs:
%      sPre - string: string before lable
%   sMatCmd - string: Matlab command, to be executed when clicking link 
%    sLable - string: lable to be displayed as link 
%     sPost - string: string after lable
%
% Outputs:
%   sLinkMsg - string: string with link to matlab command
%    sRawMsg - string: string without link, only lable
%
% Example: 
%   [sLinkMsg,sRawMsg] = strMsgWithMatCmdLink(sPre,sMatCmd,sLable,sPost)
%
%
% See also: strcontain
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-01

%% create string with link

% error handling
if strcontain(sMatCmd,'"')
    error('createMsgWithMatCmdLink:InvalidCharacter',...
        'Matlab command contains invalid character " for link creating.');
end

% create command
sLinkMsg = sprintf('%s <a href = "matlab: %s">%s</a> %s',...
    sPre,sMatCmd,sLable,sPost);

% create raw
sRawMsg = sprintf('%s "%s" %s',sPre,sLable,sPost);

return