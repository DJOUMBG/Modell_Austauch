function dstXmlUpdate(sPath,cExpression)
% DSTXMLUPDATE update all DIVe XMLs in the subfolders of a specified path.
% CAUTION: initIO.std files are recreated.
%
% Syntax:
%   dstXmlUpdate(sPath)
%   dstXmlUpdate(sPath,cExpression)
%
% Inputs:
%   sPath - string 
%   cExpression - cell (mx2) for file attribute determination with
%                   (:,1): string with attribute name
%                   (:,2): string with regular expression to determine
%                          files with attribute value = true
%
% Outputs:
%
% Example: 
%   dstXmlUpdate('C:\dirsync\06DIVe\90SysDM\03Migrate\02Export\phys\eng\detail')
%   dstXmlUpdate(pwd,{'isMain','(\.mdl)$|(\.slx)$';'isStandard','\.m$';'executeAtInit','';'copyToRunDirectory',''})
%
% See also: dstXmlDataSet, dstXmlGetAll, dstXmlModule, dstXmlSupportSet
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-08-25

tic

% check input
if nargin < 2
    cExpression = {'',''};
end

% find all DIVe XMLs in specified file tree
xXml = dstXmlGetAll(sPath,false);
disp(['dstXmlUpdate found ' num2str(numel(xXml)) ' for update.']);

% first update dataset and support set XMLs
for nIdxFile = 1:numel(xXml)
    if strcmp(xXml(nIdxFile).sType,'Data')
        disp(['Recreate XML for ' xXml(nIdxFile).sPath]);
        dstXmlDataSet(xXml(nIdxFile).sPath,cExpression);
    elseif strcmp(xXml(nIdxFile).sType,'Support')
        disp(['Recreate XML for ' xXml(nIdxFile).sPath]);
        dstXmlSupportSet(xXml(nIdxFile).sPath,cExpression);
    end
end

% update module XMLs
for nIdxFile = 1:numel(xXml)
    if strcmp(xXml(nIdxFile).sType,'Module')
        disp(['Recreate XML for ' xXml(nIdxFile).sPath]);
        dstXmlModule(xXml(nIdxFile).sPath,false,cExpression);
    end
end

toc
return
