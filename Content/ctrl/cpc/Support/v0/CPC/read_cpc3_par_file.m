function data = read_cpc3_par_file(name, flag)

if (nargin < 2) flag = 1; end;

h = fopen(name); % Datei öffnen

l = fgetl(h); % 1. Zeile einlesen

fclose(h); % Datei schließen

if (strncmp(l, 'CANape PAR V3.1: CPC3.a2l 1 0 CPC3', 15))
    data = read_canape_par_file_31(name, flag);
elseif (strncmp(l, 'CANape PAR V3.2: CPC3.a2l 1 0 CPC3', 15))
    data = read_canape_par_file_32(name, flag);
else
    error(sprintf('Error reading %s', name));
end;
