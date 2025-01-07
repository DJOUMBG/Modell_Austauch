function sInitIOReference = dstInitIOVariantsCreate(cModulePath,xPort,xSource,nInport,nOutport,cExpression)
% DSTINITIOVARIANTSCREATE This function creates initIO dataset files for
% those variants which are user specifies. It returns initIO dataset
% reference which will be used in generation of module XML
%	
% Syntax:
%   dstInitIOVariantsCreate(cModulePath,xPort,xSource,nInport,nOutport,cExpression)
%
% Inputs:
%   cModulePath - cell with string components of basic module path 
%         xPort - structure with fields: 
%          .name    - string with portname
%          .unit    - string with unit
%          .initial - string with initial value of port
%       xSource - structure which is obtained after reading DIVe Signal list: 
%       nInport - integer (1xm) with index of ports in xPort
%      nOutport - integer (1xn) with index of ports in xPort
%   cExpression - cell (mx2) for file attribute determination with
%                   (:,1): string with attribute name; 
%                          'initIO' -> regexp for initIO creation selection
%                          'initIOReference' -> regexp for reference dataset 
%                   (:,2): string with regular expression to determine
%                          files with attribute value = true
%
% Outputs:
%   sInitIOReference - string which has reference initIO dataset's name
% 
% Example: 
%   sInitIOReference = dstInitIOVariantsCreate(sModulePath,xPort,nInport,nOutport,cExpression)

% init output
sInitIOReference = '';

%initialize variables
cVariantSelect = {};
cVariantSignal = ['std' 'sna' xSource.subset(1).field(1,27:end)];

% pathes and folders
sPathInitIO = fullfile(cModulePath{1:end-2},'Data','initIO');
if exist(sPathInitIO,'dir')
    cVariantExist = dirPattern(sPathInitIO,'*','folder');
else
    cVariantExist = {};
end

%% initIO create selection
bInitIO = strcmp('initIO',cExpression(:,1)); % check for a regular expression for initIO
if any(bInitIO)
    % silent mode without user interaction for initIO variant create selection 
    %resolve regular expression pattern to be used
    sRegExp = strtrim(cExpression{bInitIO,2});
    
    % limit initIO variants to the ones defined by regular expression
    bRegVariant = ~cellfun(@isempty,regexp(cVariantSignal,sRegExp,'once'));
    cVariantSelect = cVariantSignal(bRegVariant);
    
    if isempty(cVariantSelect) && isempty(cVariantExist)
        fprintf(2,['Error - dstInitIOVariantsCreate: neither initIO dataset ' ...
            'variant created nor existing variant in silent mode for "%s"\n'],sPathInitIO);
        return
    end
else
    % interactive mode for dataset variant creation
    % list dialogue for user selection
    nSelectionRef = listdlg('InitialValue',1:numel(cVariantSignal),... %choose all variants as default
        'SelectionMode','multiple',...
        'ListString',cVariantSignal,...
        'ListSize',[300 400],...
        'PromptString','Select initIO dataset variants to be created',...
        'Name','create initIO dataset variants'); 
    
    if isempty(nSelectionRef) % cancel in initIO dataset selection
        if isempty(cVariantExist)
            % no previous initIO data variants
            fprintf(2,['Error - dstInitIOVariantsCreate: neither initIO dataset ' ...
                'variant created nor existing variant in interactive mode for "%s"\n'],sPathInitIO);
            return
        end
    else % use selected variants
        cVariantSelect = cVariantSignal(nSelectionRef);
    end
end % if silent mode = regexp exists for initIO create

%% reference dataset selection
cVariantAll = [cVariantExist cVariantSelect];

% determine reference dataset from existing variant XML
if ~isempty(cVariantExist)
    % get reference from first initIO datset variant
    sInitIOReference = getDataSetReference(sPathInitIO);
    
    if ~isempty(sInitIOReference) 
        if ismember(sInitIOReference,cVariantAll)
            fprintf(1,['Remark: initIO dataset reference "%s" for "%s" was ' ...
                'determined by existing datasets\n'],sInitIOReference,sPathInitIO);
        else
            
        end
    end
end % existing previous initIO 

% determine reference dataset from regular expression
bRegexpRef = strcmp('initIOReference',cExpression(:,1)); % check for a regular expression for initIO
if isempty(sInitIOReference) && any(bRegexpRef)
    %resolve regular expression pattern to be used
    sRegExp = strtrim(cExpression{bRegexpRef,2});
    
    % get initIO reference variant by regular expression
    bRef = ~cellfun(@isempty,regexp(cVariantAll,sRegExp,'once'));
    cVariantReference = cVariantAll(bRef);
    switch numel(cVariantReference)
        case 0
            % no hit by regular expression
            fprintf(2,['Error - dstInitIOVariantsCreate: reference dataset ' ...
                'determination by regular expression "%s" failed for "%s" - ' ...
                'issuing interactive mode\n'],sRegExp,sPathInitIO);
            
        case 1
            % one match by regular expression
            sInitIOReference = cVariantReference{1};
            fprintf(1,['Remark: initIO dataset reference "%s" for "%s" was ' ...
                'determined by regular expression\n'],sInitIOReference,sPathInitIO);
            
        otherwise
            % multiple hits by regular expression
            fprintf(2,['Error - dstInitIOVariantsCreate: multiple reference ' ...
                'datasets determinated (%s) by regular expression "%s" for "%s" ' ...
                '- issuing interactive mode\n'],strGlue(cVariantReference,','),...
                sRegExp,sPathInitIO);
            
    end
end % determine reference dataset from regular expression

% determine reference dataset by single entity
if isempty(sInitIOReference) && numel(cVariantSelect)==1
    sInitIOReference = cVariantSelect{1};
end

% determine reference dataset interactively
if isempty(sInitIOReference)
    nReference = listdlg('InitialValue',1,...
        'SelectionMode','single',...
        'ListString',cVariantSelect,...
        'ListSize',[300 400],...
        'PromptString','Select the reference initIO dataSet variant',...
        'Name','Reference initIO dataset selection');
    if isempty(nReference)
        fprintf(2,['Error - dstInitIOVariantsCreate: User canceled reference ' ...
            'dataset selection for "%s". No initIO dataset variants created!\n'],sPathInitIO);
        return
    else
        sInitIOReference = cVariantSelect{nReference};
    end
end

%% create datasets
% delete datasets, which are re-created
% Remark: description was not maintained in old initIO creation
for nIdxVar = 1:numel(cVariantSelect)
    sPathRemove = fullfile(sPathInitIO,cVariantSelect{nIdxVar});
    if exist(sPathRemove,'dir')
        rmdir(sPathRemove,'s');
    end
end

% resort datasets to be (re-)created to generate reference dataset first
bReference = strcmp(sInitIOReference,cVariantSelect);
if any(bReference)
    cVariantSelect = [cVariantSelect(bReference) cVariantSelect(~bReference)];
end

% loop over initIO dataset variant to be created
xInvalidPort = struct; % init error structure
for nInitIdx = 1:numel(cVariantSelect)
    % create initIO dataset
	[cErrInForEachVar,cErrOutForEachVar] = dstInitIOCreate(cModulePath,xPort,...
                                    nInport,nOutport,cVariantSelect{nInitIdx});
    % capture invalid port information in a strucure
    if ~isempty(cErrInForEachVar)
        xInvalidPort.(cVariantSelect{nInitIdx}).ErrInports = cErrInForEachVar;
        fprintf(2,'\t<a href="matlab:openvar(''xInvalidPort.%s.ErrInports'')">%s</a>\n',...
            cVariantSelect{nInitIdx},'Click here for list of Inports with invalid values');
    end
    if ~isempty(cErrOutForEachVar)
        xInvalidPort.(cVariantSelect{nInitIdx}).ErrOutports = cErrOutForEachVar;
        fprintf(2,'\t<a href="matlab:openvar(''xInvalidPort.%s.ErrOutports'')">%s</a>\n',...
            cVariantSelect{nInitIdx},'Click here for list of Outports with invalid values');
    end
end
if ~isempty(fieldnames(xInvalidPort))
    assignin('base','xInvalidPort',xInvalidPort);
end

% state not re-created datasets
bNoCreate = ~ismember(cVariantExist,cVariantSelect);
cVariantNoCreate = cVariantExist(bNoCreate);
if ~isempty(cVariantNoCreate)
    fprintf(1,'Remark: The following initIO dataset variants have not been recreated\n');
    for nIdxVar = 1:numel(cVariantNoCreate)
        sPathVariant = fullfile(sPathInitIO,cVariantNoCreate{nIdxVar});
        fprintf(1,'    <a href="matlab:winopen(''%s'')">%s</a>\n',sPathVariant,sPathVariant);
    end
    fprintf(1,'  Please check port values and reference dataset for consistency.\n');
end
return

% =========================================================================

function [cErrInport,cErrOutport] = dstInitIOCreate(cModulePath,xPort,nInport,nOutport,sInitIOVarName)
% DSTOTHERINITIOCREATE creates initIO_in.m and initIO_out.m files  for any 
% initIO data variant
%	
% Syntax:
%   dstInitIOCreate(sModulePath,xPort,nInport,nOutport,sSpecVersion)
%
% Inputs:
%   cModulePath - cell with string components of basic module path 
%         xPort - structure with fields: 
%          .name    - string with portname
%          .unit    - string with unit
%          .initial - string with initial value of port
%       nInport - integer (1x1) 
%      nOutport - integer (1x1) 
%  sSpecVersion - string with current DIVe spec version implemented for XML
%                 creation
% sInitIOVarName - initIO data variant name.
% sInitIOReference - string with initIO dataset reference name like 'std'
%
% Outputs:
%   cErrInport- A cell containing in-ports that are not valid
%   cErrInport- A cell containing out-ports that are not valid
%
% Example: 
%   dstInitIOCreate(sModulePath,xPort,nInport,nOutport,sSpecVersion)

% adapt port value field/column
if strcmp(sInitIOVarName,'std')
    sXlsInitColName = 'initial';
else
    sXlsInitColName = sInitIOVarName;
end

% create folder
sPathVariant = fullfile(cModulePath{1:end-2},'Data','initIO',sInitIOVarName);
if exist(fileparts(sPathVariant),'dir') ~= 7
    mkdir(fileparts(sPathVariant));
end
if exist(sPathVariant,'dir') ~= 7
    mkdir(sPathVariant);
end

% create initIO_in.m
sFileInPath = fullfile(sPathVariant,'initIO_in.m');
[bSuccesInPort cErrInport] = dstInitIOFileWrite(sFileInPath,nInport,xPort,sXlsInitColName,'Inport');
% create initIO_out.m
sFileOutPath = fullfile(sPathVariant,'initIO_out.m');
[bSuccesOutPort cErrOutport] = dstInitIOFileWrite(sFileOutPath,nOutport,xPort,sXlsInitColName,'Outport');
% report errors and warning to users
if ~bSuccesInPort || ~bSuccesOutPort
    if strcmp(sXlsInitColName,'initial')
        fprintf(2,'Error: Variant "%s" failed because of invalid/empty values in DIVe_Signals.xlsx(Column:"%s")\n',...
            sInitIOVarName,sXlsInitColName);
    else
        fprintf(2,'Warning: Variant "%s" failed because of invalid/empty values in DIVe_Signals.xlsx(Column:"%s")\n',...
            sInitIOVarName,sXlsInitColName);
    end
end
if ~bSuccesInPort || ~bSuccesOutPort
    % try to cleanup created folder and content
    try  
        if exist(sPathVariant,'dir') == 7
            rmdir(sPathVariant,'s');
        end
    catch ME
        fprintf(2,['Error - dstInitIOVariantsCreate:dstInitIOCreate: Unable ' ...
            'to delete directory "%s" with message:\   %s\n'],sPathVariant,ME.message);
    end
end

%Create DataSet XMLs only if valid values exist for ports
if bSuccesInPort && bSuccesOutPort
    dstXmlDataSet(sPathVariant,{'isStandard','\.m$';'executeAtInit','';'copyToRunDirectory',''});
end
return

% =========================================================================

function [outstring]=fprintfStringCorrection(instring)
% fprintfStringCorrection - modifies strings to be printed correctly with
% fprintf function
% e. g. percent '%' >> '%%' 
outstring = regexprep(instring, ...
                            {'%'},...
                            {'%%'});
return

% =========================================================================

function sReference = getDataSetReference(sPath)
% GETDATASETREFERENCE get the reference dataset of the specifed DIVe
% dataset class path on the file system.
%
% Syntax:
%   sReference = getDataSetReference(sPath)
%
% Inputs:
%   sPath - char (1xn) with path of a DIVe dataset class
%
% Outputs:
%   sReference - char (1xn) reference dataset variant of this dataset class
%
% Example: 
%   sReference = getDataSetReference(sPath)

% init output
sReference = '';

% determine available variants
cVariant = dirPattern(sPath,'*','folder');
if isempty(cVariant)
    return
end

% read XML file (header only)
sFileXML = fullfile(sPath,cVariant{1},[cVariant{1} '.xml']);
if exist(sFileXML,'file')
    xData = dsxReadCfgHeader(sFileXML);
    
    if isfield(xData,'DataSet') && isfield(xData.DataSet,'reference')
        sReference = xData.DataSet.reference;
    else
        fprintf(2,['Error - dstInitIOVariantsCreate:getDataSetReference: ' ...
            'encountered invalid XML content in file "%s"\n'],sFileXML);
    end
end
return

% =========================================================================

function [bSuccess,cErrPorts] = dstInitIOFileWrite(sFilePath,nPort,xPort,sInitIOVarName,sPortType)
% DSTINITIOFILEWRITE This function writes initIO files
% 
% Syntax:
%       dstInitIOFileWrite(sFileInPath,nInport,xPort,sInitIOVarName,sPortType);
%
% Inputs:
%   sFilePath - string path of initIO file 
%   nPort - integer (1xn) with number of ports in xPort
%   xPort - structure with fields: 
%      .name    - string with portname
%       .unit    - string with unit
%      .initial - string with initial value of port
%  sInitIOVarName - String which mentions initIO variant name 
%  sPortType - String which mentions port type (Inport/Outport)
%
% Outputs:
%   bSuccess - boolean which mentions
%             true : If all ports have valid values in Signal List
%             fasle : If any one of the ports have invalid values
%   cErrPorts - cell array containing all port names with invalid values
% Example: 
%   dstInitIOFileWrite(sFileInPath,nInport,xPort,sInitIOVarName,'Inport');
%   dstInitIOFileWrite(sFileInPath,nInport,xPort,sInitIOVarName,'Outport');

cErrPorts = {};
bSuccess = true;
hFileInit = fopen(sFilePath,'w');
if strcmp(sPortType,'Inport')
    fprintf(hFileInit,'%s\r\n',fprintfStringCorrection('% Inports:'));
else
    fprintf(hFileInit,'%s\r\n',fprintfStringCorrection('% Outports:'));
end
% loop over ports
for nIdxPort = 1:numel(nPort)
    sPortValue = xPort(nPort(nIdxPort)).(sInitIOVarName);
    % check specified init value
    if isempty(sPortValue) % specified init value is missing
        
        % check port's sna value as fallback, if not a control signal
        if strcmp(sInitIOVarName,'sna') && ~strcmpi('control',xPort(nPort(nIdxPort)).type)
            % check port's initial value as fallback
            sPortSnaValue = xPort(nPort(nIdxPort)).initial;
            
            if isempty(sPortSnaValue)
                % fallback failure - state error
                cErrPorts = [cErrPorts xPort(nPort(nIdxPort)).name]; %#ok<AGROW>
                bSuccess = false;
            else
                % write sna value to file
                dstInitIOFileWriteValue(hFileInit, xPort(nPort(nIdxPort)), sPortSnaValue)
            end
        else
            % fallback failure - state error (no specified value and no sna or control signal)
            cErrPorts = [cErrPorts xPort(nPort(nIdxPort)).name]; %#ok<AGROW>
            bSuccess = false;
        end
    else
        % write specified init value to file
        dstInitIOFileWriteValue(hFileInit, xPort(nPort(nIdxPort)), sPortValue)
    end
end
fclose(hFileInit);
return

% =========================================================================

function [] = dstInitIOFileWriteValue (hFile, xPort, sValue)
% DSTINITIOFILEWRITEVALUE 
%
% Syntax:
%   dstInitIOFileWriteValue (hFile,xPort,sValue)
%
% Inputs:
%    hFile - handle (1x1) of file
%    xPort - structure with fields of port information 
%       .name - string with port name
%       .unit - string with unit of port
%       .minAbsoluteRange - string with minimum absolute value of port
%       .maxAbsoluteRange - string with maximum absolute value of port
%   sValue - string with value of initial value
%
% Example: 
%   dstInitIOFileWriteValue (1,xPort,'42')

% build comment
sCommentUnit = ' % ';
sCommentPhys = '';
sCommentAbs = '';
if ~isempty(xPort.unit)
    sCommentUnit = sprintf(' %% [%s]',xPort.unit);
end
if ~isempty(xPort.minPhysicalRange) && ~isempty(xPort.maxPhysicalRange)
    sCommentPhys = sprintf(', phys: %s..%s',xPort.minPhysicalRange,xPort.maxPhysicalRange);
end
if ~isempty(xPort.minAbsoluteRange) && ~isempty(xPort.maxAbsoluteRange)
    sCommentAbs = sprintf(', abs: %s..%s',xPort.minAbsoluteRange,xPort.maxAbsoluteRange);
end
sComment = [sCommentUnit sCommentPhys sCommentAbs];

% write init value to file
fprintf(hFile,'%s = %s;%s\r\n', xPort.name, sValue, sComment);
return

