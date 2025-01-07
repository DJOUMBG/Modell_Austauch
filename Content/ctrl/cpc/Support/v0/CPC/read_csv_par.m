function [Y] = read_csv_par(sFile) %#ok<*NASGU>
% READ_CSV_PAR read last values of csv file as parameter
% 1st value will be ignored, as probably it will be time value
%
%
% Syntax:  [Y] = read_csv_par(sFile)
%
% Inputs:
%    sFile - [''] csv file(String)
%
% Outputs:
%    Y - [.] Output structure with read parameter
%
% Example: 
%    Y = read_csv_par('cpc_debug.csv');

% Author: PLOCH37
% Date:   04-Nov-2020
%
% SVN: (is set automatically, if Keywords - Property enabled)
%   $Rev:: 3508                                                 $
%   $Author:: PLOCH37                                           $
%   $Date:: 2020-11-09 00:00:13 +0100 (Mo, 09. Nov 2020)        $
%   $URL: file:///J:/TG/FCplatform/500_newLDYN_SimPlatform/DIVeLDYN_svn/trunk/ldDevProj/case/c000/Content/ctrl/cpc/Support/v0/CPC/read_csv_par.m $


%% Default input
if ~exist('sFile', 'var') || isempty(sFile)
    sFile = 'cpc_debug.csv';
end


%% Init output
Y = [];


%% Read file
% Open file
fid = fopen(sFile);
% Get Parameter
sPar = fgetl(fid);
% Get Values (read until last line reached)
while ~feof(fid)
    sVal = fgetl(fid);
end
% Close file
fclose(fid);


%% Write structure output variable
sNames = textscan(sPar, '%s', 'Delimiter', ',');
sNames = sNames{1};
dValues = textscan(sVal, '%f', 'Delimiter', ',');
dValues = dValues{1};

for k = 2:length(sNames) % ignore 1st value = time
    sNameDef = regexp(sNames{k}, '[a-zA-Z_0-9.]*', 'match'); % split "name[1][4]"
    sName = sNameDef{1};
    col = 1;
    row = 1;
    switch length(sNameDef)
        case 2
            col = str2double(sNameDef{2}) + 1; % col starts with 0
        case 3
            col = str2double(sNameDef{2}) + 1; % column and row starts with 0
            row = str2double(sNameDef{3}) + 1;
    end
    % Check if signals already written, but other signals in struct
    % for example signals: cdi_g_VersCAL and cdi_g_VersCAL.day
    if any(sName == '.') 
        sStructNames = strsplit(sName, '.');
        if isfield(Y, sStructNames{1}) && ~isstruct(Y.(sStructNames{1}))
            Y = rmfield(Y, sStructNames{1});
            fprintf('Removed %s to write %s\n', sStructNames{1}, sName);
        end
    end
    % Write values
    try
        eval(['Y.' sName '(row, col) = dValues(k);']); % consider names like cal_a_Cal.Save_u8, therefore use of eval
    catch
        fprintf('Ignore %s\n', sName);
    end
end
