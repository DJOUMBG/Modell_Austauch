function [sTool,sFmu] = getFileVersionFmu(sFile)
% GETFILEVERSIONFMU get the Release/Version and bit-type of zipped
% FMU model container
%
% Syntax:
%   [sTool,sFmu] = getFileVersionFmu(sFile)
%
% Inputs:
%   sFile - string with file path of FMU file
%
% Outputs:
%   sTool - string with authoring tool version of FMU file 
%           e.g. SimulationX_w3264_3_7_0_34479, Simpack_w64_2019x
%    sFmu - string with FMI version and bit implementation info 
%           e.g. 'fmu10_w64' or 'fmu20_w3264'
%
% Example: 
%   sFile = fullfile(getBasePath,['Content\phys\mec\minimal4sil\hd_om471_g281_gw5_hl6\' ... 
%     'Module\std\fmu10\mec_minimal4sil_hd_om471_g281_gw5_hl6_std.fmu'])
%   sFile = fullfile(getBasePath,['phys\mec3d\mbsrtm\' ... 
%     'truck_Solo_4xX_LU_SiZw_V01\Module\SFTP_V451\fmu10\SFTP_V451.fmu'])
%   [sTool,sFmu] = getFileVersionFmu(sFile)
%
% See also: dsxReadCfgHeader, zip7Extract, versionAliasSimulink, strGlue, 
%           regexp, regexprep, regexptranslate, strrep, strtrim
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-02-01

% check input
if ~exist(sFile,'file')
    error('getFileVersionFmu:fileNotFound',...
        'The specified file is not on the file system: %s',sFile)
end

% determine file type
[sPath,sName,sExt] = fileparts(sFile); %#ok<ASGLU>

if ~strcmpi(sExt,'.fmu')
    % file type is unknown here
    error('getFileVersionFmu:unknownFileType',...
        'The file type "%s" is unknown for FMU Version determination!',sExt);
end
    
% extract file modelDescription.xml from zip file
sFileExtract = 'modelDescription.xml';
cList = zip7Extract(sFile,sFileExtract,sPath,true);
bHit = ~cellfun(@isempty,regexp(cList,'modelDescription.xml','match','once'));
if sum(bHit) > 1
    error('zip7:MultipleMainModel','Multiple files in zip-file found: %s\n',sFile);
end
sModDes = fullfile(sPath,sFileExtract);
if ~exist(sModDes,'file')
    % file not found in zipfile
    fprintf(2,'File "modelDescription.xml" could not be retrieved from *.fmu file');
end

% read XML file
xTree = dsxReadCfgHeader(sModDes);
delete(sModDes); % delete file

% extract release info from XML structure
if isfield(xTree,'fmiModelDescription')
    if isfield(xTree.fmiModelDescription,'fmiVersion')
        fmiVersion = xTree.fmiModelDescription.fmiVersion;
    else
        error('getFileVersionFmu:missingFmuVersion',...
            ['The FMU''s "modelDescription.xml" has no ' ...
            '"fmuVersion" attribute or an unusual format.']);
    end
    if isfield(xTree.fmiModelDescription,'generationTool')
        fmuGenTool = xTree.fmiModelDescription.generationTool;
    else
        error('getFileVersionFmu:missingGenerationTool',...
            ['The FMU''s "modelDescription.xml" has no ' ...
            '"generationTool" attribute or an unusual format.']);
    end
else
    error('getFileVersionFmu:missingFmiModelDescription',...
        ['The FMU''s "modelDescription.xml" has no ' ...
        '"fmiModelDescription" tag or an unusual format.']);
end

% determine available bit versions
sFS = regexptranslate('escape',filesep);
nW32 = double(any(~cellfun(@isempty,regexp(cList,[sFS 'win32' sFS],'once'))));
nW64 = 2*double(any(~cellfun(@isempty,regexp(cList,[sFS 'win64' sFS],'once'))));
nL32 = double(any(~cellfun(@isempty,regexp(cList,[sFS 'linux32' sFS],'once'))));
nL64 = 2*double(any(~cellfun(@isempty,regexp(cList,[sFS 'linux64' sFS],'once'))));
cBinW = {'','w32','w64','w3264'}; % possible values
cBinL = {'','l32','l64','l3264'}; % possible values
if nW32+nW64 < 1 
    fprintf(2,'Warning: No Windows implementation found in FMU "%s"\n',sFile);
end
sBin = [cBinW{nW32+nW64+1} cBinL{nL32+nL64+1}];
        
% create output
fmuGenTool = regexprep(fmuGenTool,'\([^\)]+\)',''); % remove bracket with content
sFmu = ['fmu' strrep(fmiVersion,'.','') '_' sBin]; % create e.g. fmu10_w3264
[sFront,nEnd] = regexp(fmuGenTool,'^\w+','match','end','once'); % get front word
sRear = strtrim(fmuGenTool(nEnd+2:end)); % rear part without blanks
sRear = regexprep(sRear,'[ \.\(\)]','_'); % replace .()blank with _
sTool = [sFront,'_',sBin,'_',sRear]; % create e.g. SimulationX_w3264_3_7_0_34479
return
