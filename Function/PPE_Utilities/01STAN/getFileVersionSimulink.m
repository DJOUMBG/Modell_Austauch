function sRelease = getFileVersionSimulink(sFile)
% GETFILEVERSIONSIMULINK get the Matlab Release of a Simulink file (mdl or
% slx).
%
% Syntax:
%   sRelease = getFileVersionSimulink(sFile)
%
% Inputs:
%   sFile - string with file path of Simulink file
%
% Outputs:
%   sRelease - string with release version of Matlab of this Simulink file
%
% Example: 
%   sRelease = getFileVersionSimulink(sFile)
%
% See also: dsxRead, zip7Extract, versionAliasSimulink
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-04-03

% check input
if ~exist(sFile,'file')
    error('getFileVersionSimulink:fileNotFound',...
        'The specified file is not on the file system: %s',sFile)
end

% initialize output
sRelease = '';

% determine file type
[sPath,sName,sExt] = fileparts(sFile); %#ok<ASGLU>

if strcmpi(sExt,'.mdl')
    % read file until version information
    sLine = '';
    nFid = fopen(sFile,'r');
    try 
        while ischar(sLine)
            % get next line from file
            sLine = fgetl(nFid);
            if ischar(sLine)
                sLine = strtrim(sLine);
                if strcmp(sLine(1:min(numel(sLine),7)),'Version')
                    sVersion = strtrim(sLine(8:end));
                    sLine = -1; % break loop
                end % if Version content of file
            end % if char array
        end % while lines in file
    catch ME
        fprintf(1,'getFileVersionSimulink - Failure in mdl-file read: %s\n',ME.message);
        fclose(nFid);
    end
    fclose(nFid);
    
    % convert Simulink version information into MATLAB release string
    sRelease = versionAliasSimulink(sVersion); % convert version to release
    
elseif strcmpi(sExt,'.slx')
    % extract XML from slx (=zip) file
    cFileExtract = {'mwcoreProperties.xml','coreProperties.xml'};
    cField = {'mwcoreProperties.matlabRelease.cONTENT','cp0x3AcoreProperties.cp0x3Aversion.cONTENT'};
    cXml = cellfun(@(x)fullfile(sPath,x),cFileExtract,'UniformOutput',false);
    zip7Extract(sFile,cFileExtract,sPath); % extract file(s)
    bExist = ismember(cFileExtract,dirPattern(sPath,'*','file')); % check which files were successful
    nExist = find(bExist,1,'first'); % only search in newer file, older one might be still there
   
    % extract release from XML file
    try
        xTree = dsxRead(cXml{nExist(1)});
        sRelease = getfieldRecursive(xTree,cField{nExist(1)});
    catch ME
        error('getFileVersionSimulink:failXmlRead',...
            'The Version XML "%s" contains not a release info: %s',sXml,ME.message)
    end
    delete(cXml{bExist});
else
    % file type is unknown here
    error('getFileVersionSimulink:unknownFileType',...
        'The file type "%s" is unknown!',sExt);
end
return

% =========================================================================

