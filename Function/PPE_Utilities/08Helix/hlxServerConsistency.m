function hlxServerConsistency(varargin)
% HLXSERVERCONSISTENCY check basic consistency of DIVeOrganizationList and
% Perforce Helix groups and activated users.
%
% Syntax:
%   hlxServerConsistency(varargin)
%
% Inputs:
%   sFileOrga - string with filepath of DIVeOrganizationList
%
% Outputs:
%
% Example: 
%   hlxServerConsistency(varargin)
%
% See also: dbread, hlxOutParse, p4
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-02-14

% file with DIVe access right informaton
if nargin < 1 || isempty(varargin{1})
    sFileOrga = 'C:\dirsync\06DIVe\32FunctionHelix\Organization\DIVeOrganizationList.xlsx';
else
    sFileOrga = varargin{1};
end
if exist(sFileOrga,'file')~=2
    sFileOrga = which('DIVeOrganizationList.xlsx');
end


% get group information from DIVeOrganizationList
xDB = dbread(sFileOrga,'UserRoleTrainingGroups');
nColHelix = find(strcmp('Helix',xDB.subset.field));
bColInactive = strcmp('inactive DIVe member',xDB.subset.field);
cGroupExcel = xDB.subset.field(nColHelix+1:end);
bActive = cellfun(@isempty,xDB.subset.value(:,bColInactive));
xDB.subset.value = xDB.subset.value(bActive,:); % remove inactive user entries

%% check group consistency
% get groups from Helix
cGroupHelix = hlxOutParse(p4('groups'),{' '},1,true);

% match groups
[cOr,nExcel,nHelix] = setxor(cGroupExcel,cGroupHelix); %#ok<ASGLU>

% report singular group appearance
fprintf(1,'\nGroups exclusive to DIVeOrganizationList.xlsx:\n');
for nIdxGroup = nExcel'
    fprintf(1,'%s\n',cGroupExcel{nIdxGroup});
end
fprintf(1,'\nGroups exclusive to Helix:\n');
for nIdxGroup = nHelix'
    fprintf(1,'%s\n',cGroupHelix{nIdxGroup});
end

%% check user consistency
% get Helix users from DIVeOrganizationList
bHelix = ~cellfun(@isempty,xDB.subset.value(:,nColHelix));
cUserExcel = strtrim(xDB.subset.value(bHelix,[4,1,2,3,nColHelix]));

% get users from Helix
cUserHelix = strtrim(hlxOutParse(p4('users'),{'<','>','(',')'},1,true));

% match users
[cOr,nExcel,nHelix] = setxor(cUserExcel(:,1),cUserHelix); %#ok<ASGLU>

% report singular group appearance
fprintf(1,'\nHelix Users exclusive to DIVeOrganizationList.xlsx:\n');
for nIdxUser = nExcel'
    fprintf(1,['<a href="matlab:disp(''Activating user %s in Helix...'');' ...
        'hlxUserActivate(''%s'');disp(''... done.'');">%s</a>  %s %s %s %s\n'],...
        cUserExcel{nIdxUser,1},cUserExcel{nIdxUser,1},cUserExcel{nIdxUser,:});
end
fprintf(1,'\nUsers exclusive to Helix:\n');
for nIdxUser = nHelix'
    fprintf(1,'%s\n',cUserHelix{nIdxUser});
end
return
