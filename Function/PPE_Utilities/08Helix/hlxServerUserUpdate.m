function hlxServerUserUpdate(varargin)
% HLXSERVERUSERUPDATE update user fullname and email address within Perforce from DIVe Organisation
% List Excel file.
%
% Syntax:
%   hlxServerUserUpdate(varargin)
%
% Inputs:
%   varargin - input arguments
%      sFileOrga - filepath of DIVe Organisation List xlsx
%
% Outputs:
%
% Example: 
%   hlxServerUserUpdate(varargin)
%
% See also: dbread, hlxOutParse, p4, strGlue, strsplitOwn
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2023-11-08

% file with DIVe access right informaton
if nargin < 1 || isempty(varargin{1})
    sFileOrga = 'C:\dirsync\06DIVe\32FunctionHelix\Organization\DIVeOrganizationList.xlsx';
else
    sFileOrga = varargin{1};
end
if exist(sFileOrga,'file')~=2
    sFileOrga = which('DIVeOrganizationList.xlsx');
end

% read ExcelSheet
xDB = dbread(sFileOrga,{'UserRoleTrainingGroups'});
dbUser = xDB.subset(1);

% reduce information of User Table
cName = dbrColGet(dbUser,'full name');
cEmail = dbrColGet(dbUser,'Email');
cIdAll = dbrColGet(dbUser,'User ID');

% get Helix users
cUser = hlxOutParse(p4('users'),' ',1,true);

% update user information on name and email adress
for nIdxUser = 1:numel(cUser)
    bId = strcmp(cUser{nIdxUser},cIdAll);
    if any(bId)
        % get fullname
        cSplit = strtrim(strsplitOwn(cName{bId},','));
        switch numel(cSplit)
            case 2
                sName = strGlue(cSplit([2,1]),' ');
            case 1
                sName = cSplit{1};
            otherwise
                % uncovered condition - report and proceed
                fprintf(1,'Encountered uncovered name entry for user ID "%s": "%s"\r\n',...
                    cUser{nIdxUser},cName{bId});
        end
        % update user entry
        [sMsg,nStatus] = p4(sprintf('--field FullName="%s" --field Email="%s" user -o %s| p4 user -i -f',...
            sName,cEmail{bId},cUser{nIdxUser}));
        if nStatus
            fprintf(2,'Error during user info Update: \n%s\n',sMsg);
        else
            fprintf(1,'Updated user "%s" \n',cUser{nIdxUser})
        end
    end
end
return
