function xXml = dstXmlGetAll(sPath,bFile)
% DSTXMLGETALL get all DIVe XMLs in a folder tree with file path and type.
% Recursive function.
%
% Syntax:
%   xXml = dstXmlGetAll(sPath)
%
% Inputs:
%   sPath - string with path of file system folder tree to search
%   bFile - boolean if path to file is needed - otherwise folder is used
%
% Outputs:
%   xXml - structure with fields: 
%    .sPath - string with XML filepath
%    .sType - string for type of DIVe element (Module, Data, Support)
%
% Example: 
%   xXml = dstXmlGetAll('c:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air')
%   xXml = dstXmlGetAll('c:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air',0)
%   xXml = dstXmlGetAll('c:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air',1)
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\Data')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\Data\air')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\Data\air\ref000p1013T20')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air\std')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air\std\Module')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air\std\Module\airCalc')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air\std\Data')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air\std\Data\initiIO')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\air\std\Data\initiIO\p1013T20h60')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\Support')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\Support\dive_EnvLoadRoad')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\roadair\linc\Support')
%   xXml = dstXmlGetAll('C:\dirsync\08Helix\11d_main\com\DIVe\Content\bdry\env\roadair\linc\Support\roadLib')
% 
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2014-07-15

% initialize output
xXml = struct('sPath',{},'sType',{});

% check input
if nargin < 2
    bFile = false;
end

% check for deep start inside Module, Data or Support folder
cElement = {'Module','Data','Support'};
nLevelExt = [1 2 1];
cPath = pathparts(sPath);
[bElement,nElement] = ismember(cElement,cPath);
nElement = nElement(bElement); % DIVe element index

% check next step 
nDiff = numel(cPath)-nElement;
if isempty(nElement) || nDiff < nLevelExt(bElement)
    cFolder = dirPattern(sPath,'*','folder');
    % proceed to next level
    for nIdxFolder = 1:numel(cFolder)
        xXmlAdd = dstXmlGetAll(fullfile(sPath,cFolder{nIdxFolder}),bFile);
        xXml = structConcat(xXml,xXmlAdd);
    end
    
else % add file entry
   
    % check for deep folder inside DIVe element
    if nDiff > nLevelExt(bElement) 
        % limit folder depth
        cPath = cPath(1:nElement+nLevelExt(bElement));
        sPath = fullfile(cPath{:});
    end
    
    if bFile % add file to path
        sFile = [cPath{end},'.xml'];
        sPath = fullfile(cPath{:},sFile);
        if ~exist(sPath,'file')
            % red error message on commandline without throwing an error
            fprintf(2,'Correct DIVe XML file %s missing in: %s \n',sFile,fileparts(sPath));
            xXml = struct('sPath',{},'sType',{});
            return
        end        
    end
    
    % create output structure
    xXml = struct('sPath',sPath,'sType',cElement(bElement));
end
return


