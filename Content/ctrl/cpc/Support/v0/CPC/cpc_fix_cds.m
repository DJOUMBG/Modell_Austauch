function [] = cpc_fix_cds(sDir)
% CPC_FIX_CDS fix CDS file names
%
%
% Syntax:  [] = cpc_fix_cds(sDir)
%
% Inputs:
%    sDir - [''] directory of CDS datasets (String)
%
% Outputs:
%     -
%
% Example:
%    cpc_fix_cds; % uses current path
%    cpc_fix_cds('C:\ploch37\20_DIVe\P4V\drm_conv\Content\ctrl\cpc\silver\cpc5ce_t23_3\Data\cds\std');
%
%
% Subfunctions: rename_files
%
% Author: PLOCH37
% Date:   15-Jan-2024

%% ------------- BEGIN CODE --------------

% Define directory
if ~exist('sDir', 'var')
    sDir = pwd;
end

% Rename files (case sensitive)
rename_files(sDir, '_TEST.HEX', '.hex')
rename_files(sDir, '_Export_Log.TXT', '_Log.txt')


function rename_files(sDir, sOld, sNew)

% Find files 
cFile = dir(fullfile(sDir, ['*' sOld '*']));
cFile = {cFile.name}';

% Rename files
for n = 1:length(cFile)
    % File names
    sFile0 = cFile{n};
    sFile1 = strrep(sFile0, sOld, sNew);
    % File pathes
    sPath0 = fullfile(sDir, sFile0);
    sPath1 = fullfile(sDir, sFile1);
    % Rename file
    movefile(sPath0, sPath1)
    % Display info
    disp([sFile0 ' --> ' sFile1])
end

