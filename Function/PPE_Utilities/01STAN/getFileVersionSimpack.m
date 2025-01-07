function sRelease = getFileVersionSimpack(sFile)
% GETFILEVERSIONSIMPACK get the Release/Version and bit-type of zipped
% Simpack model container
%
% Syntax:
%   sRelease = getFileVersionSimpack(sFile)
%
% Inputs:
%   sFile - string with file path of Simpack zip container file
%
% Outputs:
%   sRelease - string with release version of Simpack container 
%              (e.g. w64_20190001)
%
% Example: 
%   sRelease = getFileVersionSimpack(sFile)
%
% See also: dsxRead, zip7Extract, versionAliasSimulink, strGlue
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-10-11

% check input
if ~exist(sFile,'file')
    error('getFileVersionSimpack:fileNotFound',...
        'The specified file is not on the file system: %s',sFile)
end

% initialize output
sRelease = '';
sBit = '';
sVersion = '';

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
[sPath,sName,sExt] = fileparts(sFile);

if strcmpi(sExt,'.zip')
    % get list of files in zip
    [nStatus,sMsg] = system(sprintf('"%s" l "%s"',sFileExe,sFile));
    if nStatus
        error('zip7:ListingFail',['The the listing of the zip file failed: '...
              '%s\n'],sFile);
    end
    
    % parse 7z listing
    cLine = strsplitOwn(sMsg,char(10));
    cContent = regexp(cLine,['(?<=' sName ').+'],'match','once');
    % check bit dependecies via user lib
    cUserLib = regexp(cContent(end-20:end),'(?<=\\user_routines\\lib\\)win\d\d$','match','once');
    cUserLib = cUserLib(~cellfun(@isempty,cUserLib));
    cUserLib = unique(cUserLib);
    switch numel(cUserLib)
        case 0
            sBit = 'w3264';
        case 1
            sBit = regexprep(cUserLib{1},'win','w');
        otherwise
            error('zip7:MultipleBitUserLib',['User libs with multiple bit ' ...
                'versions under "user_routines\lib" folder in zip-file: %s\n'],sFile);
    end
    % determine main model file
    cSpck = regexp(cContent,'(?<=\\main_model\\)[\w-]+\.spck$','match','once');
    cSpck = cSpck(~cellfun(@isempty,cSpck));
    switch numel(cSpck)
        case 0
            fprintf(2,['Simpack version determination: No *.spck file under' ...
                ' "main_model" folder in zip-file: %s\n'],sFile);
            return
        case 1
            sFileExtract = cSpck{1};
        otherwise
            error('zip7:MultipleMainModel',['Multiple *.spck files under "main_model" ' ...
                'folder in zip-file: %s\n'],sFile);
    end
    
    % extract *.spck file from zip file
    zip7Extract(sFile,sFileExtract,sPath)
    sSpck = fullfile(sPath,sFileExtract);
    
    if ~exist(sSpck,'file')
        % file not found in zipfile
        fprintf(2,['Simpack *.spck could not be retrieved from zip file - ' ...
                   'other name than zipfile?']);
    end
    
    % extract release from XML file
    try
        nFid = fopen(sSpck,'r');
        bSearch = 0;
        while bSearch < 1 && ~feof(nFid)
            sLine = fgetl(nFid);
            if strcmp(sLine(1:min(14,numel(sLine))),'version.number')
                sVersion = sLine(18:end);
                bSearch = 1;
            end
        end
        fclose(nFid);
    catch ME
        fclose(nFid);
        error('getFileVersionSimpack:failFileRead',...
            'Error during parsing of main_model spck-file: "%s" \nError message: %s',...
            sSpck,ME.message)
    end
    delete(sSpck);
else
    % file type is unknown here
    error('getFileVersionSimpack:unknownFileType',...
        'The file type "%s" is unknown for Simpack Version determination!',sExt);
end

% create output
sRelease = strGlue({sBit,sVersion},'_');
return
