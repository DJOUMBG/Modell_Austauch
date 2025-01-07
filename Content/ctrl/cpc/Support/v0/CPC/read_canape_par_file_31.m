% data = read_canape_par_file_31(name) lädt Parameter aus der Datei name (mit
% CANape CDM-Studio (Version 3.1) gespeichert) und speichert diese in der
% Variable data ab. Dabei werden die SI-Werte und nicht die RWV-Werte
% gespeichert!
%
% Autor: Stefan Goldschmidt, Daimler AG, 24.06.2008
% -------------------------------------------------
% History:
%  2008-06-24   Stefan Goldschmidt, Daimler AG
%               * create
%  2011-05-11   Lars Fersterra, Daimler AG
%               * leer Zeilen ignorieren
% -------------------------------------------------

function [data, datatype] = read_canape_par_file_31(name, flag)

if (nargin < 2); flag = 1; end

% h         Handle der Datei
% l         Puffer für eine Zeile der Datei

% s         Zustand für den Automaten, der eine Zeile scannt
%           0       Start
%           1       Name
%           2       Übergang Name->Info
%           3       Info
%           4       Übergang Info->Wert
%           5       Wert
%           6       Ende

% p         Index für den Automaten, der eine Zeile scannt

h = fopen(name); % Datei öffnen

l = fgetl(h); % Zeile einlesen

if isempty(l); l = ';'; end

% Ignore header line
if strncmp(l, 'CANape PAR', 10)
    l = fgetl(h); % read next line
end

while ischar(l)

    s = 0; % Zustand zurücksetzen
    p = 1; % Index zurücksetzen
    
    % Ignore empty lines or comments
    while isempty(l) || l(1) == ';'
        if ~isempty(l)
            % fprintf('%s\n', l(2:end));
        end
        l = fgetl(h); % read next line
    end

    if ~isempty(l) % prüfe ob Zeile Zeichen enhält
        
        while (s >= 0 && s <= 5) % ... solange kein Fehler vorliegt (s < 0) oder das Ende erreicht wurde (s > 5)

            c = l(p); % character of the current line

            switch s

                case 0 % Start

                    % Name erkannt
                    if isName(c); s = 1;
                    % Fehler
                    else s = -1;
                    end

                case 1 % Name

                    % Name fortsetzen
                    if (isWord(c) || c == '_' || c == '.'); s = 1;
                    % Übergang Name->Info erkannt
                    elseif (c == ' '); s = 2; p_name = p-1;
                    % Fehler
                    else s = -1;
                    end

                case 2 % Übergang Name->Info

                    % Übergang Name->Info fortsetzen
                    if (c == ' '); s = 2;
                    % Info erkannt
                    elseif isInfo(c); s = 3; p_info(1) = p+1;
                    % Fehler
                    else s = -1;
                    end

                case 3 % Info

                    % Info fortsetzen
                    if isInfo(c); s = 3;
                    % Übergang Info->Wert erkannt
                    elseif (c == ' '); s = 4; p_info(2) = p-2;
                    % Fehler
                    else s = -1;
                    end

                case 4 % Übergang Info->Wert

                    % Übergang Info->Wert fortsetzen
                    if (c == ' '); s = 4;
                    % Wert erkannt
                    elseif isNum(c); s = 5; p_wert(1) = p;
                    % Fehler
                    else s = -1;
                    end

                case 5 % Wert

                    % Wert fortsetzen
                    if isNum(c); s = 5;
                    % Ende
                    elseif (c == ' '); s = 6; p_wert(2) = p-1;
                    % Fehler
                    else s = -1;
                    end

                otherwise

                    error('error in line %s at position %d', l, p);

            end

            p = p+1; % Index erhöhen

            if (p > length(l) && s ~= 6); s = -1; end % Fehler bei Überlauf

        end

        if (s == 6) % ... es wurde eine Zeile erfolgreich eingelesen

            name = l(1:p_name);
            info = l(p_info(1):p_info(2));
            wert = l(p_wert(1):p_wert(2));

            if ~isempty(name) ... % ... es liegt ein Name vor
                    && isempty(strfind(name, '._')) % und kann auch in eine Matlab Struktur zugewiesen werden

                % Type(Size) oder Type(Size),(Dimension,Dimension)
                k = strfind(info, ',');

                % Datatype info
                if isempty(k)
                    typ = info; %#ok<NASGU>
                else
                    typ = info(1:k-1); %#ok<NASGU>
                end
                eval(sprintf('datatype.%s = typ;', name));

                if ~isempty(k)

                    % Feld
                    % info could be "UINT(8),(1,5)" but also "FLOAT,(1,5)"
                    m = find(info == '(', 1, 'last');
                    n = find(info == ')', 1, 'last');
                    d = sscanf(info(m:n), '(%d,%d)');
                    % disp(sprintf('%s: %d, %d', name, d(1), d(2)));

                    % Zellen abarbeiten

                    matrix = zeros(d(1), d(2)); % Matrix initialisieren
                    for i = 1:d(1)

                        for j = 1:d(2)

                            if (i == 1 && j == 1)

                                % erstes Element

                                % disp(sprintf('%s(%d, %d) = %s', name, i, j, wert));
                                matrix(i,j) = str2double(wert);

                            else

                                % weiteres Element
                                l = fgetl(h); % Zeile einlesen

                                s = 4; % Zustand zurücksetzen
                                p = 1; % Index zurücksetzen

                                while (s >= 0 && s <= 5) % ... solange kein Fehler vorliegt (s < 0) oder das Ende erreicht wurde (s > 5)

                                    c = l(p); % character of the current line

                                    switch s

                                        case 4 % Übergang Info->Wert

                                            % Übergang Info->Wert fortsetzen
                                            if (c == ':' || c == ' '); s = 4;
                                            % Wert erkannt
                                            elseif isNum(c); s = 5; p_wert(1) = p;
                                            % Fehler
                                            else
                                                fprintf('value (%d,%d) for %s expected\n', i, j, name);
                                                s = -1;
                                            end

                                        case 5 % Wert

                                            % Wert fortsetzen
                                            if isNum(c); s = 5;
                                            % Ende
                                            elseif (c == ' '); s = 6; p_wert(2) = p-1;
                                            % Fehler
                                            else s = -1;
                                            end

                                        otherwise

                                            error('error in line %s at position %d', l, p);

                                    end

                                    p = p+1; % Index erhöhen

                                    if (p > length(l) && s ~= 6); s = -1; end % Fehler bei Überlauf

                                end

                                if (s == 6) % ... es wurde eine Zeile erfolgreich eingelesen

                                    wert = l(p_wert(1):p_wert(2));

                                    % disp(sprintf('%s(%d, %d) = %s', name, i, j, wert));
                                    matrix(i,j) = str2double(wert);

                                else

                                    % Fehler
                                    fprintf('line "%s" skipped\n', l);

                                end

                            end

                        end

                    end

                    % Wert schreiben
                    eval(sprintf('data.%s = matrix;', name));

                else

                    % Einzelwert

                    % disp(sprintf('%s = %s', name, wert));
                    eval(sprintf('data.%s = %s;', name, wert));

                end
                
            else

                % Fehler
                fprintf('line "%s" skipped\n', l);

            end

        else

            % Fehler
            fprintf('line "%s" skipped\n', l);

        end
    else
        % fprintf('Empty line skipped\n');
    end
            
    l = fgetl(h); % Zeile einlesen

end

fclose(h); % Datei schließen


function [b] = isNum(s)
% for example: 1.2e-3
b =(s >= '0' && s <= '9') || s == '.' || s == '-' || s == 'e';

function [b] = isName(s)
b = (s >= 'a' && s <= 'z') || (s >= 'A' && s <= 'Z');

function [b] = isWord(s)
% same as \w, but not considerung underscore '_'
b = isName(s) || (s >= '0' && s <= '9');

function [b] = isInfo(s)
b = isWord(s) || any(s == '[](),');
