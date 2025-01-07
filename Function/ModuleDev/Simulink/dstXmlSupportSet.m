function dstXmlSupportSet(sPath,cExpression)
% DSTXMLSUPPORTSET create a DIVe compliant support set XML.
% Create a support set XML description file, which includes all files of
% the specified directory. Part of "DIVe Simulink Transfer Package" (dst).
%
% Syntax:
%   dstXmlSupportSet(sPath)
%   dstXmlSupportSet(sPath,cExpression)
%
% Inputs:
%   sPath - string with path to folder with files, which define one support
%           set
%   cExpression - cell (mx2) for file attribute determination with
%                   (:,1): string with attribute name
%                   (:,2): string with regular expression to determine
%                          files with attribute value = true
%
% Outputs:
%
% Example: 
%   dstXmlSupportSet(pwd)
%   dstXmlSupportSet(pwd,{'executeAtInit','init.*m$';'copyToRunDirectory',''})
%
% See also: dirPattern, dstFileTagCreate, dsxWrite, pathparts
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
if ~exist(sPath,'dir')
    fprintf(2,'dstXmlSupportSet specified path does not exist:\n%s\n',sPath);
end

% decompose path
cPath = pathparts(sPath); 

% find context level (ctrl,phys)
bContext = ismember(cPath,{'phys','ctrl','bdry','human','pltm'});
if any(bContext)
    nContext = numel(bContext) - find(bContext);
end

% determine path/classification info
bSupport = strcmp('Support',cPath);
% ensure correct input path level (must be DataSet Variant path, not class)
if find(bSupport) ~= numel(cPath)-1
    fprintf(2,['SupportSet XML generation aborted as specified path is not a ' ...
               'SupportSet path:\n%s\n'],sPath);
    return
end
cLevel = {'species','family','type'};
nLevel = find(bSupport) - 1 - (numel(cPath)-nContext);
sLevel = cLevel{nLevel};
for nIdxLevel = 1:numel(cLevel)
    if nLevel >= nIdxLevel
        xLH.(cLevel{nIdxLevel}) = cPath{end-nContext+nIdxLevel};
    else
        xLH.(cLevel{nIdxLevel}) = '';
    end
end
sContext = cPath{end-nContext};
sInstance = cPath{end};

% try to retrieve previous XML
sPathXml = fullfile(sPath,[sInstance '.xml']);
if exist(sPathXml,'file')
    xTreeOrg = dsxRead(sPathXml);
end

% Create basic XML structure
% xSupport.SupportSet.xmlns = 'DIVeSupportSet.xsd';
xSupport.SupportSet.xmlns = 'http://www.daimler.com/DIVeSupport';
xSupport.SupportSet.xmlns0x3Axsi = 'http://www.w3.org/2001/XMLSchema-instance';
xSupport.SupportSet.xsi0x3AschemaLocation = ['\\emea.corpdir.net\E019\prj\TG\DIVE\100_doc\110_specification\DIVe_v'...
                                             strrep(sSpec,'.','') '\XMLSchemes\DIVeSupport.xsd'];
xSupport.SupportSet.name = sInstance;
xSupport.SupportSet.type = xLH.type;
xSupport.SupportSet.family = xLH.family;
xSupport.SupportSet.species = xLH.species;
xSupport.SupportSet.context = sContext;
xSupport.SupportSet.level = sLevel;
xSupport.SupportSet.specificationVersion = sSpec;
xSupport.SupportSet.supportSetVersion = '1';
xSupport.SupportSet.description = '';

% retain previous XML description
if exist('xTreeOrg','var') && isfield(xTreeOrg,'SupportSet') && ~isempty(xTreeOrg)
    xSupport.SupportSet.description = xTreeOrg.SupportSet.description;
end

% Add files to XML structure
if exist('xTreeOrg','var') && isfield(xTreeOrg,'SupportSet') && ~isempty(xTreeOrg)
    xSupport.SupportSet.SupportFile = dstFileTagCreate(sPath,...
        {'executeAtInit','copyToRunDirectory'},xTreeOrg.SupportSet.SupportFile,...
        cExpression);
else
    xSupport.SupportSet.SupportFile = dstFileTagCreate(sPath,...
        {'executeAtInit','copyToRunDirectory'},struct(),cExpression);    
end

% Write XML file
dsxWrite(fullfile(sPath,[sInstance '.xml']),xSupport);
return
