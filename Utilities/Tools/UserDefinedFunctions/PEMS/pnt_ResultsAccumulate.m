function [sFilename]= pnt_ResultsAccumulate(sPath)
%pnt_ResultsAccumulate Takes the path of a DIVe result folder as path and
% accumulates all signals into a single file having time series format and
% returns the complete name of the file created as O/p argument
%
% Syntax:
%   [sFilename]= pnt_ResultsAccumulate(sPath)
%
%
% Inputs:
%       sPath - String with path of the DIVe result
%
% Outputs:
%       sFilename - String with complete path of the Result file with ext
%
% Example:
%   [sFilename]= pnt_ResultsAccumulate('D:\Results')
%
% See also:  uniread,dirPattern,isvarname 
%
% Author: Ajesh Chandran, TT/S43 DTICI
%  Phone: +91-80-6149-6368
% MailTo: ajesh.chandran@daimlertruck.com
%   Date: 2020-02-19

%% Checking for the basic files
cWsMatfile = dirPattern(sPath,'WS*.mat','file'); % Getting the name of the WS matfile
if isempty(cWsMatfile)
    fprintf('WS mat file not found Please check the folder\n'); % Error Message
    return; % End the evaluation
end
cMvafile = dirPattern(sPath,'MVA_collectAll.mat','file'); % Getting the name of the MVA_collectAll file
if isempty(cMvafile)
    fprintf('MVA Collect all file missing. Please check the folder\n'); % Error Message
    return; % End the evaluation
end
cMcmsilverrawfile = dirPattern(sPath,'mcm_silver_raw.txt','file'); % Getting the name of the mcm silver raw
if isempty(cMcmsilverrawfile)
    fprintf('mcm silver raw file missing. Please check the folder\n'); % Error Message
    return; % End the evaluation
end

%% Reading the data
MpxSources = uniread(fullfile(sPath,cWsMatfile)); % Reading the contents to structure format

for nIdx = 1:length(MpxSources.subset) % The loop to iterate through different subsets
    nChannel = length(MpxSources.subset(1,nIdx).data.name);
    for nIdx2 = 1:nChannel % The loop to iterate through the different variables in a subset
        
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'[')
            %Correction for channel name with special character
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'[','_');
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},']','_');
        end
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'(')
            %Correction for channel name with special character
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'(','_');
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},')','_');
        end
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'~')
            %Correction for channel name with special character
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'~','_');
        end
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},' ')
            %Correction for channel name with special character
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},' ','_');
        end
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'/')
            %Correction for channel name with special character
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'/','_');
        end
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'=')
            %Correction for channel name with special character
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'=','_');
        end
        if ~isempty(strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2}(1),'_'))...
                %Correction for channel name with first character as _
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = MpxSources.subset(1,nIdx).data.name{1,nIdx2}(2:end);
        end
        
    end
end
clearvars nIdx nIdx2 nChannel % Clearing the varibles used for data extraction

%% Converting the Structure to time series format

fprintf('Converting the structure to time series format\n'); % Message update
for nIdx = 1:length(MpxSources.subset)
    
    % Reading the data
    n_channels = length(MpxSources.subset(1,nIdx).data.name);
    for nIdx2 = 1:n_channels
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'[')
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'[','_');
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},']','_');
        end
        if strfind(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'-')
            MpxSources.subset(1,nIdx).data.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).data.name{1,nIdx2},'-','_');
        end
        if isvarname([MpxSources.subset(1,nIdx).data.name{1,nIdx2}]) % to exclude variable starting with number
            eval([MpxSources.subset(1,nIdx).data.name{1,nIdx2},' = MpxSources.subset(1,nIdx).data.value(:,nIdx2);']);
        else
            %disp([MpxSources.subset(1,nIdx).data.name{1,nIdx2}])
        end
    end
    % Reading the attributes
    n_channels = length(MpxSources.subset(1,nIdx).attribute.name);
    for nIdx2 = 1:n_channels
        if strfind(MpxSources.subset(1,nIdx).attribute.name{1,nIdx2},'[')
            MpxSources.subset(1,nIdx).attribute.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).attribute.name{1,nIdx2},'[','_');
            MpxSources.subset(1,nIdx).attribute.name{1,nIdx2} = strrep(MpxSources.subset(1,nIdx).attribute.name{1,nIdx2},']','_');
        end
        eval([MpxSources.subset(1,nIdx).attribute.name{1,nIdx2},' = MpxSources.subset(1,nIdx).attribute.value(:,nIdx2);'])
    end
    
end
clearvars nIdx nIdx2 nChannel % Clearing the varibles used for data extraction

%% Extracting other informations from the sMP structure for calculation

sBuild = CVPROG{1}(4:5); % Getting the build name from configuration
load(fullfile(sPath,cWsMatfile{1}),'sMP'); % For getting the configuration parameters
cDBCmodules = cell(0);
cDBCmodules = [cDBCmodules sMP.cfg.Configuration.ModuleSetup(:).name];    % Cell of DBC modules names
bStatus = cellfun(@(x) strcmp(x,'eng1'),cDBCmodules); % Checking for eng module
if ~sum(bStatus)
    bStatus = cellfun(@(x) strcmp(x,'eng'),cDBCmodules); % Checking for eng module
end
nIndex = find(bStatus);   % Finding the index of eng module in the array
cDBCmodules = cell(0); % Resetting the DBC modules cell
cDBCmodules = [cDBCmodules sMP.cfg.Configuration.ModuleSetup(nIndex).DataSet(:).className]; % Adding the Eng module datasets
bStatus = cellfun(@(x) strcmp(x,'mainData'),cDBCmodules);% Check for mainData
nIndex2 = find(bStatus);% Obtaining location of mainData
sEngName = sMP.cfg.Configuration.ModuleSetup(nIndex).DataSet(nIndex2).variant; % Getting the Engine name
if(strfind(sEngName,'_pulse')) % renaming _pulse engine name to normal name
    sEngName = sEngName(1:(strfind(sEngName,'_pulse')-1));
end
fprintf('\n Engine:  %s\n',sEngName); % Display Message

nPowerRating = sMP.ctrl.mcm.sys_can_performance_class_1m;  % Getting the Power rating
nCylinder = sMP.ctrl.mcm.sys_cylinder_value_1m; % Getting the number of cylinders for work calculation
nEngMaxTorque = sMP.ctrl.mcm.sys_max_eng_trq_1m; % Getting the max engine torque
%% Adjusting the sampling time to 1 Hz
nSampleTime = time(end)-time(end-1); % Getting the sample time of mcm_silver_raw signals
if (numel(is1_eng_speed) ~= numel(NMOTW)) % is1_eng_speed is a basic sig in mcm and NMOTW is basic in MVA
    fprintf('Sampling time of MVA and mcm logging differs Please cross check\n'); % Error Message
    fprintf('Stopping the Evaluation\n'); % Error Message
    return
end
if (numel(NMOTW) ~= numel(mec_veh_transPos))%  NMOTW is basic sig in MVA and eng_mdot_air is basic in platform
    fprintf('Sampling time of MVA and Platform differs Please cross check\n'); % Error Message
    fprintf('Stopping the Evaluation\n'); % Error Message
    return
end
sFrequency = num2str(1/nSampleTime); % Defining the frequency for sampling
if nSampleTime~=1
    fprintf('Resampling to 1 Hz\n'); % Update Message
end
xVar = whos; % Getting the workspace variables
bKeep = strcmp('double',{xVar.class}) & cellfun(@(x)min(x)==1&&max(x)~=1,{xVar.size}); % Selecting only double with length more than 1
xVarDel = xVar(~bKeep); % List of variables to be deleted
xVar = xVar(bKeep); % Only double variables
for nIdxVar = 1:numel(xVar)
    eval([xVar(nIdxVar).name,'=',xVar(nIdxVar).name,'(1:',sFrequency,':end);']);% Desampling
end

%% Saving the output

sOutputFileName = fullfile(sPath,['B',sBuild,cWsMatfile{1}(16:end-4),'.mat']);
save(sOutputFileName,'-regexp', '^(?!(MpxSources|sBuild|sOutputFileName)$).');
sFilename = sOutputFileName; % Returning the complete path of the processed file

end