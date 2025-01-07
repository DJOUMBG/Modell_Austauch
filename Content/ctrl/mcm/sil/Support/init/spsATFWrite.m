function spsATFWrite(xSubset,sPathTarget)
% SPSATFWRITE write an ASAM Transfer Format (ATF) file for import into MVA.
%
% Syntax:
%   spsATFWrite(xSubset,sFileTarget)
%
% Inputs:
%       xSubset - structure with fields of a Morphix subset
%   sFileTarget - string string with target filepath
%
% Example: 
%   spsATFWrite(xSubset,sFileTarget)

disp('Data transfer to ATF for MVA import...')

% determine file name ?? or argument

% correction on Uniread data for MVA
xSubset = spsUnireadMVACorrection(xSubset);

% determine filename
[bTF,nID] = ismember('MessTyp',xSubset.attribute.name); %#ok<ASGLU>
sMesstyp = xSubset.attribute.value{nID};
[bTF,nID] = ismember('MOTID',xSubset.attribute.name); %#ok<ASGLU>
sMOTID = xSubset.attribute.value{nID};
[bTF,nID] = ismember('BRBLMA',xSubset.attribute.name); %#ok<ASGLU>
sBRBLMA = xSubset.attribute.value{nID};
nBRBL = str2double(sBRBLMA);

sFile = sprintf('DMB_%s_%04i_%s.ATF_%s',sMOTID,nBRBL,datestr(now,'yyyymmddHHMMSS'),sMesstyp);
sFileTarget = fullfile(sPathTarget,sFile);

% open ATF File
nFid = fopen(sFileTarget,'w');

% write header
fprintf(nFid,'%s\n','ATF_FILE V1.4;');
fprintf(nFid,'%s\n','//DaimlerTruckAG DIVe Simulation');
fprintf(nFid,'%s\n\n','//rainer.r.frey@daimlertruck.com;christoph.hillenbrand@daimlertruck.com');

% copy instance description section from data model
swaFileContentCopy(nFid,'DataModel.txt')
fprintf(nFid,'\n');

% patch additional constant IDs into Morphix attributes
cConst = {'UmfeldID',1;... 1
          'UsersID',1;... 2
          'VersuchsID',1;... 3
          'U_VersuchsID',1;... 4
          'submatrix',1;... 5
          'MessungsID',1;... 6
          'measurement',1;... 7
          'sequence_representation',0;... 8
          'global_flag',0;... 9
          'UmfeldName','MVA NFZ';... 10
          'UsersName','TPC';... 11
          };
xSubset.attribute.name = [xSubset.attribute.name cConst(:,1)'];
xSubset.attribute.value = [xSubset.attribute.value cConst(:,2)'];

% code shortcut
xAttr = xSubset.attribute;
nValueNum = size(xSubset.data.value,1);

% pre-parse application element definition
xAppl = spsATFDefParse('DataModel.txt');
      
% write instance element section part 1
swaElementWrite(nFid,xAppl,xAttr,'Umfeld');
swaElementWrite(nFid,xAppl,xAttr,'MotId');
swaElementWrite(nFid,xAppl,xAttr,'Versuch');
swaElementWrite(nFid,xAppl,xAttr,'Messung');
swaInstAttributeWrite(nFid,'SubMatrix',[{'Id',1;...
                                        'Name','SM-1';...
                                        'number_of_rows',nValueNum};
                                        cConst(7,:)]);

% copy unit description section (as specified from MVA)
swaFileContentCopy(nFid,'Units.txt')

% pre-parse Quantity definition
xQuant = spsATFDefParse('Quantities.txt');

% determine allowed data channel
[bAllow,nGroesse] = ismember(xSubset.data.name,{xQuant.Groessen.GroNameDef});
% report failures
cFail = xSubset.data.name(~bAllow);
if ~isempty(cFail)
    fprintf(2,['spsWriteATF - the following data channels of passed data ' ...
        'failed during transfer to MVA ATF due to illegal data channel ' ...
        'name for MVA (not in Quantities.txt):\n']);
    for nIdxFail = 1:numel(cFail);
        fprintf(2,'   %s\n',cFail{nIdxFail});
    end
end
% cut data to allowed data channels
xSubset.data.name  = xSubset.data.name(bAllow);
xSubset.data.value = xSubset.data.value(:,bAllow);
nGroesse = nGroesse(bAllow);

% create instance element block "Groessen"
for nIdxChannel = 1:numel(nGroesse)
    swaInstAttributeWrite(nFid,'Groessen',...
        [{'GroID',nIdxChannel;...
          'EinheitsID',xQuant.Groessen(nGroesse(nIdxChannel)).EinheitsID;...
          'GroNameDef',size(xSubset.data.value,1)};
                                        cConst(7,:)]);
end

% determine "time"/ID channel
bHit = strcmp('MessTyp',xSubset.attribute.name);
if sum(bHit) ~= 1
    warning('spsATFWrite:unclearIDchannel',['spsATFWrite found no clear ' ...
          '"MessTyp" attribute within the passed subset attributes!']);
end
sMessTyp = xSubset.attribute.value{find(bHit,1,'first')};
switch sMessTyp
    case 'ZYK' % recorder measurement
        sIdChannel = 'SYSRECZEIT';
    case 'FU' % stationare measurement
        sIdChannel = 'LFNR';
    otherwise
        error('spsATFWrite:unknownMessTyp',['spsATFWrite found unknown ' ...
          '"MessTyp" attribute within the passed subset: %s'], sMessTyp);
end
% ensure ID channel in subset data
bID = strcmp(sIdChannel,xSubset.data.name);
if ~any(bID)
     error('spsATFWrite:IDchannelNotFound',['spsATFWrite could not find the '...
           'independent data channel for this measurement: %s'], sIdChannel);
end
    
% determine data type for values
cType = {1,'DT_STRING';...
         3,'DT_FLOAT';...
         6,'DT_LONG';...
        10,'DT_DATE'};
nDatatype = ones(1,numel(xSubset.data.name)).*3;
bLong = ismember(xSubset.data.name,{'LFNR','MESPKTNR','BRBLNR'});
nDatatype(bLong) = deal(6);

% create instance element block "Messgroesse"
for nIdxChannel = 1:numel(nGroesse)
    swaInstAttributeWrite(nFid,'Messgroesse',...
        {'DatenTyp',nDatatype(nIdxChannel);...
          'MessGroID',nIdxChannel;...
          'MESSGROINDEP',bID(nIdxChannel);...
          'MessGroesse',xSubset.data.name{nIdxChannel};...
          'EinheitsID',xQuant.Groessen(nGroesse(nIdxChannel)).EinheitsID;...
          'GroessenID',nIdxChannel;...
          'MessungsID',1});
end

% write data channels
for nIdxChannel = 1:numel(nGroesse)
    bDatatype = cell2mat(cType(:,1)') == nDatatype(nIdxChannel);
    swaInstMeasWrite(nFid,...
        {'Id',nIdxChannel;...
         'measurement_quantity',nIdxChannel;...
         'Name',xSubset.data.name{nIdxChannel};...
         'submatrix',1;...
         'independent',bID(nIdxChannel);...
         'sequence_representation',0;...
         'global_flag',0;...
         'Datatype',nDatatype(nIdxChannel);...
         'Valuecount',nValueNum},...
         cType{bDatatype,2},...
         xSubset.data.value(:,nIdxChannel));
end

% write end of ATF file
swaElementWrite(nFid,xAppl,xAttr,'Users');
fprintf(nFid,'ATF_END;');
fclose(nFid);

disp('... transfer to ATF finished.')
return

% =========================================================================

function swaFileContentCopy(nFid,sFile)
% SWAFILECOPY copies the (string) content of a file to the file specified
% as open file handle.
%
% Syntax:
%   swaFileCopy(nFid,sFile)
%
% Inputs:
%    nFid - handle of open target file
%   sFile - string with filepath of file to copy into open file handle
%
% Example: 
%   nFid = fopen('testtarget.txt','w');
%   swaFileCopy(nFid,which('strGlue'));
%   fclose(nFid);

% input check
if ~exist(sFile,'file')
    sFileWhich = which(sFile);
    if isempty(sFileWhich)
        error('spsWriteATF:sourceFileNotFound',...
            'spsWriteATF - the specified source file is not available: %s \n',sFile);
    else
        sFile = sFileWhich;
    end
end

% read file by line
nFidDM = fopen(sFile,'r');
if verLessThanMATLAB('8.4.0')
    ccLine = textscan(nFidDM,'%s','delimiter','\n','whitespace','','bufsize',65536); %#ok<BUFSIZE> 
else
    ccLine = textscan(nFidDM,'%s','delimiter','\n','whitespace','');
end
fclose(nFidDM);

% write file content to target file
for nIdxLine = 1:numel(ccLine{1})
    fprintf(nFid,'%s\n',ccLine{1}{nIdxLine});
end
return

% =========================================================================

function swaElementWrite(nFid,xAppl,xAttr,sElem)
% SWAELEMENTWRITE determines automatically the attributes of an application
% element and writes the existing ones into the target file.
%
% Syntax:
%   swaElementWrite(nFid,xAppl,xAttr,sElem)
%
% Inputs:
%    nFid - handle of target file 
%   xAppl - structure with fields of application elements, which contain
%           attribute definition cells (content of DataModel.txt, MVA ATF)
%   xAttr - structure with fields name and value according Morphix structure 
%   sElem - string with element name according MVA ATF Data Model
%
% Outputs:
%
% Example: 
%   swaElementWrite(nFid,xAppl,xAttr,sElem)

% determine allows attributes of element
cAttrAllow = xAppl.(sElem)(:,1);
bAllow = ismember(xAttr.name,cAttrAllow);
cAttr = [xAttr.name(bAllow)',xAttr.value(bAllow)'];

% write element with all allowed and existing attributes
swaInstAttributeWrite(nFid,sElem,cAttr);
return

% =========================================================================

function swaInstAttributeWrite(nFid,sElement,cAttribute)
% SWAINSTATTRIBUTEWRITE write a simple ATF instance element with attributes.
%
% Syntax:
%   swaInstAttributeWrite(nFid,sElement,cAttribute)
%
% Inputs:
%         nFid - handle of open target file
%     sElement - string with instance element to write
%   cAttribute - cell (mx2) with (:,1): attribute name string 
%                                (:,2): attribute value
%
% Example: 
%   swaInstAttributeWrite(nFid,sElement,cAttribute)

fprintf(nFid,'INSTELEM %s\n',sElement);
for nIdxAttr = 1:size(cAttribute,1)
    if ischar(cAttribute{nIdxAttr,2})
        fprintf(nFid,'    %s = "%s";\n',cAttribute{nIdxAttr,1},cAttribute{nIdxAttr,2});
    else
        fprintf(nFid,'    %s = %g;\n',cAttribute{nIdxAttr,1},cAttribute{nIdxAttr,2});
    end
end
fprintf(nFid,'ENDINSTELEM;\n\n');
return

% =========================================================================

function swaInstMeasWrite(nFid,cAttribute,sDatatype,vValue)
% SWAINSTMEASWRITE write an ATF instance element of type "LocalColumn"
% including data block.
%
% Syntax:
%   swaInstMeasWrite(nFid,cAttribute,vValue)
%
% Inputs:
%         nFid - handle of open target file
%   cAttribute - cell (mx2) with (:,1): attribute name string 
%                                (:,2): attribute value 
%    sDatatype - string with data type (DT_STRING,DT_FLOAT,DT_LONG,DT_DATE)
%       vValue - vector (1xn) with values of this data channel
%
% Example: 
%   swaInstMeasWrite(1,{'bla','blub'},'DT_FLOAT',4:2:80)

% print entry
fprintf(nFid,'INSTELEM LocalColumn\n');
% attribute part 
for nIdxAttr = 1:size(cAttribute,1)
    if ischar(cAttribute{nIdxAttr,2})
        fprintf(nFid,'    %s = "%s";\n',cAttribute{nIdxAttr,1},cAttribute{nIdxAttr,2});
    else
        fprintf(nFid,'    %s = %g;\n',cAttribute{nIdxAttr,1},cAttribute{nIdxAttr,2});
    end
end
% data part
fprintf(nFid,'    Values = DATATYPE %s,\n',sDatatype);
if length(vValue)>1
	fprintf(nFid,'        %g,\n',vValue(1:end-1));
end
fprintf(nFid,'        %g;\n',vValue(end));
fprintf(nFid,'ENDINSTELEM;\n\n');
return

