function [Y] = read_silver_par_file(sFile, bDebug) %#ok<*NASGU>
% READ_SILVER_PAR_FILE read silver par/init/txt files
% txt files that defines parameter like this: ptconf_p_Trans.GearRatio_s16[19]=1;
%
%
% Syntax:  [Y] = read_silver_par_file(sFile)
%
% Inputs:
%     sFile - [''] Silver txt file (optional, default: cal_out.txt)
%    bDebug - [-] Output warnings (optional, default: 0)
%
% Outputs:
%    Y - [.] Output structure with read parameter
%
% Example:
%    Y = read_silver_par_file;
%    Y = read_silver_par_file('cal_out.txt');
%    Y = read_silver_par_file('cal_out.txt', 1);
%
%
% See also: write_silver_par_file

% Author: ploch37
% Date:   14-Nov-2018
%
% SVN: (is set automatically, if Keywords - Property enabled)
%   $Rev:: 2631                                                 $
%   $Author:: ploch37                                           $
%   $Date:: 2019-01-15 13:59:43 +0100 (Di, 15. Jan 2019)        $
%   $URL: file:///J:/TG/FCplatform/500_newLDYN_SimPlatform/DIVeLDYN_svn/trunk/ldDevProj/case/c000/Content/ctrl/cpc/Support/v0/CPC/read_silver_par_file.m $


%% Default input
if ~exist('sFile', 'var') || isempty(sFile)
    sFile = 'cal_out.txt';
end
if ~exist('bDebug', 'var') || isempty(bDebug)
    bDebug = 0;
end


%% Init output
Y = [];


%% Read file
fid = fopen(sFile);
c = textscan(fid, '%[^=]=%[^;];', 'CommentStyle', '/'); % read values like string to consider lines like this: 5000*0.001
fclose(fid);
sNames = c{1};
dValues = c{2};


%% Write structure output variable
for k = 1:length(sNames)
    sNameDef = regexp(sNames{k}, '[a-zA-Z_0-9.]*', 'match');
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
    try
        eval(['Y.' sName '(row, col) = ' dValues{k} ';']); % consider substructures like ptconf_p_Trans.TransType_u8, therefor use of eval
    catch
        if bDebug
            fprintf('Ignore: %s = %s;\n', sNames{k}, dValues{k});
        end
    end
end
