function CreateCANapeParFile(FileName, Parameter, ECU, Mode, ParType)
% CREATECANAPEPARFILE Create .par file
% Diese Funktion erstellt die CANape-Parameterdatei FileName und legt die
% in der Struktur Parameter definierten Parameter darin ab. ECU gibt den
% Namen des Steuergerätes an. Zum Beispiel 'IPPC'. Mit Mode kann angegeben
% werden, ob ein EEP- (0) oder ein CDS-Abzug (1) erstellt werden soll.
%
% Syntax:  CreateCANapeParFile(FileName, Parameter, ECU, Mode, ParType)
%
% Inputs:
%     FileName - [''] File name and location
%    Parameter - [.] Parameter Structure
%          ECU - [''] Name of ECU
%         Mode - [0,1] 0: EEP, 1:CDS (optional)
%      ParType - [.] Parametertype info (optional), for example 'INT(16)'
%
% Outputs:
%     -
%
% Example: 
%    CreateCANapeParFile(['..\Data\Production\ippc_eeprom_' lower(Identifier) '_canape.par'], IPPC_EEP, 'IPPC');
%
%
% Subfunctions: CreateCANapeParFileCAL, CreateCANapeParFileEEP, getType, writeVar

if ~exist('Mode', 'var')
    Mode = 0;
end

if ~exist('ParType', 'var')
    ParType = [];
end


h = fopen(FileName, 'w');
fprintf(h, 'CANape PAR V3.2: %s.a2l 1 0 %s\r\n', ECU, ECU);
switch Mode
    case 1
        CreateCANapeParFileCAL(h, Parameter, ParType);
    otherwise
        CreateCANapeParFileEEP(h, Parameter, ParType);
end
fclose(h);


function CreateCANapeParFileEEP(h, Parameter, ParType)
PIDs = fieldnames(Parameter);
for k = 1:length(PIDs)
    if isstruct(Parameter.(PIDs{k}))
        Elements = fieldnames(Parameter.(PIDs{k}));
        for n = 1:length(Elements)
            Data = Parameter.(PIDs{k}).(Elements{n});
            Variable = [PIDs{k} '.' Elements{n}];
            if ~isempty(ParType)
                try 
                    DataType = ParType.(PIDs{k}).(Elements{n});
                catch
                    % Parameter could be new and not defined in the source par file
                    DataType = '';
                end
            else
                DataType = '';
            end
            writeVar(h, Data, Variable, DataType)
        end
    else
        % fprintf(2, '%s not a PID, writing anyway\n', PIDs{k});
        Data = Parameter.(PIDs{k});
        Variable = PIDs{k};
        if ~isempty(ParType)
            try
                DataType = ParType.(PIDs{k});
            catch
                % Parameter could be new and not defined in the source par file
                DataType = '';
            end
        else
            DataType = '';
        end
        writeVar(h, Data, Variable, DataType)
    end
end


function CreateCANapeParFileCAL(h, Parameter, ParType)
Elements = fieldnames(Parameter);
for k = 1:length(Elements)
    Data = Parameter.(Elements{k});
    if ~isempty(ParType)
        DataType = ParType.(Elements{k});
    else
        DataType = '';
    end
    Variable = Elements{k};
    writeVar(h, Data, Variable, DataType)
end


function [sType] = getType(Variable, sTypeIn)
l = max(strfind(Variable, '_'));
Type = Variable(l+1:end);
switch Type
    case {'u1', 'u2', 'u4', 'u8'}
        sType = 'UINT(8)';
    case 's8'
        sType = 'INT(8)';
    case 'u16'
        sType = 'UINT(16)';
    case 's16'
        sType = 'INT(16)';
    case 'u32'
        sType=  'UINT(32)';
    case 's32'
        sType =  'INT(32)';
    otherwise
        sType = 'UNKNOWN';
        
        if ~exist('sTypeIn', 'var') 
            error('Invalid type of %s!', Variable);
        end
        
end

% Check variable type
if exist('sTypeIn', 'var') && ~strcmp(sType, 'UNKNOWN') && ~strcmp(sType, sTypeIn)
    fprintf('Type of %s should be %s, but is %s\n', Variable, sType, sTypeIn)
end


function writeVar(h, Data, Variable, Type)
if ~exist('Type', 'var') || isempty(Type)
    % Get the Variable type
    Type = getType(Variable);
else
    % Just check the type
    % getType(Variable, Type);
end

Variable = [Variable ' [' Type];
if ((size(Data, 1) == 1) && (size(Data, 2) == 1))
    Variable = [Variable ']'];
    Variable = [Variable ' ' num2str(Data) ' ;\r\n'];
    fprintf(h, Variable);
else
    Variable = [Variable ',(' num2str(size(Data, 1)) ',' num2str(size(Data, 2)) ')]'];
    Variable = [Variable '\r\n'];
    fprintf(h, Variable);
    for n = 1:size(Data, 1)
        for m = 1:size(Data, 2)
            Variable = [': ' num2str(Data(n, m)) ' ;\r\n'];
            fprintf(h, Variable);
        end
    end
end