function hlxAccessGroupUserTransfer(varargin)
% HLXACCESSGROUPUSERTRANSFER create users, groups and access table in Helix
% according DIVeOrganizationList.
%
% Syntax:
%   hlxAccessGroupUserTransfer
%   hlxAccessGroupUserTransfer(sFileOrga)
%   hlxAccessGroupUserTransfer(sFileOrga,bGroupUpdate)
%
% Inputs:
%      sFileOrga - string with filepath of DIVeOrganizationList.xlsx
%   bGroupUpdate - boolean if group update should be done
%   sPathCompare - string with path of compare directory
%
% Outputs:
%
% Example: 
%   hlxAccessGroupUserTransfer('C:\dirsync\06DIVe\32FunctionHelix\Organization\DIVeOrganizationList.xlsx',false)
%   hlxAccessGroupUserTransfer('C:\frmoelle\01_Helix\10_drd_DIVeScripts\Organization\DIVeOrganizationList.xlsx',false,'C:\Temp\HelixAccessRights') % für Frank
%
% See also: dbread
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-07-06

% file with DIVe access right informaton
if nargin < 1 || isempty(varargin{1})
    sFileOrga = 'C:\dirsync\06DIVe\32FunctionHelix\Organization\DIVeOrganizationList.xlsx';
else
    sFileOrga = varargin{1};
end
if exist(sFileOrga,'file')~=2
    sFileOrga = which('DIVeOrganizationList.xlsx');
end
if nargin < 2
    bGroupUpdate = true;
else
    bGroupUpdate = varargin{2};
end
if nargin < 3 || isempty(varargin{1})
    sPathCompare = 'C:\dirsync\08Helix\00Ressource\accessRights';
else
    sPathCompare = varargin{3};
end

% check input
if ~exist(sFileOrga,'file')
    error('hlxAccessGroupUserTransfer:fileNotFound',...
        '');
end

% read ExcelSheets
xDB = dbread(sFileOrga,'GroupAccessRights',2); % omit first line for header
dbGroup = xDB.subset;
xDB = dbread(sFileOrga,{'UserRoleTrainingGroups','NonContentAccessFront',...
                        'NonContentAccessRear','ConfidentialContent'});
dbUser = xDB.subset(1);
dbAccessFront = xDB.subset(2);
dbAccessRear = xDB.subset(3);
dbConfid = xDB.subset(4);
xConf = db2ConfidentialStruct(dbConfid);

% reduce information of User Table
bActive = cellfun(@isempty,dbrColGet(dbUser,'inactive DIVe member'));
bDIVeUser = ~cellfun(@isempty,dbrColGet(dbUser,'prj_basic'));
nDIVeUser = find(strcmp(dbUser.field,'prj_basic'));
bUserAny = false(size(bActive));
for nIdxUser = 1:numel(bUserAny)
    bUserAny(nIdxUser) = any(~cellfun(@isempty,dbUser.value(nIdxUser,nDIVeUser:end)));
end
dbUser.value = dbUser.value(bActive&(bDIVeUser|bUserAny),:);

% % reduce information of Group Table
% bColOnhold = strcmp('onhold',regexp(dbGroup.field,'onhold','match','once'));
% bOnhold = ~cellfun(@isempty,dbGroup.value(:,bColOnhold));
% dbGroup.value = dbGroup.value(~bOnhold,:);

% DEBUG ONLY
assignin('base','dbUser',dbUser);
assignin('base','dbGroup',dbGroup)

%% collect group info
cUser = dbrColGet(dbUser,'User ID');
% cGroup = dbrColGet(dbGroup,'name');
nPrjDIVeUser = find(strcmp('prj_basic',dbUser.field));
cGroup = dbUser.field(nPrjDIVeUser:end);
bEmpty = cellfun(@isempty,cGroup);
cGroup = cGroup(~bEmpty);
cGroupUnique = unique(cGroup);
for nIdxGroup = 1:numel(cGroupUnique)
    xGroup(nIdxGroup).name = cGroupUnique{nIdxGroup}; %#ok<AGROW>
    
    % determine users of group
    cUserOfGroup = dbrColGet(dbUser,xGroup(nIdxGroup).name);
    xGroup(nIdxGroup).user = cUser(~cellfun(@isempty,cUserOfGroup)); %#ok<AGROW>
    
    % determine owners of this group
    xGroup(nIdxGroup).owner = cUser(strcmp('o',cUserOfGroup)); %#ok<AGROW>
end

% determine column IDs of dbGroup
bName = strcmp(dbGroup.field,'name');
bConf = strcmp(dbGroup.field,'Common Confidential');
bStream = strcmp(dbGroup.field,'stream');
bContext = strcmp(dbGroup.field,'context');
bSpecies = strcmp(dbGroup.field,'species');
bFamily = strcmp(dbGroup.field,'family');
bType = strcmp(dbGroup.field,'type');
bClass = strcmp(dbGroup.field,'datasetClass');
bWrite = strcmp(dbGroup.field,'write');
bRead = strcmp(dbGroup.field,'read');
bLogHier = bContext|bSpecies|bFamily|bType;

% resort rules for access approach in Helix
[cTrash,nIdSort] = sort(dbGroup.value(:,bConf)); %#ok<ASGLU>
dbGroup.value = dbGroup.value(nIdSort,:);

%% expand access information
bCommon = strcmp('Common',dbGroup.value(:,bConf));
cAccessCommon = cell(sum(bCommon),1);
cAccessConfidential = cell(sum(~bCommon),1);
cDepot = {'//DIVe'};
cStreamDefault = {'d*'}; % default stream spec
cContent = {'com/DIVe/Content'};
for nIdxRow = 1:size(dbGroup.value,1)
    % determine role/access level
    if strcmp('x',dbGroup.value{nIdxRow,bWrite})
        sRole = 'write';
    elseif strcmp('x',dbGroup.value{nIdxRow,bRead})
        sRole = 'read';
    else
        % should not happen - neither read nor write
        fprintf(2,['DIVeOrganzitionList entry without read or ' ...
                   'admin permission: group "%s", logical hierarchy "%s"\n'],...
                   dbGroup.value{nIdxRow,bName},strGlue(dbGroup.value(nIdxRow,bLogHier),'.'));
        sRole = 'list';
    end
    
    %% create specification of affected files
    % take care of special stream definitions
    if isempty(dbGroup.value{nIdxRow,bStream})
        % standard stream defintion (d*) 
        cStream = cStreamDefault;
    else
        % use explizit stream definition
        cStream = dbGroup.value(nIdxRow,bStream);
    end
    % take care of dataset classType entries
    if isempty(dbGroup.value{nIdxRow,bClass})
        % standard tree in logical hierarchy
        sFileSpec = strGlue([cDepot cStream cContent dbGroup.value(nIdxRow,bLogHier) {'...'}],'/');
    else
        % single dataset classType rule
        sFileSpec = strGlue([cDepot cStream cContent dbGroup.value(nIdxRow,bLogHier) ...
                            {'Data'} dbGroup.value(nIdxRow,bClass) {'...'}],'/');
    end
    sGroup = dbGroup.value{nIdxRow,bName};
    
    if bCommon(nIdxRow)
        % grant access on Common Content
        %     read group usr_PPE_Utility * //PPE_Utility/Matlab/...
        cAccessCommon{nIdxRow} = strGlue({sRole,'group',sGroup,'*',sFileSpec},' ');
    else
        % grant access on Confidential Content
        cAccessConfidential{nIdxRow-sum(bCommon)} = strGlue({sRole,'group',sGroup,'*',sFileSpec},' ');
    end
end

%% create exclude rules 
cExclude = cell(numel(xConf),1);
for nIdxEntry = 1:numel(xConf)
    % context, species, family, type
    cCsft = {xConf(nIdxEntry).context,xConf(nIdxEntry).species,...
             xConf(nIdxEntry).family,xConf(nIdxEntry).type};
    bEmpty = cellfun(@isempty,cCsft);
    cCsft = cCsft(~bEmpty);
    % add module name entry
    if ~isempty(xConf(nIdxEntry).name)
        cCsft = [cCsft {'Module',xConf(nIdxEntry).name}]; %#ok<AGROW>
    end
    % add ModelSet entry
    if ~isempty(xConf(nIdxEntry).ModelSet)
        if isempty(xConf(nIdxEntry).name)
            % patch missing levels and "Module", module variant
            cCsft = [cCsft repmat({'*'},1,4-numel(cCsft)) ...
                     {'Module','*',xConf(nIdxEntry).ModelSet}]; %#ok<AGROW>
        else
            % logical hierarchy should be already complete until module variant
            cCsft = [cCsft {xConf(nIdxEntry).ModelSet}]; %#ok<AGROW>
        end
    end
    % create full filespec for access table entry
    sFileSpec = strGlue([cDepot cStreamDefault cContent cCsft {'...'}],'/');
    % exclude rule on confidential content
    cExclude{nIdxEntry} = strGlue({'list','group','*','*',['-' sFileSpec]},' ');
end

%% create front part of access table list
cAccessFront = cell(size(dbAccessFront.value,1),1);
% bValid = true(size(cAccessFront));
bAccessLevel = strcmp('AccessLevel',dbAccessFront.field);
bGroupName = strcmp('GroupName',dbAccessFront.field);
bFolderDefinition = strcmp('FolderDefinition',dbAccessFront.field);
for nIdxRow = 1:size(dbAccessFront.value,1)
    sRole = dbAccessFront.value{nIdxRow,bAccessLevel};
    sGroup = dbAccessFront.value{nIdxRow,bGroupName};
    sFileSpec = dbAccessFront.value{nIdxRow,bFolderDefinition};
    cAccessFront{nIdxRow} = strGlue({sRole,'group',sGroup,'*',sFileSpec},' ');
end

%% create rear part of access table list
cAccessRear = cell(size(dbAccessRear.value,1),1);
% bValid = true(size(cAccessRear));
bAccessLevel = strcmp('AccessLevel',dbAccessRear.field);
bGroupName = strcmp('GroupName',dbAccessRear.field);
bFolderDefinition = strcmp('FolderDefinition',dbAccessRear.field);
for nIdxRow = 1:size(dbAccessRear.value,1)
    sRole = dbAccessRear.value{nIdxRow,bAccessLevel};
    sGroup = dbAccessRear.value{nIdxRow,bGroupName};
    sFileSpec = dbAccessRear.value{nIdxRow,bFolderDefinition};
    cAccessRear{nIdxRow} = strGlue({sRole,'group',sGroup,'*',sFileSpec},' ');
end

% add super users
cSuper = {'list user * * -//spec/...';
          'list user * * //spec/stream/*';
          'read user * * //spec/stream/DIVe/...';
          'super user diveonesys * //...';
          'super group SuperUser * //...';
          'super group service_users * //...';
          'super user admin * //...';
          'super user rafrey5_admin * //...';
          'super user rafrey5 * //...'};

% combine parts of access table
cAccess = [cAccessFront; cAccessCommon; cExclude; cAccessConfidential; cAccessRear; cSuper];
% correction of Microsoft autochange on format character of "..."
cAccess = strrep(cAccess,char(224),'...');
cAccess = strrep(cAccess,char(8230),'...');


% TEMP print rules for copy paste
fprintf(1,'Access table from DIVeOrganizationList:\n\n');
for nIdxLine = 1:numel(cAccess)
    fprintf(1,'%s\n',cAccess{nIdxLine});
end
fprintf(1,'\nEnd of Access table\n');

% print rules to compare file
if ~exist(sPathCompare,'dir')
    mkdir(sPathCompare);
end
% write file with current protections
cAccessCurrent = hlxFormParse(p4('protect -o'),'Protections','',inf,true);
cAccessCurrent = strrep(cAccessCurrent,char(224),'...');
cAccessCurrent = strrep(cAccessCurrent,char(8230),'...');
sFileOld = fullfile(sPathCompare,'old.txt');
nFid = fopen(sFileOld,'w');
for nIdxLine = 1:numel(cAccessCurrent)
    fprintf(nFid,'%s\n',cAccessCurrent{nIdxLine});
end
fclose(nFid);

% write file with new protections
sFileNew = fullfile(sPathCompare,'new.txt');
nFid = fopen(sFileNew,'w');
for nIdxLine = 1:numel(cAccess)
    fprintf(nFid,'%s\n',cAccess{nIdxLine});
end
fclose(nFid);

% open P4Merge with both versions
system(sprintf('p4merge.exe %s %s &',sFileOld,sFileNew));

% DEBUG ONLY
% assignin('base','xUser',xUser);
assignin('base','xGroup',xGroup)
assignin('base','cAccess',cAccess)

%% update groups
if bGroupUpdate
    for nIdxGroup = 1:numel(xGroup)
        % set group in Helix
        p4group(xGroup(nIdxGroup).name,xGroup(nIdxGroup).user,xGroup(nIdxGroup).owner);
    end
end
% if bAccessUpdate
%     % TODO - doesnot work as command gets to long!! -> write file and use
%     % form file for scripting
%     p4form('protect','Protections',cAccess);
% end
return

% =========================================================================

function xConf = db2ConfidentialStruct(xSubset)
% DB2CONFIDENTIALSTRUCT create a confidential definition structure from a
% Excel dbread structure of DIVe Confidential definition from
% DIVeOrganizationList.
%
% Syntax:
%   xConf = db2ConfidentialStruct(xSubset)
%
% Inputs:
%   xSubset - structure with fields: 
%     .field - cell (1xn) with field names 
%     .value - cell (mxn) with field values
%
% Outputs:
%   xConf - structure to define confidential Module trees: 
%     .context  - string with context
%     .species  - string with species
%     .family   - string with family
%     .type     - string with type
%     .name     - string with name
%     .ModelSet - string with ModelSet (hybrid collection)
%
% Example: 
%   xDB = dbread('DIVeOrganizationList.xlsx','ConfidentialContent')
%   xConf = db2ConfidentialStruct(xDB.subset)

% init struct
xConf = structInit(xSubset.field);

% build content for next struct
for nIdxRow = 1:size(xSubset.value,1)
    cIn = reshape([xSubset.field;cell(1,numel(xSubset.field))],1,[]);
    for nIdxField = 1:numel(xSubset.field)
        cIn{nIdxField*2} = xSubset.value(nIdxRow,nIdxField);
    end
    
    % initialize next struct entry
    xConf(nIdxRow) = struct(cIn{:});
end
return
