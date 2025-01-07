function hBlock = gcbs(nDepth)
% GCBS get current blocks. Returns a handle to all selected blocks.
%
% Syntax:
%   hBlock = gcbs(nDepth)
%
% Inputs:
%   nDepth - [optional] integer with searchdepth
%
% Outputs:
%   hBlock - handle of currently selected blocks
%
% Example: 
%   hBlock = gcbs
%   hBlock = gcbs(1)
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-12-16

% check input
if exist('nDepth','var') ~= 1
    nDepth = -1;
end

% search for block according option
if nDepth < 0
    hBlock = find_system(gcs,'FindAll','on',...
                             'FollowLinks','on',...
                             'LookUnderMasks','all',...
                             'Type','block',...
                             'selected','on');
else
    hBlock = find_system(gcs,'FindAll','on',...
                             'SearchDepth',nDepth,...
                             'FollowLinks','on',...
                             'LookUnderMasks','all',...
                             'Type','block',...
                             'selected','on');
end
return