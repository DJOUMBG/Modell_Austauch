function dstXmlDataSet(sPath,cExpression)
% DSTXMLDATASET create a DIVe DataSet variant XML description file. DataSet
% variant XML files include a listing of all files in the same directory
% including certain DIVe execution attributes (for details see DIVe
% Specification).
% 
% Extended functionality:
% - other DataSet variant XML files of the same DataSet classType are 
%   searched in alphabetical order to determine the reference DataSet
%   variant 
% - if no other DataSet variant XML is found the actual DataSet variant
%   becomes the reference DataSet variant
% - if DataSet variant XML exists already, the description is maintained
% - if DataSet variant XML exists already and DataFiles have the same name,
%   the file attributes are maintained
% - if another DataSet variant XML exists and DataFiles have the same name,
%   the file attributes are overtaken
% - Silent interface - specify with cExpression regular expressions to
%   determine, which files get which attribute
% 
% Part of "DIVe Simulink Transfer Package" (dst).
%
% Syntax:
%   dstXmlDataSet(sPath)
%   dstXmlDataSet(sPath,cExpression)
%
% Inputs:
%   sPath - string with path to folder with files, which define one dataset
%   cExpression - cell (mx2) for file attribute determination with
%                   (:,1): string with attribute name
%                   (:,2): string with regular expression to determine
%                          files with attribute value = true
%
% Outputs:
%
% Example: 
%   dstXmlDataSet(pwd)
%   dstXmlDataSet(pwd,{'isStandard','\.m$';'executeAtInit','';'copyToRunDirectory',''})
%
% See also: dirPattern, dstFileTagCreate, dsxRead, dsxWrite, pathparts, dstXmlUpdate
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-08-20

% specification version definition
sSpec = '1.0.0';

% check input arguments
if nargin < 1
    sPath = pwd;
end
if nargin < 2
    cExpression = {'',''};
end

% decompose path
cPath = pathparts(sPath);

% check if DataSet classType folder was selected --> run dstXmlUpdate
if strcmp(cPath{end-1}, 'Data')
    dstXmlUpdate(sPath,cExpression);
    return
end

% get old XML information for conservation of parameter info
bXmlOrg = false;
cFileXml = dirPattern(sPath,{[cPath{end},'.xml']},'file');
if ~isempty(cFileXml)
    xTreeOrg = dsxRead(fullfile(sPath,cFileXml{1}));
    if ~isempty(xTreeOrg)
        bXmlOrg = true;
    end
end

% find context level (ctrl,phys)
bContext = ismember(cPath,{'phys','ctrl','bdry','human','pltm'});
if any(bContext)
    nContext = numel(bContext) - find(bContext);
end

%% determine path/classification info
bData = strcmp('Data',cPath);
% ensure correct input path level (must be DataSet Variant path, not class)
if find(bData) ~= numel(cPath)-2
    fprintf(2,['DataSet XML generation aborted as specified path is not a ' ...
               'DataSet Variant path:\n%s\n'],sPath);
    return
end
cLevel = {'species','family','type'};
nLevel = find(bData) - 1 - (numel(cPath)-nContext);
sLevel = cLevel{nLevel};
for nIdxLevel = 1:numel(cLevel)
    if nLevel >= nIdxLevel
        xLH.(cLevel{nIdxLevel}) = cPath{end-nContext+nIdxLevel};
    else
        xLH.(cLevel{nIdxLevel}) = '';
    end
end
sContext = cPath{end-nContext};
sClassType = cPath{end-1};
sInstance = cPath{end};

%% determine reference dataset by searching other dataset XMLs
bXml = false;
sReference = sInstance; % self reference if no other DataSet instance available
cClassInstance = dirPattern(fullfile(cPath{1:end-1}),'*','folder'); % get other instances
for nIdxInstance = 1:numel(cClassInstance)
    sPathXmlRef = fullfile(cPath{1:end-1},cClassInstance{nIdxInstance},[cClassInstance{nIdxInstance} '.xml']);
    if exist(sPathXmlRef,'file') % if xml exists
        % get reference dataset from xml
        xRef = dsxRead(sPathXmlRef);
        sReference = xRef.DataSet.reference;
        bXml = true;
        break
    end
end

%% Create basic XML structure
% xTree.DataSet.xmlns = 'DIVeData.xsd';
xTree.DataSet.xmlns = 'http://www.daimler.com/DIVeData';
xTree.DataSet.xmlns0x3Axsi = 'http://www.w3.org/2001/XMLSchema-instance';
xTree.DataSet.xsi0x3AschemaLocation = ['\\emea.corpdir.net\E019\prj\TG\DIVE\100_doc\110_specification\DIVe_v'...
                                       strrep(sSpec,'.','') '\XMLSchemes\DIVeData.xsd'];
xTree.DataSet.classType = sClassType;
xTree.DataSet.reference = sReference;
xTree.DataSet.name = sInstance;
xTree.DataSet.type = xLH.type;
xTree.DataSet.family = xLH.family;
xTree.DataSet.species = xLH.species;
xTree.DataSet.context = sContext;
xTree.DataSet.level = sLevel;
xTree.DataSet.specificationVersion = sSpec;
xTree.DataSet.dataSetVersion = '1';
xTree.DataSet.description = '';
    
% Add files to XML structure
if bXmlOrg % previous XML existed
    xTree.DataSet.DataFile = dstFileTagCreate(sPath,{'isStandard','executeAtInit','copyToRunDirectory'},xTreeOrg.DataSet.DataFile,cExpression);
    if isfield(xTreeOrg.DataSet,'description')
        xTree.DataSet.description = xTreeOrg.DataSet.description;
    end
elseif bXml % reference XML existed
    xTree.DataSet.DataFile = dstFileTagCreate(sPath,{'isStandard','executeAtInit','copyToRunDirectory'},xRef.DataSet.DataFile,cExpression);
    disp(['<a href="matlab:open(''' fullfile(sPath,[sInstance '.xml']) ''')">Add comment to DataSet XML file ' [sInstance '.xml'] '</a>']);
else % ask user
    xTree.DataSet.DataFile = dstFileTagCreate(sPath,{'isStandard','executeAtInit','copyToRunDirectory'},struct(),cExpression); 
    disp(['<a href="matlab:open(''' fullfile(sPath,[sInstance '.xml']) ''')">Add comment to DataSet XML file ' [sInstance '.xml'] '</a>']);
end

%% Write XML file
dsxWrite(fullfile(sPath,[sInstance '.xml']),xTree);
return
