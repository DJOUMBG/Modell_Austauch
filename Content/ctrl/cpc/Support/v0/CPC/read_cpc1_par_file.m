% data = read_cpc1_par_file(name) l‰dt Parameter aus der Datei name (mit
% VDODiag gespeichert) und speichert diese in der Variable data ab. Dabei
% werden die SI-Werte und nicht die RWV-Werte gespeichert!
%
% Autor: Stefan Goldschmidt, Daimler AG, 30.06.2008

function data = read_cpc1_par_file(name, flag)

if (nargin < 2) flag = 1; end;

% h         Handle der Datei
% l         Puffer f¸r eine Zeile der Datei

% s         Zustand f¸r den Automaten, der eine Zeile scannt
%           0       Start
%           1       Name
%           2       Erg‰nzung
%           3       =
%           4       Wert
%           5       Ende

% p         Index f¸r den Automaten, der eine Zeile scannt

h = fopen(name); % Datei ˆffnen

l = fgetl(h); % Zeile einlesen

while (ischar(l))

    s = 0; % Zustand zur¸cksetzen
    p = 1; % Index zur¸cksetzen

    while (s >= 0 & s <= 4) % ... solange kein Fehler vorliegt (s < 0) oder das Ende erreicht wurde (s > 5)

        switch (s)

            case 0 % Start

                % Name erkannt
                if ((l(p) >= 'a' & l(p) <= 'z') | (l(p) >= 'A' & l(p) <= 'Z')) s = 1;
                % Fehler
                else s = -1;
                end;

            case 1 % Name

                % Name frotsetzen
                if ((l(p) >= 'a' & l(p) <= 'z') | (l(p) >= 'A' & l(p) <= 'Z') | (l(p) >= '0' & l(p) <= '9') | l(p) == '_' | l(p) == '.' | l(p) == '[' | l(p) == ']') s = 1;
                % Erg‰nzung erkannt
                elseif (l(p) == ' ') s = 2; p_name = p-1;
                % = erkannt
                elseif (l(p) == '=') s = 3; p_name = p-1;
                % Fehler
                else s = -1;
                end;

            case 2 % Erg‰nzung

                % Erg‰nzung frotsetzen
                if ((l(p) >= 'a' & l(p) <= 'z') | (l(p) >= 'A' & l(p) <= 'Z') | (l(p) >= '0' & l(p) <= '9') | l(p) == '_' | l(p) == '.' | l(p) == '[' | l(p) == ']' | l(p) == '(' | l(p) == ')' | l(p) == ',') s = 2;
                % = erkannt
                elseif (l(p) == '=') s = 3;
                % Fehler
                else s = -1;
                end;

            case 3 % =

                % Wert erkannt
                if ((l(p) >= '0' & l(p) <= '9') | l(p) == '.' | l(p) == '-') s = 4; p_wert = p;
                % Fehler
                else s = -1;
                end;

            case 4 % Wert

                % Wert fortsetzen
                if ((l(p) >= '0' & l(p) <= '9') | l(p) == '.' | l(p) == '-') s = 4;
                % Fehler
                else s = -1;
                end;

            otherwise

                error(sprintf('error in line %s at position %d', l, p));

        end;
    
        p = p+1; % Index erhˆhen

        if (p > length(l))

            if (s ~= 4) s = -1; % Fehler bei ‹berlauf
            else s = 5; % Ende
            end;

        end;

    end;

    if (s == 5) % ... es wurde eine Zeile erfolgreich eingelesen

        name = l(1:p_name);
        wert = l(p_wert:end);

        if (~isempty(name)) % ... es liegt ein Name vor

            % Skalar oder Feld
            m = strfind(name, '[');
            n = strfind(name, ']');

            if (length(m) == 1 & length(n) == 1)

                % Feld

                name = sprintf('%s(%s+1)', name(1:m-1), name(m+1:n-1));

                eval(sprintf('data.%s = %s;', name, wert));

            elseif (length(m) == 0 & length(n) == 0)

                % Einzelwert

                eval(sprintf('data.%s = %s;', name, wert));

            else

                % Fehler

                disp(sprintf('line "%s" skipped', l));

            end;

        else

            % Fehler

            disp(sprintf('line "%s" skipped', l));

        end;

    else

        % Fehler

        disp(sprintf('line "%s" skipped', l));

    end;

	l = fgetl(h); % Zeile einlesen

end;

fclose(h); % Datei schlieﬂen
