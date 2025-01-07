function [] = par2mat(sFile)
% PAR2MAT reads par file and save as mat file
% - clears also parameter that are not EEPROM parameter
% - can be used to create main par files for CPC for faster initialisation
%
%
% Syntax:  [] = par2mat(sFile)
%
% Inputs:
%    sFile - [''] File name and location or folder name (String)
%
% Outputs:
%     -
%
% Example: 
%    par2mat('cpc_eep.par') % 1 par file
%    par2mat('C:\ploch37\parfiles\') % all par in this folder
%    par2mat % all par files in current folder
%
%
% See also: read_par_file
%
% Author: PLOCH37
% Date:   07-Aug-2020

BACKUP_SUFFIX = '_org';

%% Read all par files in folder
if nargin == 0
    sFile = pwd;
end
if exist(sFile, 'file') == 7 % file is folder
    sDir = sFile;
    sFiles = dir(fullfile(sDir, '*.par'));
    sFiles = {sFiles.name}';
    % Ignore backup files
    idx = cellfun(@isempty, strfind(sFiles, [BACKUP_SUFFIX '.par']));
    sFiles = sFiles(idx);
    % Run this function for all par files in folder
    for k = 1:length(sFiles);
        % Recursive call of this function
        par2mat(fullfile(sDir, sFiles{k}));
    end
    return
end

%% Read par file as text
fid = fopen(sFile);
c = textscan(fid, '%[^\n]', 'Whitespace', ''); % read any line
c = c{1};
fclose(fid);

%% Read par file into Matlab
EEP = read_par_file(sFile);


%% Save original file as backup
[sDir, sName] = fileparts(sFile);
sFileBackup = fullfile(sDir, [sName BACKUP_SUFFIX]);
if ~exist([sFileBackup '.mat'], 'file') 
    save(fullfile(sDir, [sName BACKUP_SUFFIX '.mat']), '-struct', 'EEP');
end
if ~exist([sFileBackup '.par'], 'file') 
    copyfile(sFile, [sFileBackup '.par']);
end


%% Clear par file from paramater that are not EEP parameter
sFieldExcept = {
    ''
    };
sFieldRemove = {
    'cal_a_Cal' % CAL parameter are coming from CDS file
    'fm_a_XfCal' % Fleet Management flash data
    'fm_a_Cal' % Stored Fleet Management values
    'dpf_a_Cal' % Stored Diesel Particle Filter values
    };
% Remove parameter
sField = fieldnames(EEP);
for k = 1:length(sField)
    s = sField{k};
    if any(strcmp(s, sFieldExcept))
        % Do not remove explicit defined parameter
    elseif any(strcmp(s, sFieldRemove))
        % Remove explicit defined parameter
        fprintf(1, 'Removed %s\n', s);
        EEP = rmfield(EEP, s);
        c = removePar(c, s);
    elseif ~isstruct(EEP.(s))
        % Remove all parameter that are not in the struct
        EEP = rmfield(EEP, s);
        c = removePar(c, s);
    elseif isempty(strfind(s, '_p_')) && isempty(strfind(s, '_a_'))
        % Remove all parameter that are not
        % _p_ (normal parameter) or _a_ (read in parameter)
        EEP = rmfield(EEP, s);
    elseif isfield(EEP.(s), 'Free_u8')
        % Remove all free or reserved bytes
        [c, EEP] = removeFree(c, EEP, s, 'Free_u8');
    elseif isfield(EEP.(s), 'free_u8')
        % Remove all free or reserved bytes
        [c, EEP] = removeFree(c, EEP, s, 'free_u8');
    end
end


%% Save new file as mat
save([fullfile(sDir, sName) '.mat'], '-struct', 'EEP');

%% Write new file as par
fid = fopen(sFile, 'w');
for l = 1:length(c)
    fprintf(fid, '%s\n', c{l});
end
fclose(fid);


function [c, EEP] = removeFree(c, EEP, s, sFree)
% Remove all free or reserved bytes
if length(unique(EEP.(s).(sFree))) ~= 1
    fprintf(1, 'Values set in %s\n', [s '.' sFree]);
else
    % fprintf(1, 'All values in %s: %g\n', [s '.' sFree], unique(EEP.(s).(sFree)));
end
c = removePar(c, [s, '.' sFree]);
EEP.(s) = rmfield(EEP.(s), sFree);


function [c] = removePar(c, sPar)
% Remove defined paramter from par file
idx = find(strncmp(c, sPar, length(sPar)));
if length(idx) > 1
    % Search for exact this name. White space assumed after the parameter name
    idx = find(strncmp(c, [sPar ' '], length(sPar)+1));
end
if length(idx) == 1 % only 1 Parameter with this name found
    c(idx) = []; % remove parameter line
    while idx <= length(c) && c{idx}(1) == ':' % remove also following lines, if paramter is an array
        c(idx) = [];
    end
end