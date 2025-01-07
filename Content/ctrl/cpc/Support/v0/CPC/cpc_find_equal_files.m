function cpc_find_equal_files(sFile)
% CPC_FIND_EQUAL_FILES show equal files in different CPC releases
%
%
% Syntax:  cpc_find_equal_files(sFile)
%
% Inputs:
%    sFile - [''] file path (String)
%
% Outputs:
%     -
%
% Example:
%    cpc_find_equal_files('C:\ploch37\20_DIVe\P4V\drm_conv\Content\ctrl\cpc\silver\cpc6_t23_3\Support\v000\cpc\cpc_eep4sim.m');
%
%
% Author: PLOCH37
% Date:   13-Oct-2023

%% ------------- BEGIN CODE --------------

% Find cpc main folder
sKey = 'cpc\silver';
idx = strfind(sFile, sKey);
sDirMain = sFile(1 : idx + length(sKey));

% Find file path in release folders
sPathFile = strrep(sFile, sDirMain, ''); % remove main folder
sPathFile = regexprep(sPathFile, '\w*', '', 'once'); % remove release folder

% Find different release folders
xDirList = dir(sDirMain);
xDirList(~[xDirList.isdir]) = []; % only folder
cDir = {xDirList.name}'; % only names
idx = ismember(cDir, {'.', '..', 'Data', 'Support'}); % idx of ignored folder
cDir(idx) = []; % remove ignored folder
cDir = flipud(sort(cDir)); %#ok<FLPST> % latest release first

% Compare Checksum of base and other files
sMD5 = Simulink.getFileChecksum(sFile);
disp(sFile);
for n = 1:length(cDir)
    sF_disp = fullfile(cDir{n}, sPathFile);
    sF = fullfile(sDirMain,sF_disp);
    if exist(sF, 'file')
        sMD5_ = Simulink.getFileChecksum(sF);
        if strcmp(sMD5, sMD5_)
            fprintf(1, '%s is equal\n', sF_disp);
        else
            fprintf(2, '%s is different\n', sF_disp);
        end
    else
        fprintf(1, '%s doesn''t exist\n', sF_disp);
    end
end