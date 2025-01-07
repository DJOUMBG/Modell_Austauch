% Erzeugt CDI-Put-Blöcke im Subsystem sys. Das Subsystem sys muss bereits
% existieren. Ausgangspunkt ist die Struktur data. Sie enthält die PID's
% als Elemente. Zum Beispiel:
%
% data.ptconf_p_Trans
% data.ptcong_p_Axle
%
% Unterhalb der PID's befinden sich die einzelnen Variablen. Zum Beispiel:
%
% data.ptconf_p_Trans.GearRatio_s16
% data.ptconf_p_Trans.GearFricEff_u8
%
% Mit PID wird die PID in data spezifiziert, für dessen Variablen
% CDI-Put-Blöcke erzeugt werden. Die CDI-Put-Blöcke werden von
% Constant-Blöcken versorgt, die die Werte liefern. Als Wert wird eine
% Variable eingetregen. Für die Größe GearRatio_s16 in der PID
% ptconf_p_Trans hat sie zum Beispiel die Form:
%
% name.ptconf_p_Trans.GearRatio_s16
%
% name wird als Parameter übergeben.

function position = create_cpc3_par_subsystem(sys, PID, data, name, position)

% Get all possible cpc parameters and signals, skip other
xCDI = fcGetCDI('c'); 
sParPossible = [{xCDI.Name}]';
sPar = fieldnames(data.(PID));
for k = 1:length(sPar)
    s = sPar{k};
    % Check if the parameter exist
    if ~any(strcmp(s, sParPossible))
        fprintf('Skip %s\n', s);
        data.(PID) = rmfield(data.(PID), s);
    end
end


% Prüft, ob PID in data enthalten ist
if (isfield(data, PID))

    % PID ist in data vorhanden

    % Holt alle Elemente der PID
    Parameter_list = fieldnames(eval(['data.', PID]));

    % Ein Cell-Array wird sichergestellt
    if (~iscell(Parameter_list)) Parameter_list = {Parameter_list}; end;

    % Eine Signalliste für einen CDI-Block beginnt mit einem '{'
    Signals = '{';

    % Portzähler wird mit 1 initialisiert
    Port = 1;

    % Es werden alle Elemente der PID behandelt
    for i = 1:length(Parameter_list)

        % Prüft, ob es sich bei dem Element um ein Free-Elemente handelt
        if (~strncmp(Parameter_list{i}, 'Free', 4))

            % Es ist kein Free-Element

            % Die Signalliste für den CDI-Block wird ergänzt
            if (Port == 1) Signals = [Signals, '''', Parameter_list{i}, '''']; % Es ist das erste Element (ohne vorangestelltem Komma)
            else Signals = [Signals, ',''', Parameter_list{i}, '''']; end; % Es ist ein weiteres Element (mit vorangestelltem Komma)

            % Portzähler wird erhöht
            Port = Port+1;

        end;

    end;

    % Eine Signalliste für einen CDI-Block endet mit einem '{'
    Signals = [Signals, '}'];

    % CDI-Put-Block wird hinzugefügt
    add_block('CDI_lib/CDI_Put', [sys, '/CDI_Put ', PID], 'Signals', Signals, 'AllRights', 'on', 'DoCheck', 'off', 'Position', [position(1)+450 position(2) position(1)+450+360 position(2)+(Port-1)*30]);

    % Portzähler wird mit 1 initialisiert
    Port = 1;

    % Es werden alle Elemente der PID behandelt
    for i = 1:length(Parameter_list)

        % Prüft, ob es sich bei dem Element um ein Free-Elemente handelt
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
                otherwise, error('Type of %s is unknown', Parameter_list{i});
            end;

            % Constant-Block wird hinzugefügt
            % Es wird der SI-Datentyp gesetzt
            % Es wird der Wert gesetzt
            add_block('Simulink/Sources/Constant', [sys, '/Constant ', PID, '_', Parameter_list{i}], 'OutDataTypeStr', Type, 'Value', [name, '.', PID, '.', Parameter_list{i}], 'SampleTime', '-1', 'Position', [position(1) position(2)+(Port-1)*30 position(1)+180 position(2)+(Port-1)*30+30], 'ShowName', 'off');

            % Datatype-Conversion-Block wird hinzugefügt
            % Der Datentyp vird vom CDI-Put-Block übernommen
            % Der SI-Wert wird beibehalten
            add_block('Simulink/Signal Attributes/Data Type Conversion', [sys, '/Data Type Conversion ', PID, '_', Parameter_list{i}], 'OutDataTypeStr', 'Inherit: Inherit via back propagation', 'ConvertRealWorld', 'Stored Integer (SI)', 'Position', [position(1)+270 position(2)+(Port-1)*30 position(1)+270+90 position(2)+(Port-1)*30+30], 'ShowName', 'off');

            % Constant-Block wird mit Datatype-Conversion-Block verbunden
            add_line(sys, ['Constant ', PID, '_', Parameter_list{i}, '/1'], ['Data Type Conversion ', PID, '_', Parameter_list{i}, '/1']);

            % Datatype-Conversion-Block wird mit CDI-Put-Block verbunden
            add_line(sys, ['Data Type Conversion ', PID, '_', Parameter_list{i}, '/1'], ['CDI_Put ', PID, '/', int2str(Port)])

            % Portzähler wird erhöht
            Port = Port+1;

        end;

    end;
    
    position(2) = position(2)+(Port-1)*30+60;

else

    % PID ist in data nicht vorhanden

    error('PID %s is not part of the data structure');

end;
