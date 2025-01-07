function dmdLoadData(sFileXml)
% DMDLOADDATA  load data of specified DIVe module description file
%
% Syntax:
%   dmdLoadData
%   dmdLoadData(sFileXml)
%
% Inputs:
%   sFileXml - string with path of DIVe module documentation XML file
%
% Outputs:
%
% Example: 
%   dmdLoadData(sFileXml)
%   dmdLoadData('C:\dirsync\06DIVe\01Content\phys\eng\simple\transient\std\std.xml')
%
% See also: dpsLoadStandard, dsxRead, fullfileSL, pathparts, structUnify
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-10-22

% input check
if nargin == 0
    [sFileXmlName,sFileXmlPath] = uigetfile( ...
        {'*.xml','DIVe Module Description (xml)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open Module Description (*.xml)',...
        'MultiSelect','off');
    if isequal(sFileXmlName,0) % user chosed cancel in file selection popup
        return
    else
        sFileXml = fullfile(sFileXmlPath,sFileXmlName);
    end
else
    if ~exist(sFileXml,'file')
        error('buildDIVeSfcn:fileNotFound',['The specified file does not exist: ' sFileXml])
    end
end

% load module XML description
cPathXml = pathparts(sFileXml);
xTree = dsxRead(sFileXml);

% load parameters from all data files
cLevel = {'species','family','type'};
xData = struct;
for nIdxDataSet = 1:numel(xTree.Module.Interface.DataSet)
    % determine location of data set
    [bTF,nLevel] = ismember(xTree.Module.Interface.DataSet(nIdxDataSet).level,cLevel); %#ok<ASGLU>
    sFileXmlData = fullfile(cPathXml{1:end-6+nLevel},'Data',...
                            xTree.Module.Interface.DataSet(nIdxDataSet).classType,...
                            xTree.Module.Interface.DataSet(nIdxDataSet).reference,...
                            [xTree.Module.Interface.DataSet(nIdxDataSet).reference,'.xml']);
    
    % load data
    xDataAdd = dpsLoadStandard(sFileXmlData);
    xData = structUnify(xData,xDataAdd);
end
if isfield(xTree.Module.Interface,'DataSetInitIO')
    % load initIO data
    sFileXmlData = fullfile(cPathXml{1:end-3},'Data',...
    xTree.Module.Interface.DataSetInitIO.classType,...
    xTree.Module.Interface.DataSetInitIO.reference,...
    [xTree.Module.Interface.DataSetInitIO.reference,'.xml']);
    % load data
    xDataAdd = dpsLoadStandard(sFileXmlData);
    xData = structUnify(xData,xDataAdd);
end


% create dataset
sMP.(xTree.Module.context).(xTree.Module.species) = xData;
assignin('base','sMP',sMP);
return
