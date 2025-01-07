function [data, datatype] = read_par_file(sFile)
% READ_PAR_FILE read CANape PAR files
% V3.1 and V3.2 supported
%
%
% Syntax:  [data, datatype] = read_par_file(sFile)
%
% Inputs:
%    sFile - [''] file name (String)
%
% Outputs:
%        data - [.] Data
%    datatype - [.] Data type information
%
% Example: 
%    EEP = read_par_file('cpc_eep.par');
%
%
% See also: read_canape_par_file_31, read_canape_par_file_32
%
% Author: PLOCH37
% Date:   16-Mar-2021

% Extend file name by .par extension
if ~strcmp(sFile(end-3:end), '.par')
    sFile = [sFile '.par'];
end

% Read first line
h = fopen(sFile); % open file
l = fgetl(h); % read first line
fclose(h); % close file

% Select PAR Version
switch l(1:15)
    case 'CANape PAR V3.1'
        [data, datatype] = read_canape_par_file_31(sFile);
    case 'CANape PAR V3.2'
        [data, datatype] = read_canape_par_file_32(sFile);
    otherwise
        error('Error reading %s', sFile);
end
