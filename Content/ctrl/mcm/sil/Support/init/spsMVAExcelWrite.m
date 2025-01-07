function spsMVAExcelWrite(sFileData,sPath)
% SPSMVAEXCELWRITE conversion function from DIVeMB ToDisc output MVA*.asc in
% Uniplot UXX ASCII format into the MVAPC import *.xlsm ATF converter.
%
% Syntax:
%   spsMVAExcelWrite(sFileData,sPath)
%
% Inputs:
%   sFileData - string with filepath of MVA*.asc output data of DIVe MB
%       sPath - string with path to place the ATF Converter *.xlsm
%
% Outputs:
%
% Example: 
%   spsMVAExcelWrite(sFileData,sPath)

disp('Data transfer to Excel for MVA import...')

% load data from MVA*.asc file or use passed structure
if isstruct(sFileData)
    xSubset = sFileData;
%     sFileData = fullfile(xSubset.location.path,xSubset.location.name);
else 
    MpxSources = spsUniread(sFileData);
    xSubset = MpxSources(1).subset(1);
end
xAttribute = xSubset.attribute;

% define attribute lists for ATF converter Excel sheets
cMotID = {'MOTID'	'STRING';
          'D'   	'FLOAT';
          'S'   	'FLOAT';
          'Z'   	'LONG'};

cTest  = {'ABT'     'STRING';
          'CVPROG'  'STRING';
          'PRSTNR'   	'STRING';
          'VersuchsTyp'   	'STRING';
          'DAN'   	'FLOAT';
          'D1'   	'FLOAT';
          'D2'   	'FLOAT';
          'D2N'   	'FLOAT';
          'D2S'   	'FLOAT';
          'D31'   	'FLOAT';
          'D32'   	'FLOAT';
          'D4'   	'FLOAT';
          'D5'   	'FLOAT';
          'DV'   	'FLOAT';
          'DT'   	'FLOAT';
          'EPS'   	'FLOAT';
          'HU'   	'FLOAT';
          'D32'   	'FLOAT';
          'D32'   	'FLOAT'};

cMeasurement = {'BRBLMA'	'STRING';
          'CMPROG_A'   	'STRING';
          'MessTyp'   	'STRING';
          'Messung'   	'STRING';
          'USER'        'STRING';
          'DATUME'   	'DATE';
          'MessBeginn'  'DATE';
          'MessEnde'    'DATE';
          'TEXT01'   	'STRING';
          'TEXT02'   	'STRING';
          'TEXT03'   	'STRING';
          'TEXT04'   	'STRING';
          'TEXT05'   	'STRING';
          'XDATSAEE'   	'STRING';
          'XDATSNEE'   	'STRING';
          'ZLA'         'LONG'};

% % save mat file of *.asc
% [sPathSource,sFile] = fileparts(sFileData);
% save(fullfile(sPathSource,[sFile,'.mat']),'MpxSources');

% copy ATF converter template
sMessTyp = getAttribute('MessTyp',xAttribute);
sMotID = getAttribute('MOTID',xAttribute);
sBRBLMA = num2str(getAttribute('BRBLMA',xAttribute));
sCMPROG_A = num2str(getAttribute('CMPROG_A',xAttribute));
if strcmp(sMessTyp,'ZYK')
    sCMPROG_A = sprintf('%s_%s','R#001',sCMPROG_A);
end
sFileATF = fullfile(sPath,sprintf('%s_%s_%s.xlsx',sMotID,sBRBLMA,sCMPROG_A));
copyfile(which('ATF_Template.xlsx'),sFileATF);

% sort/create (SYS)RECZEIT and calculate "MessEnde"
xSubset = spsUnireadMVACorrection(xSubset);

% write attributes into sheets
cSheet = createSheetAttribute(cMotID,xAttribute);
xlswrite(sFileATF,cSheet,'MotID');
cSheet = createSheetAttribute(cTest,xAttribute);
xlswrite(sFileATF,cSheet,'Test');
cSheet = createSheetAttribute(cMeasurement,xAttribute);
xlswrite(sFileATF,cSheet,'Measurement');

% remove non-MVA data
bKeep = cellfun(@(x)strcmp(upper(x),x),xSubset.data.name);
xSubset.data.name = xSubset.data.name(bKeep);
xSubset.data.value = xSubset.data.value(:,bKeep);

% generate TIMESTMP (Datum + Zeit) for Data1
vMessBeginn = datevec(num2str(getAttribute('MessBeginn',xSubset.attribute)),'yyyymmddHHMMSS'); 
mTIMESTMP = repmat(vMessBeginn,[size(xSubset.data.value,1),1]);
mTIMESTMP = addDatevec(mTIMESTMP,...
    [zeros(size(xSubset.data.value,1),5) xSubset.data.value(:,1)]);
vTIMESTMP = datevec2num(mTIMESTMP);
xSubset.data.name = [xSubset.data.name {'TIMESTMP'}];
xSubset.data.value = [xSubset.data.value vTIMESTMP];

% prepare data for writing
cSheet = cell(1,numel(xSubset.data.name));
cSheet{1,1} = 'Data';
cSheet{1,2} = 1;
cSheet(2,:) = xSubset.data.name;
% cSheet(3,:) = ; % TODO units
cSheet(4,:) = repmat({'FLOAT'},1,numel(xSubset.data.name));
cSheet = [cSheet; num2cell(xSubset.data.value)];

% write data into sheets
xlswrite(sFileATF,cSheet,'Data1');
disp('... data transfer finished.')
return

% =========================================================================

function cSheet = createSheetAttribute(cAttribute,xAttribute)
% CREATESHEETATTRIBUTE create cell with attribute content for ATF converter
% Excel sheet. 
%
% Syntax:
%   cSheet = createSheetAttribute(cAttribute,xAttribute)
%
% Inputs:
%   cAttribute - cell (mx2) with attribute names and their DATA TYPE of the
%                current ATF Excel sheet
%   xAttribute - structure with fields: 
%       .name  - cell with strings containing attribute names
%       .value - cell with strings or values containing attribute values
%
% Outputs:
%   cSheet - cell (nx4) with strings and values for use with xlswrite 
%
% Example: 
%   cSheet = createSheetAttribute({'USER','STRING';'BRBLMA','STRING'},xAttribute)

% create header line
cSheet = {'NAME','DATA TYPE','UNIT','VALUE'};

% add all attributes which are matched in the data structure
for nIdxAttribute = 1:size(cAttribute,1)
    value = getAttribute(cAttribute{nIdxAttribute,1},xAttribute); % get matching attribute value
    if ~isempty(value) % a value was found
        cSheet(end+1,1:4) = [cAttribute(nIdxAttribute,1:2) {''} {value}]; %#ok<AGROW>
    end
end
return

% =========================================================================

function value = getAttribute(sName,xAttribute)
% GETATTRIBUTE get an attribute value by an attribute name string from a
% Morphix data structure subset attribute part.
%
% Syntax:
%   value = getAttribute(sName,xAttribute)
%
% Inputs:
%        sName - string with attribute name
%   xAttribute - structure with fields: 
%       .name  - cell with strings containing attribute names
%       .value - cell with strings or values containing attribute values
%
% Outputs:
%   value - real or string with attribute value
%
% Example: 
%   value = getAttribute(sName,xAttribute)

nHit = find(ismember(xAttribute.name,sName));
if numel(nHit) > 0
    value = xAttribute.value{nHit(1)};
else
    value = [];
end
return

% =========================================================================

function xAttribute = setAttribute(sName,vValue,xAttribute)
% GETATTRIBUTE set an attribute value by an attribute name string from a
% Morphix data structure subset attribute part.
%
% Syntax:
%   xAttribute = setAttribute(sName,vValue,xAttribute)
%
% Inputs:
%        sName - string with attribute name
%       vValue - string or number with attribute value
%   xAttribute - structure with fields: 
%       .name  - cell with strings containing attribute names
%       .value - cell with strings or values containing attribute values
%
% Outputs:
%   xAttribute - structure with fields: 
%       .name  - cell with strings containing attribute names
%       .value - cell with strings or values containing attribute values
%
% Example: 
%   xAttribute = setAttribute('MessEnde',20150622083634,xAttribute)

nHit = find(ismember(xAttribute.name,sName));
if numel(nHit) > 0
    xAttribute.value{nHit(1)} = vValue;
else
    warning('setAttribute:noAttribute',['Attribute for setting parameter not found in structure: ' sName])
end
return

% =========================================================================

function vNum = datevec2num(vDate)
% DATEVEC2NUM create a number representing a datevector with seconds as the
% base order (format: yyyymmddHHMMSS)
%
% Syntax:
%   vNum = datevec2num(vDate)
%
% Inputs:
%   vDate - vector (nx6) with date vectors [yyyy mm dd HH MM SS]
%
% Outputs:
%   vNum - vector (nx1) with number in format [yyyymmddHHMMSS]
%
% Example: 
%   vNum = datevec2num(vDate)

% vNum = zeros(size(vDate,1),1);
vNum = vDate(:,1) * 1e10;
vNum = vNum + vDate(:,2) * 1e8;
vNum = vNum + vDate(:,3) * 1e6;
vNum = vNum + vDate(:,4) * 1e4;
vNum = vNum + vDate(:,5) * 1e2;
vNum = vNum + vDate(:,6);
return

% =========================================================================

function vDate = addDatevec(vDate1,vDate2)
% ADDDATEVEC adds two date vector notations of [yyyy mm dd HH MM SS].
%
% Syntax:
%   vDate = addDatevec(vDate1,vDate2)
%
% Inputs:
%   vDate1 - vector (1x6) of format [yyyy mm dd HH MM SS]
%   vDate2 - vector (1x6) of format [yyyy mm dd HH MM SS] 
%
% Outputs:
%   vDate - vector (1x1) [yyyy mm dd HH MM SS]
%
% Example: 
%   vDate = addDatevec(vDate1,vDate2)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-06-22

% define maximum entry for datevec (entry 3 for days in month 
vElemMax = [inf 12 30 24 60 60];  

% add date vectors
vDate = vDate1 + vDate2;

% get correct maximum days for month
if vDate(1,2) > 12
    vDate(1,2) = mod(vDate(1,2),12);
    vDate(1,1) = vDate(1,1)+floor(vDate(1,2)./12);
end
vElemMax(3) = eomday(vDate(1,1),vDate(1,2));  

% propagate exceeding values to next vector element
for nIdxElem = numel(vElemMax):-1:2
    if nIdxElem == 3 && any(vDate(:,3))>58
        warning('addDatevec:insecureDayCountPropagation',['The calculation '...
            'of new month from days includes a span of more than one month '...
            '- the day might not be correct due to weak "day per month" '...
            'implemenation, when spanning multiple months.'])
    end
    vDate(:,nIdxElem-1) = vDate(:,nIdxElem-1) + floor(vDate(:,nIdxElem)./vElemMax(nIdxElem));
    vDate(:,nIdxElem) = mod(vDate(:,nIdxElem),vElemMax(nIdxElem));
end
return
