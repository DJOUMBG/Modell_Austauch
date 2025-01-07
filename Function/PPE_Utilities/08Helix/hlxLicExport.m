function cUser = hlxLicExport(sFile)
% HLXLICEXPORT export currect DIVe user list as user license file
%
% Syntax:
%   cUser = hlxLicExport
%   cUser = hlxLicExport(sFile)
%
% Inputs:
%   sFile - [optional] string with filepath of DIVeOrganizationList.xlsx
%
% Outputs:
%   cUser - cell (mx4) with user IDs and end date of license
%
% Example: 
%   cUser = hlxLicExport(sFile)
%
% See also: hlxLicExport, pathparts
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-12-04

% define lease date
nDate = [2024,12,31];

% determine DIVeOrginationListl.xlsx
if nargin < 1
    % create list of location candidates
    cPath = pathparts(mfilename('fullpath'));
    cFile = {fullfile(cPath{1:end-3},'Organization','DIVeOrganizationList.xlsx')
             fullfile(cPath{1:end-2},'Organization','DIVeOrganizationList.xlsx')
             'C:\dirsync\06DIVe\32FunctionHelix\Organization\DIVeOrganizationList.xlsx'
             'C:\frmoelle\01_Helix\10_drd_DIVeScripts\Organization\DIVeOrganizationList.xlsx'};
    % check locations
    nExist = 0;
    bExist = false;
    while nExist < numel(cFile) && ~bExist
        nExist = nExist + 1;
        bExist = exist(cFile{nExist},'file');
    end
    % check success and fallback
    if bExist
        sFile = cFile{nExist};
    else
        sFile = uigetfile('DIVeOrganizationList.xlsx','Select DIVeOrganizationList.xlsx');
    end
    if isempty(sFile) || isnumeric(sFile)
        return
    end
end
 
% load list
xDB = dbread(sFile,'UserRoleTrainingGroups');
bColUser = strcmp('User ID',xDB.subset.field);
bColInactive = strcmp('inactive DIVe member',xDB.subset.field);
bActive = cellfun(@isempty,xDB.subset.value(:,bColInactive));
cUser = xDB.subset.value(bActive,bColUser);

cUser = [cUser; {'e019_tpc-pc_s_diveq'}];

% create user entries
cLine = cellfun(@(x)sprintf('''%s'',%i,%02i,%02i',lower(x),nDate(:)),cUser,'UniformOutput',false);

% add header & end
cHeader = {...
    'function [cUser] = licUser()'
    '% licUser creates cell list of valid users.'
    ''
    '% userID, yyyy,mm,dd'
    'cUser = {...'};
cEnd = {...
    '    };'
    'return'};
cLine = [cHeader; cLine; cEnd];

% write file 
sLic = 'licUser.m'; % TODO - how to determine the correct folder?!?
nFid = fopen(sLic,'w');
for nIdxLine = 1:numel(cLine)
    fprintf(nFid,'%s\n',cLine{nIdxLine});
end
fclose(nFid);
fprintf(1,'Written to file: %s\n',sLic);
return
