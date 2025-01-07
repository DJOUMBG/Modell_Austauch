function sRoot = hlxPrintConfig(cDepotFile,nLevel,sPath)
% HLXPRINTCONFIG get Configuration and referenced files from Perforce
% according specified depth level.
%
% Syntax:
%   sRoot = hlxPrintConfig(cDepotFile)
%   sRoot = hlxPrintConfig(cDepotFile,nLevel)
%   sRoot = hlxPrintConfig(cDepotFile,nLevel,sPath)
%
% Inputs:
%   sDepotFile - string 
%       nLevel - integer (1x1) with depth of referenced files to be fetched 
%                 1: {default} only configuration XML
%                 2: see 1 + Module XMLs according versionId
%                 3: see 2 + DataSet variant XMLs according versionId
%                 4: see 3 + SupportSet XMLs according versionId
%                 5: all files of Module SupportSets and DataSet variants
%                    according versionId
%        sPath - string 
%
% Outputs:
%   sRoot - string with root path (contains Configuration and Content
%           folder)
%
% Example: 
%   sRoot = hlxPrintConfig('//DIVe/d_main/com/DIVe/Configuration/Vehicle/Other/CosimCheckTime_jb0hxcwk0.xml')
%   sRoot = hlxPrintConfig('c:\dirsync\08Helix\11d_main\com\DIVe\Configuration\Vehicle\Other\CosimCheckTime_jb0hxcwk0.xml')
%   sRoot = hlxPrintConfig('//DIVe/d_main/com/DIVe/Configuration/Vehicle/Other/CosimCheckTime_jb0hxcwk0.xml@10214')
%   sRoot = hlxPrintConfig('//DIVe/d_main/com/DIVe/Configuration/Vehicle/Other/CosimCheckTime_jb0hxcwk0.xml',3)
%   sRoot = hlxPrintConfig('//DIVe/d_main/com/DIVe/Configuration/Vehicle/Other/CosimCheckTime_jb0hxcwk0.xml',3,'C:\temp\p4print')
%
% See also: p4print, p4, p4syncConfigVersion
%
% Author: Rainer Frey, TP/EAF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-03-25

%% check input
% ensure cell
if ischar(cDepotFile)
    cDepotFile = {cDepotFile};
end
% check specified depot path
if exist(cDepotFile{1},'file')
    % derive depot path of file
    [nStatus,sWorkspace] = p4switch(cDepotFile{1},false);
    if nStatus % path is part of a Perfore client
        [cRoot,cStream] = hlxFormParse(p4(sprintf('client -o %s',sWorkspace)),{'Root','Stream'});
        nPathRoot = numel(pathparts(cRoot{1}));
        % get Depot pathes from filesystem pathes
        for nIdxFile = 1:numel(cDepotFile)
            cPath = pathparts(cDepotFile{nIdxFile});
            cDepotFile{nIdxFile} = strGlue([cStream cPath(nPathRoot+1:end)],'/');
        end
    else
        error('hlxPrintConfig:noDepotPath',...
            'Specified filesystem path not part of a Perforce Helix workspace: %s',cDepotFile{1});
    end
elseif strcmp(cDepotFile{1}(1:2),'//')
    % verify existence in Perforce
    sMsg = p4(sprintf('changes -m 1 %s',cDepotFile{1}));
    if isempty(sMsg) % no changelists exist for this depot path
        error('hlxPrintConfig:noDepotPath',...
            'Unknown Perforce Helix Depot path specified: %s',cDepotFile{1});
    end
else
    error('hlxPrintConfig:noDepotPathAtAll',...
        'Unknown Perforce Helix Depot path specified: %s',cDepotFile{1});
end
if nargin < 2
    nLevel = 1;
end
if nargin < 3
    sPath = pwd;
end

% init output
sRoot = sPath;

% get configurations
cFileConfig = cell(size(cDepotFile));
% generate filepathes of configurations
for nIdxFile = 1:numel(cDepotFile)
    cPathDepot = pathparts(cDepotFile{nIdxFile});
    nConfigLevel = find(strcmp('Configuration',cPathDepot));
    sLast = regexprep(cPathDepot{end},{'\@\d+$','\#\d+$','#head$','#have$'},'');
    cFileConfig{nIdxFile} = fullfile(sPath,cPathDepot{nConfigLevel:end-1},[sLast '.xml']);
end
cStream = {strGlue(cPathDepot(1:nConfigLevel-1),'/')};
% print configs to filesystem
p4print(cDepotFile,cFileConfig);
if nLevel == 1
    return
end

% collect files/pathes
ccDeep = {};
cLevel = {'species','family','type'};
for nIdxFile = 1:numel(cFileConfig)
    % read configuration
    xTree = dsxRead(cFileConfig{nIdxFile});
    
    % loop over Setups
    for nIdxSetup = 1:numel(xTree.Configuration.ModuleSetup)
        % Module variant entry
        xSet = xTree.Configuration.ModuleSetup(nIdxSetup).Module;
        cLogHier = {xSet.context xSet.species xSet.family xSet.type};
        ccDeep{end+1,1} = [cLogHier {'Module' xSet.variant xSet.versionId}]; %#ok<AGROW>
        if nLevel > 2
            % DataSet variant entries
            for nIdxSet = 1:numel(xTree.Configuration.ModuleSetup(nIdxSetup).DataSet)
                xDat = xTree.Configuration.ModuleSetup(nIdxSetup).DataSet(nIdxSet);
                ccDeep{end+1,1} = [cLogHier(1:1+find(strcmp(xDat.level,cLevel))) ...
                    {'Data' xDat.classType xDat.variant xDat.versionId}]; %#ok<AGROW>
            end
        end
        if nLevel > 3
            % SupportSet entry
            for nIdxSet = 1:numel(xTree.Configuration.ModuleSetup(nIdxSetup).SupportSet)
                xSup = xTree.Configuration.ModuleSetup(nIdxSetup).SupportSet(nIdxSet);
                ccDeep{end+1,1} = [cLogHier(1:1+find(strcmp(xSup.level,cLevel))) ...
                    {'Support' xSup.name xSup.versionId}]; %#ok<AGROW>
            end
        end
    end % for xSetup
end % for cFile

% expand pathes
cDepot = cell(size(ccDeep));
cFile = cell(size(ccDeep));
for nIdxDeep = 1:numel(ccDeep)
    if ~isempty(ccDeep{nIdxDeep}{end})
        ccDeep{nIdxDeep}{end} = ['@' ccDeep{nIdxDeep}{end}]; %#ok<AGROW>
    end
    if nLevel > 4
        cDepot{nIdxDeep} = [strGlue([cStream {'Content'} ccDeep{nIdxDeep}(1:end-1) ...
                                     {'...'}],'/') ccDeep{nIdxDeep}{end}];
        cFile{nIdxDeep} = fullfile(sPath,'Content',strGlue(ccDeep{nIdxDeep}(1:end-1),filesep),'...');
    else
        cDepot{nIdxDeep} = [strGlue([cStream {'Content'} ccDeep{nIdxDeep}(1:end-1) ...
                                     {[ccDeep{nIdxDeep}{end-1} '.xml']}],'/') ccDeep{nIdxDeep}{end}];
        cFile{nIdxDeep} = fullfile(sPath,'Content',strGlue(ccDeep{nIdxDeep}(1:end-1),filesep),[ccDeep{nIdxDeep}{end-1} '.xml']);
    end
end
    
% print deep level files
p4print(cDepot,cFile);
return

