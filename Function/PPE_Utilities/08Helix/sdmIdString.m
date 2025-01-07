function sId = sdmIdString(xCollection)
% SDMIDSTRING create DIVe unique ID file in all XML locations of
% collection.
%
% Syntax:
%   sId = sdmIdString(xCollection)
%
% Inputs:
%   sPathCollection - string with target path of collection copy operation
%                     (for module: module variant path,
%                      for dataset: dataset class type path,
%                      for supportset: "Support" folder of level)
%   xCollection - structure with fields: 
%    .CollectionName     - string with collection name
%    .BranchName         - string with branch name of collection version
%    .ClassificationName - string with uppermost SysDM Classification
%    .BranchVersion      - integer with collection version in this branch
%    .Time               - integer with checkin time in seconds since
%                          00:00:00 01.01.1970
% Outputs:
%   sId - string with SysDM ID derived from Collection info
%
% Example: 
%   xCollection.BranchName = 'AutoUpdate11';
%   xCollection.BranchVersion = 4;
%   sdmIdString(xCollection)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-06-08

% determine collection number
sBranchNo = regexp(xCollection.BranchName,'\d+$','match','once');
if isempty(sBranchNo)
    if strcmp(xCollection.BranchName,'trunk')
        nBranch = xCollection.BranchVersion + 1;
        nVersion = 0;
    else
        nBranch = 0;
        nVersion = xCollection.BranchVersion;
    end
else
    nBranch = str2double(sBranchNo);
    nVersion = xCollection.BranchVersion;
end

% create DIVeID string
sId = sprintf('%i.%i',nBranch,nVersion);
return
