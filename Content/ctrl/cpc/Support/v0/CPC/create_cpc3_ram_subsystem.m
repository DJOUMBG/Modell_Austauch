% Erzeugt CDI-Put-Bl�cke im Subsystem sys. Das Subsystem sys muss bereits
% existieren. Ausgangspunkt ist die Struktur data. Sie enth�lt die Module
% als Elemente. Zum Beispiel:
%
% data.cal
% data.itpm
%
% Unterhalb der Module befinden sich die einzelnen Variablen. Zum Beispiel:
%
% data.cal.cal_o_AgAccelDemandFactorKickdown_s16
% data.cal.cal_o_AgAccelDemandFactorPower_s16
%
% Mit MOD wird das Modul in data spezifiziert, f�r dessen Variablen
% CDI-Put-Bl�cke erzeugt werden. Die CDI-Put-Bl�cke werden von
% Constant-Bl�cken versorgt, die die Werte liefern. Als Wert wird eine
% Variable eingetregen. F�r die Gr��e cal_o_AgAccelDemandFactorKickdown_s16
% im Modul cal hat sie zum Beispiel die Form:
%
% name.cal.cal_o_AgAccelDemandFactorKickdown_s16
%
% name wird als Parameter �bergeben.

function create_ram_subsystem(sys, MOD, data, name)

% Pr�ft, ob MOD in data enthalten ist
if (isfield(data, MOD))

    % MOD ist in data vorhanden

    % Holt alle Elemente von MOD
    Parameter_list = fieldnames(eval(['data.', MOD]));

    % Ein Cell-Array wird sichergestellt
    if (~iscell(Parameter_list)) Parameter_list = {Parameter_list}; end;

    % Eine Signalliste f�r einen CDI-Block beginnt mit einem '{'
    Signals = '{';

    % Portz�hler wird mit 1 initialisiert
    Port = 1;

    % Es werden alle Elemente von MOD behandelt
    for i = 1:length(Parameter_list)

        % Pr�ft, ob es sich bei dem Element um ein Free-Elemente handelt
        if (~strncmp(Parameter_list{i}, 'Free', 4))

            % Es ist kein Free-Element

            % Die Signalliste f�r den CDI-Block wird erg�nzt
            if (Port == 1) Signals = [Signals, '''', Parameter_list{i}, '''']; % Es ist das erste Element (ohne vorangestelltem Komma)
            else Signals = [Signals, ',''', Parameter_list{i}, '''']; end; % Es ist ein weiteres Element (mit vorangestelltem Komma)

            % Portz�hler wird erh�ht
            Port = Port +1;

        end;

    end;

    % Eine Signalliste f�r einen CDI-Block endet mit einem '{'
    Signals = [Signals, '}'];

    % CDI-Put-Block wird hinzugef�gt
    add_block('CDI_lib/CDI_Put', [sys, '/CDI_Put ', MOD], 'Signals', Signals, 'AllRights', 'on', 'DoCheck', 'off');

    % Portz�hler wird mit 1 initialisiert
    Port = 1;

    % Es werden alle Elemente von MOD behandelt
    for i = 1:length(Parameter_list)

        % Pr�ft, ob es sich bei dem Element um ein Free-Elemente handelt
        if (~strncmp(Parameter_list{i}, 'Free', 4))

            % Es ist kein Free-Element

            % Sucht den Datentyp im Signal
            j = strfind(Parameter_list{i}, '_');

            % Behandelt den Datentyp im Signal
            switch (Parameter_list{i}(max(j)+1:end))
                case 'u1', Type = 'uint8';
                case 'u2', Type = 'uint8';
                case 'u4', Type = 'uint8';
                case 'u8', Type = 'uint8';
                case 's8', Type = 'int8';
                case 'u16', Type = 'uint16';
                case 's16', Type = 'int16';
                case 'u32', Type = 'uint32';
                case 's32', Type = 'int32';
                otherwise, error(sprintf('Type of %s is unknown', Parameter_list{i}));
            end;
            
            % Constant-Block wird hinzugef�gt
            % Es wird der SI-Datentyp gesetzt
            % Es wird der Wert gesetzt
            add_block('Simulink/Sources/Constant', [sys, '/Constant ', MOD, '_', Parameter_list{i}], 'OutDataTypeMode', Type, 'OutputDataTypeScalingMode', Type, 'Value', [name, '.', MOD, '.', Parameter_list{i}], 'SampleTime', '-1');

            % Datatype-Conversion-Block wird hinzugef�gt
            % Der Datentyp vird vom CDI-Put-Block �bernommen
            % Der SI-Wert wird beibehalten
            add_block('Simulink/Signal Attributes/Data Type Conversion', [sys, '/Data Type Conversion ', MOD, '_', Parameter_list{i}], 'OutDataTypeMode', 'Inherit via back propagation', 'ConvertRealWorld', 'Stored Integer (SI)');

            % Constant-Block wird mit Datatype-Conversion-Block verbunden
            add_line(sys, ['Constant ', MOD, '_', Parameter_list{i}, '/1'], ['Data Type Conversion ', MOD, '_', Parameter_list{i}, '/1']);

            % Datatype-Conversion-Block wird mit CDI-Put-Block verbunden
            add_line(sys, ['Data Type Conversion ', MOD, '_', Parameter_list{i}, '/1'], ['CDI_Put ', MOD, '/', int2str(Port)])

            % Portz�hler wird erh�ht
            Port = Port+1;

        end;

    end;

else

    % MOD ist in data nicht vorhanden

    error('MOD %s is not part of the data structure');

end;
