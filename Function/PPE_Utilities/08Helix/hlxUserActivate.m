function hlxUserActivate(varargin)
% HLXUSERACTIVATE create users based on the DIVeOrganizationList - either
% interactive or via batch.
%
% Syntax:
%   hlxUserActivate
%   hlxUserActivate(sFileOrga)
%   hlxUserActivate(sUser1,sUser2,sUser3)
%   hlxUserActivate(sFileOrga,sUser1,sUser2,sUser3)
%
% Inputs:
%   sFileOrga - [optional] string with filepath of DIVeOrganizationList.xlsx
%    varargin - [optional] (1xn) strings with user IDs to be activated in
%               HelixCore server (attach to a license)
%
% Outputs:
%
% Example: 
%   hlxUserActivate('C:\dirsync\06DIVe\32FunctionHelix\Organization\DIVeOrganizationList.xlsx')
%   hlxUserActivate('rafrey5','kthiyar')
%
% See also: dbread, hlxOutParse, hlxUserActivate, p4, strGlue, strsplitOwn
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-06-14

% default
sFileOrga = 'C:\dirsync\06DIVe\32FunctionHelix\Organization\DIVeOrganizationList.xlsx';
if exist(sFileOrga,'file')~=2
    sFileOrga = which('DIVeOrganizationList.xlsx');
end

% file with DIVe access right informaton
if nargin > 0
    if exist(varargin{1},'file')==2
        sFileOrga = varargin{1};
        cAdd = varargin(2:end);
    else
        cAdd = varargin;
    end
    if nargin == 1 && iscell(varargin{1})
        cAdd = varargin{1};
    elseif nargin == 2 && iscell(varargin{2})
        cAdd = varargin{2};
    end
else
    cAdd = {};
end

% check input
if ~exist(sFileOrga,'file')
    error('hlxAccessGroupUserTransfer:fileNotFound',...
        'The file DIVeOrganizationList.xlsx was not found - please use in first argument.');
end

% read ExcelSheets
xDB = dbread(sFileOrga,4);
dbUser = xDB.subset;

% get users of current p4 instance
cUser = hlxOutParse(p4('users'),' ',1,true);

% determine activation users
cName = dbrColGet(dbUser,'full name');
cEmail = dbrColGet(dbUser,'Email');
cIdAll = dbrColGet(dbUser,'User ID');
cInactive = dbrColGet(dbUser,'inactive DIVe member');
bActive = cellfun(@isempty,cInactive);
cId = cIdAll(bActive);
cNameDisp = cName(bActive);
bHelix = ismember(cId,cUser);
cId = cId(~bHelix); % remove users, which exist already
cNameDisp = cNameDisp(~bHelix); % remove users, which exist already

if isempty(cAdd)
    % ask for users to activate
    nSelection = listdlg('Name','Select Users',...
        'ListString',cNameDisp,...
        'PromptString','Select Users for activation on server',...
        'SelectionMode','multiple',...
        'ListSize',[200 250]);
    if isempty(nSelection)
        return
    end
    cId = cId(nSelection);
else
    % check for matching users in batch mode
    bMatch = ismember(cId,cAdd);
    cId = cId(bMatch);
end

% activate/create users in Perforce
for nIdxUser = 1:numel(cId)
    % determine string inputs
    bThis = strcmp(cId{nIdxUser},cIdAll);
    cNameSingle = strsplitOwn(cName{bThis},',');
    sName = strGlue(fliplr(cNameSingle'),' ');
    sEmail = cEmail{bThis};
    
    % create user
    p4(sprintf('--field Email="%s" --field FullName="%s" user -o %s | p4 user -i -f',...
        sEmail,sName,cId{nIdxUser}));
    
    % set user to ldap authentication
    p4(sprintf('--field AuthMethod=ldap user -o %s | p4 user -i -f',cId{nIdxUser}));
end
return
