function varargout = getMatlabInstallation(varargin)
% GETMATLABINSTALLATION determine available MATLAB installations on the
% current machine.
%
% Syntax:
%   cVersion = getMatlabInstallation
%   cVersion = getMatlabInstallation(sReleaseVersion)
%   cVersion = getMatlabInstallation(sProperty)
%   cVersion = getMatlabInstallation(sReleaseVersion,sProperty)
%
% Inputs:
%   sRelease  - [optional] string with requested release or version
%               e.g. 'R2009a','R2009a_32','7.8_win64';
%   sProperty - [optional] string with only requested property:
%               'executable' - string with filepath to executable
%               'path'       - string with installation path
%               'release'    - string with MATLAB release, e.g. 'R2009a'
%               'version'    - string with MATLAB major version, e.g. '7.8'
%
% Outputs:
%   cVersionAll - cell (nx6) with string of MATLAB installation instances
%               m = 1: string with filepath of executable
%                   2: string with installation path
%                   3: string with release
%                   4: string with version
%                   5: string with bit variant (32 or 64; based on
%                      assumption 32bit in doubt)
%                   6: string with installation folder
%
% Example: 
%   cVersionAll = getMatlabInstallation
%   sExecutable = getMatlabInstallation('7.8','executable')
%   sExecutable = getMatlabInstallation('r2014a','executable')
%   cPath = getMatlabInstallation('path')
%   cRelease = getMatlabInstallation('release')
%   cVersion = getMatlabInstallation('version')
%
% See also: strsplitOwn, versionAliasMatlab
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-08-19

% get operating system path environment
sEnv = getenv('PATH');
cPath = strsplitOwn(sEnv,';');

% search for MATLAB installation paths
cMatlabHit = regexpi(cPath,'matlab','once');
bMatlab = ~cellfun(@isempty,cMatlabHit);
cPath = cPath(bMatlab);
% remove double hits on win32 pathes
cPath = regexprep(cPath,{'\\win32$','\\win64$','\\bin','\\runtime','\\polyspace'},...
    {'','','','',''});
cPath = unique(cPath);

% try to determine MATLAB version from installation path
cMatch = regexpi(cPath,'r\d{4}[ab]|\d+[_\.]\d+','match','once');
if all(cellfun(@isempty,cMatch))
    % rogure MATLAB installations
    cMatch = regexpi(cPath,'\d{4}[ab]|\d+[_\.]\d+','match','once');
    cMatch = cellfun(@(x)['r' x],cMatch,'UniformOutput',false);
end
cFolder = regexpi(cPath,'\w*r\d{4}[ab]\w*|\w*\d+[_\.]\d+\w*','match','once');
if all(cellfun(@isempty,cMatch))
    % rogure MATLAB installations
    cFolder = regexpi(cPath,'\w*\d{4}[ab]\w*|\w*\d+[_\.]\d+\w*','match','once');
end
cMatch = regexprep(cMatch,'_','.');
cVersion = cell(0,6);
for nIdxPath = 1:numel(cMatch)
    % determine version information folders
    [sRelease,sVersion] = versionAliasMatlab(cMatch{nIdxPath},'all');
    if any(strfind(cFolder{nIdxPath},'64'))
        sBit = 'w64';
    else
        sBit = 'w32';
    end
    
    % determine executable
    if strcmp(sRelease,'R2006b')
        sExecutable = fullfile(cPath{nIdxPath},'bin','matlab.bat');
    else
        sExecutable = fullfile(cPath{nIdxPath},'bin','matlab.exe');
    end
    
    % create cell entry
    cVersion(end+1,1:6) = {sExecutable,cPath{nIdxPath},sRelease,sVersion,...
                           sBit,cFolder{nIdxPath}}; %#ok<AGROW>
end

% reduce output on release
bArgIn = ismember(varargin,{'executable','path','release','version'});
if any(~bArgIn)
    % get version or release argument
    sVersionRelease = varargin{~bArgIn};
    [sRelease,sVersion,cBit] = versionAliasMatlab(sVersionRelease,'all'); %#ok<NASGU,ASGLU>
    
    % determine viable installations
    bVersion = strcmp(sRelease,cVersion(:,3));
    cVersion = cVersion(bVersion,:);
    
    % check for output
    if sum(bVersion)>1
        % try bit reduction
        if strfind(sVersionRelease,'32') 
            % assume request of 32bit version
            bBit = strcmp('w32',cVersion(:,5));
            cVersion = cVersion(bBit,:);
        elseif strfind(sVersionRelease,'64')
            % assume request of 64bit version
            bBit = strcmp('w64',cVersion(:,5));
            cVersion = cVersion(bBit,:);
        end
        if size(cVersion,1) > 1
            % bit reduction did not resolve the multiple installations
            fprintf(2,['CAUTION: ' mfilename ' detected multiple ' ...
                'installations for the requested version "%s":\n'],sVersionRelease);
            for nIdxRow = 1:size(cVersion,1)
                fprintf(2,'   %s\n',cVersion{:,1});
            end
        end % if still more than one version
    end % if more than one version
end % argument except property type exists

% reduce output on type
if any(strcmpi('executable',varargin))
    cVersion = cVersion(:,1);
end
if any(strcmpi('path',varargin))
    cVersion = cVersion(:,2);
end
if any(strcmpi('release',varargin))
    cVersion = cVersion(:,3);
end
if any(strcmpi('version',varargin))
    cVersion = cVersion(:,4);
end

% assign output
if numel(cVersion) == 1
    varargout = cVersion;
else
    varargout = {cVersion};
end
return
