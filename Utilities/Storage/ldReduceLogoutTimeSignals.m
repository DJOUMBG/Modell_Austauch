function [xLog, xLogPath] = ldReduceLogoutTimeSignals(hLog)
% LDREDUCELOGOUTTIMESIGNALS reduce time data of logging signals
%  Reduce data of logging signals by merging all time vectors of each
%  signal to a single time vector for all logging signals.
%
%
% Syntax:
%    [xLog, xLogPath] = ldReduceLogoutTimeSignals(hLog)
%
% Inputs:
%    hLog - [*] logout handle (Simulink.SimulationData.Dataset)
%
% Outputs:
%        xLog - [.] logout struct with a single time vector sec
%    xLogPath - [.] information of signal, where signal was logged
%
% Example:
%    logout = ldReduceLogoutTimeSignals(logout);
%    [xLog, xLogPath] = ldReduceLogoutTimeSignals(logout);
%
%
% Author: BHOEFLA, PLOCH37


%% ------------- BEGIN CODE --------------

% Definition of time vector
TIME_VEC = 'sec';

% Init Outputs
xLog = [];
xLogPath = [];

try

    % Check input class
    if isa(hLog, 'Simulink.SimulationData.Dataset')
        % Number of logged signals
        nSig = hLog.numElements;
    else
        % Error for catch statement
        error('Input is not a Simulink.SimulationData.Dataset');
    end

    % Reduce every signals to the size of reference time vector
    for n = 1:nSig

        % Get signal
        hSig        = hLog.getElement(n);
        sSig        = hSig.Name;
        sSigPath    = hSig.BlockPath.getBlock(1);
        dVal        = double(hSig.Values.Data);

        % Use first logged signal time as reference time vector
        if n == 1
            xLog.(TIME_VEC) = hSig.Values.Time;
            size_ref = size(xLog.(TIME_VEC));
        end

        % Assign signal to output struct, if same size as reference time
        size_sig = size(dVal);
        if isequal(size_ref, size_sig)
            % Assign signal to output
            if isfield(xLog, sSig)
                % If signal already exist, prefer output, and skip input,
                % which usually comes from RateTransion Block.
                % These RateTransion Block Name start with RT in DIVeMB
                cBlock = strsplit(sSigPath, '/');
                sBlock = cBlock(end); % Block Name
                if strncmp(sBlock, 'RT', 2)
                    % Skip this logged signal
                    continue
                end
            end
            xLog.(sSig) = dVal;
            xLogPath.(sSig) = sSigPath;
        else
            % Output information about different size
            sSizeRef = sprintf('%dx', size_ref);
            sSizeSig = sprintf('%dx', size_sig);
            sSizeRef(end) = '';
            sSizeSig(end) = '';
            sWarn = 'Signal %s (%s) has different size (%s) than the reference (%s) -> removed from logging.';
            warning(sWarn, sSig, sSigPath, sSizeSig, sSizeRef)
        end

    end

catch ME

    % Output = Input
    xLog = hLog;
    fprintf(2, '%s \n', ME.message);

end


%% Log Memory Usage, CPC time, ... into file
try %#ok<TRYNC>

    % Get Process ID
    pid = feature('getpid');

    % Log with Powershell
    system(['powershell -command "Get-Process -id ', num2str(pid),' | Out-File -FilePath .\WS_usedRAM.txt"']);

end


try
[~,resultFile,~] = fileparts(pwd);
fileID = fopen(fullfile('\\s019mf01neta001-v-nas1.emea.tru.corpintra.net\flv','\500_Projects\08_DIVE_RESULTS\results2copy',[resultFile,'.txt']), 'w');
fprintf(fileID, strrep(pwd,'\','/'));
fclose(fileID);
end

try
[~,resultFile,~] = fileparts(pwd);
fileID = fopen(fullfile('\\emea.corpdir.net\e019\PRJ\TG\LDYNtools\888_results2copy',[resultFile,'.txt']), 'w');
fprintf(fileID, strrep(pwd,'\','/'));
fclose(fileID);
end