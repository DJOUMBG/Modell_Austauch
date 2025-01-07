function sRelease = getFileVersionSimulationX(sFile)
% GETFILEVERSIONSIMULATIONX get the Release/Version and bit-type of zipped
% SimulationX model container (*.isx).
%
% Syntax:
%   sRelease = getFileVersionSimulationX(sFile)
%
% Inputs:
%   sFile - string with file path of Simpack zip container file
%
% Outputs:
%   sRelease - string with release version of SimulationX authoring tool 
%              (e.g. SimulationX_w64_R39)
%
% Example: 
%   sRelease = getFileVersionSimulationX(sFile)
%
% See also: dsxRead, zip7Extract, versionAliasSimulink, strGlue
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-08-25

% check input
if ~exist(sFile,'file')
    error('getFileVersionSimulationX:fileNotFound',...
        'The specified file is not on the file system: %s',sFile)
end

% initialize output
sRelease = '';

% try to determine installation location
try
    sIcon = winqueryreg('HKEY_CLASSES_ROOT','7-Zip.7z\DefaultIcon');
    sFileExe = fullfile(fileparts(sIcon),'7z.exe');
catch  %#ok<CTCH>
    sFileExe = 'C:\Program Files\7-Zip\7z.exe';
end
if ~exist(sFileExe,'file')
    error('zip7:noExeFile',['The determination of the 7z.exe location ' ...
        'failed - aborting zip operation: %s\n'],sFileExe);
end

% determine file type
[sPath,sName,sExt] = fileparts(sFile); %#ok<ASGLU>

if strcmpi(sExt,'.isx')
    % get list of files in zip
    [nStatus,sMsg] = system(sprintf('"%s" l "%s"',sFileExe,sFile));
    if nStatus
        error('zip7:ListingFail',['The the listing of the zip file failed: '...
              '%s\n'],sFile);
    end
    
    % parse 7z listing
    cLine = strsplitOwn(sMsg,char(10)); %#ok<CHARTEN>

    % determine main model file
    cApp = regexp(cLine,'docProps\\app\.xml','match','once');
    cApp = cApp(~cellfun(@isempty,cApp));
    switch numel(cApp)
        case 0
            fprintf(2,['SimulationX version determination: No app.xml file under' ...
                ' "docProps" folder in isx-file: %s\n'],sFile);
            return
        case 1
            sFileExtract = cApp{1};
        otherwise
            error('zip7:MultipleAppInfo',['Multiple app.xml files under "docProps" ' ...
                'folder in isx-file: %s\n'],sFile);
    end
    
    % extract app.xml file from ixs file
    zip7Extract(sFile,sFileExtract,sPath)
    sFileOnly = regexp(sFileExtract,'[\w\.]+$','match','once');
    sAppXml = fullfile(sPath,sFileOnly);
    
    if ~exist(sAppXml,'file')
        % file not found in zipfile
        fprintf(2,['app.xml could not be retrieved from isx file - ' ...
                   'failed on version determination']);
    end
    
    % extract release from XML file
    try
        xTree = dsxRead(sAppXml);
        sVersion = xTree.Properties.AppVersion.cONTENT;
        sBit = strrep(regexp(sVersion,'\w+$','match','once'),'x','w');
        sVersionShort = strrep(regexp(sVersion,'\d+.\d+','match','once'),'.','');
    catch ME
        fclose(nFid);
        error('getFileVersionSimpack:failFileRead',...
            'Error during parsing of main_model spck-file: "%s" \nError message: %s',...
            sAppXml,ME.message)
    end
    delete(sAppXml);
else
    % file type is unknown here
    error('getFileVersionSimulationX:unknownFileType',...
        'The file type "%s" is unknown for SimulationX Version determination!',sExt);
end

% create output
sRelease = sprintf('SimulationX_%s_R%s',sBit,sVersionShort);
return
