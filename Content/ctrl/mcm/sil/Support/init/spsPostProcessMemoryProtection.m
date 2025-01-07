function spsPostProcessMemoryProtection(sPath,vTimeEnd,sOption)
% SPSPOSTPROCESSMEMORYPROTECTION checks for sufficient memory for
% postprocessing and invokes postprocessing in an extra MATLAB instance if
% necessary.
%
% Syntax:
%   spsPostProcessMemoryProtection(sPath,vTimeEnd)
%
% Inputs:
%       sPath - string with path of simulation folderS
%    vTimeEnd - value of simulation end time, used for needed memory
%               estimation in postprocessing
%     sOption - string with evaluation option:
%                on: recorder evaluation
%                stationary: recorder evaluation an stationary extraction
%
% Example: 
%   spsPostProcessMemoryProtection(pwd,1800,'on')

% check input
if nargin < 2
    vTimeEnd = 100;
end
if nargin < 3
    sOption = 'on';
end

% check if postprocessing is necessary
xContent = dir(fullfile(sPath,'MVA*.asc'));
if isempty(xContent)
    return
end

% get memory state
xMemory = memory;

% check memory limit
if xMemory.MaxPossibleArrayBytes < 20e6 + 0.16e6 * vTimeEnd % limit at 20MB + 0.2MB * second for MVA output
    % check for availability of 64bit Matlab for Postprocessing
    xMatlabThis = ver('Matlab');
    sMatlabThis = regexp(xMatlabThis.Release,'\w+','match','once');
    cMatlab = getMatlabInstallation; % get exe-files of all Matlab installations
    if strcmp('win64',computer('arch'))
        nThis = find(strcmp(sMatlabThis,cMatlab(:,3)));
        sExecutable = cMatlab{nThis(1),1};
    else % try other 64bit MATLAB
        nOther = find(strcmp('w64',cMatlab(:,5)));
        if isempty(nOther) % fallback - this matlab version
            sExecutable = fullfile(matlabroot,'bin','win32','matlab.exe');
        else % first 64bit version
            sExecutable = cMatlab{nOther(1),1};
        end
    end
    
    % execute in an own MATLAB instance
    sSystem = sprintf(['"%s" -nosplash -nodesktop -minimize -r '...
                       'addpath(genpath(''%s''));'...
                       'addpath(''%s'');funcall(''spsMvaTransfer'',''%s'',''%s'') ' ...
                       '-logfile LogPostProcessing.txt'],...
                      sExecutable,... % matlab executable of this version
                      fullfile(fileparts(fileparts(sPath)),'Utilities'),... % matlab executable of this version
                      fileparts(mfilename('fullpath')),... % addpath of supportset folder
                      sPath,... % runpath
                      sOption); % evaluaton option
    system(sSystem);
else
    % execute in this MATLAB instance
    spsMvaTransfer(sPath,sOption)
end
return
