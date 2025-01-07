function xData = dpsLoadStandard(sFileXml,xTree)
% DPSLOADSTANDARD load all files of a DIVe standard data set and return the
% parameters in a structure. 
% Part of the DIVe platform standard package (dps).
%
% Syntax:
%   xData = dpsLoadStandard(sFileXml)
%   xData = dpsLoadStandard(sFileXml,xTree)
%
% Inputs:
%   sFileXml - string with file or filepath of data set XML description 
%      xTree - structure with XML file content 
%
% Outputs:
%   xData - structure with fields of singular parameters in data file 
%
% Example: 
%   xData = dpsLoadStandard('OM471EU6.xml')
%
% See also: dsxread, structUnify, dpsLoadStandardFile
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-10-24

% check input
if ~exist(sFileXml,'file')
    error('dpsLoadStandard:fileNotFound','The specified file does not exist: %s',sFileXml);
end
if nargin < 2
    % read data set description
    xTree = dsxRead(sFileXml);
end

% get file path
sPath = fileparts(sFileXml);

% read parameters from data files
xData = struct;
for nIdxFile = 1:numel(xTree.DataSet.DataFile)
    if strcmp(xTree.DataSet.DataFile(nIdxFile).isStandard,'1')
        xDataAdd = dpsLoadStandardFile(fullfile(sPath,xTree.DataSet.DataFile(nIdxFile).name));
        % special structure for initIO data of in- and outports
        if strcmp(xTree.DataSet.classType,'initIO')
            xDataInit = xDataAdd;
            clear xDataAdd
            if strcmpi(xTree.DataSet.DataFile(nIdxFile).name,'initIO_in.m')
                xDataAdd.in = xDataInit;
            elseif strcmpi(xTree.DataSet.DataFile(nIdxFile).name,'initIO_out.m')
                xDataAdd.out = xDataInit;
            end
        end
        % combine data of files
        xData = structUnify(xData,xDataAdd); 
    end
end
return