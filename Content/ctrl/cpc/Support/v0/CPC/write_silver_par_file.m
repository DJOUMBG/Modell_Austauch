function [] = write_silver_par_file(Y, sFile, sAccess, sTitle)
% WRITE_SILVER_PAR_FILE write silver par/init/txt files
% txt files that defines parameter like this: ptconf_p_Trans.GearRatio_s16[19]=1;
%
%
% Syntax:  [] = write_silver_par_file(Y, sFile, sAccess, sTitle)
%
% Inputs:
%        Y - [.] structure with parameters (physical, not raw values)
%    sFile - [''] file to write to
%  sAccess - [''] file access type (optional, default: 'w')
%   sTitle - [''] title/comment (optional, default: '')
%
% Outputs:
%     -
%
% Example: 
%    write_silver_par_file(sMP.ctrl.cpc.CDS, 'cpc_cds.txt'); % CDS parameter must by physical and not raw values
%    write_silver_par_file(sMP.ctrl.cpc.EEP, 'eep_physical.txt'); % would only make sense, if EEP parameter are physical values
%    write_silver_par_file(sMP.ctrl.cpc.CAL, 'CPC5_defaults.txt', 'a', 'CAL values') % append CAL values
%
%
% Subfunctions: writeVar
%
% See also: read_silver_par_file

% Author: ploch37
% Date:   10-Dec-2018
%
% SVN: (is set automatically, if Keywords - Property enabled)
%   $Rev:: 3415                                                 $
%   $Author:: PLOCH37                                           $
%   $Date:: 2020-07-14 12:44:31 +0200 (Di, 14. Jul 2020)        $
%   $URL: file:///J:/TG/FCplatform/500_newLDYN_SimPlatform/DIVeLDYN_svn/trunk/ldDevProj/case/c000/Content/ctrl/cpc/Support/v0/CPC/write_silver_par_file.m $


%% Default input
if ~exist('sFile', 'var') || isempty(sFile)
    sFile = 'cpc_cds.txt';
end

if ~exist('sAccess', 'var') || isempty(sAccess)
    sAccess = 'w';
end

if ~exist('sTitle', 'var')
    sTitle = '';
end


%% Write file

% Open file
fileattrib(sFile, '+w') % make file writeable
fid = fopen(sFile, sAccess);
if fid < 0
    error('%s cannot be written', sFile)
end

% Exit function, if no parameter to add
% Consider empty Y or struct Y with no fields
if isempty(Y) || isempty(fieldnames(Y))
    fclose(fid);
    return
end

% Write title / comment
if ~isempty(sTitle)
    sTitleLen = length(sTitle);
    sSeparator = repmat('/', 1, sTitleLen + 6);
    fprintf(fid, '\r\n');
    fprintf(fid, '%s\r\n', sSeparator);
    fprintf(fid, '// %s //\r\n', sTitle);
    fprintf(fid, '%s\r\n', sSeparator);
end

% Write parameter
sPar0 = fieldnames(Y);
for k0 = 1:length(sPar0)
    sP0 = sPar0{k0};
    if isstruct(Y.(sP0))
        sPar1 = fieldnames(Y.(sP0));
        for k1 = 1:length(sPar1)
            sP1 = sPar1{k1};
            if isstruct(Y.(sP0).(sP1))
                error('only 1 substructure supported')
            else
                dValue = Y.(sP0).(sP1);
                sName = [sP0 '.' sP1];
                writeVar(fid, sName, dValue);
            end
        end
    else
        dValue = Y.(sP0);
        sName = sP0;
        writeVar(fid, sName, dValue);
    end
end
fclose(fid);


function writeVar(fid, sName, Data)
row = size(Data, 1);
col = size(Data, 2);
if col == 1 && row == 1
    fprintf(fid, '%s = %g;\r\n', sName, Data);
elseif col > 1 && row == 1
    for c = 1:col
        fprintf(fid, '%s[%d] = %g;\r\n', sName, c-1, Data(c)); % index starts with 0
    end
elseif col > 1 && row > 1
    for c = 1:col
        for r = 1:row
            fprintf(fid, '%s[%d][%d] = %g;\r\n', sName, c-1, r-1, Data(r,c));
        end
    end
else
    error('something is wrong')
end
