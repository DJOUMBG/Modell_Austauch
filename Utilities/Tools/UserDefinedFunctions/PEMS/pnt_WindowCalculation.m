function [xReturn] = pnt_WindowCalculation(sPathFull)
%pnt_WindowCalculation takes the required inputs in the form of matfile and
%calculates the window NOx. Plot of Window NOx and Power is made by NOX
%Calculator and It returns a structure containg the vectors for window NOX
%calculation
%pnt_WindowCalculation
% Syntax:
%   pnt_WindowCalculation(sPathFull)
%
% Inputs:
%         sPathFull  : Full path including extension of the input
%                      mat file from pnt_NoxCalculation function
%
% Outputs:
%
%           xReturn  : Structre containing the vectors used for Window NOx
%                      calculation
% Example:
%      pnt_NoxCalculation('D:\DIVeMB\01DIVeMB0045c00\tmp\NOx_Calc\xPassFuntionfile.mat')
%               Author: Ajesh Chandran, RDI/TBP, MBRDI
%                Phone: +91-80-6149-6368
%               MailTo: ajesh.chandran@daimler.com
%    Date of Creation : 2019-10-18
% Date of Modification:
%  Userid Modification:
% Modification Content:

%Unwrapping the structure contents
load(sPathFull); % Loading the required parameters and Data
% Calculation for updating the excel
xReturn.nT9VMinWindow=min(dT9V1Hz(dTwa1Hz>nCoolantTempMin|dTime1Hz>nTimeMin));
xReturn.nT9VMeanWindow=mean(dT9V1Hz(dTwa1Hz>nCoolantTempMin|dTime1Hz>nTimeMin));
xReturn.nT7VMeanWindow=mean(dT7V1Hz(dTwa1Hz>nCoolantTempMin|dTime1Hz>nTimeMin));
xReturn.nT7NMeanWindow=mean(dT7N1Hz(dTwa1Hz>nCoolantTempMin|dTime1Hz>nTimeMin));
xReturn.nT9NMeanWindow=mean(dT9N1Hz(dTwa1Hz>nCoolantTempMin|dTime1Hz>nTimeMin));


%Pre allocation for saving memory
dPowerCumulative=zeros(length(dTime1Hz),1);
dWorkCumulative=zeros(length(dTime1Hz),1);
dNoxCumulative=zeros(length(dTime1Hz),1);
dVehSpeedCumulative =zeros(length(dTime1Hz),1);
dT9N1HzCumulative=zeros(length(dTime1Hz),1);
dWorkRequired=zeros(length(dTime1Hz),1);
dConditionMet = zeros(length(dTime1Hz),1);
dConditionCase = zeros(length(dTime1Hz),1);
dWorkInstant = zeros(length(dTime1Hz),1);
dPowerInstant = zeros(length(dTime1Hz),1);

%% NOx Calculation Formulas
for nIdx=1:length(dTime1Hz)
    
    if(nIdx~=1)
        if(dTwa1Hz(nIdx)>=nCoolantTempMin||dTime1Hz(nIdx)>nTimeMin||dConditionMet(nIdx-1,1)==1)
            dConditionMet(nIdx,1) = 1; %Sample not valid for Work calculation
        else
            dConditionMet(nIdx,1) =0; % Work should not be calculated for this sample
        end
    else % For the first instant
        %         if(dTwa1Hz(nIdx)>=nCoolantTempMin||dTime1Hz(nIdx)>nTimeMin)
        %             dConditionMet(nIdx,1) = 1; %Sample not valid for Work calculation
        %         else
        % this part has been commented since the first value coming from DIVE is 90
        % degree C
        dConditionMet(nIdx,1) =0; % Work should not be calculated for this sample
        %         end
    end
    
    if(nIdx~=1)
        if(dConditionMet(nIdx,1)==0)
            dConditionCase(nIdx,1) = 4; % Niether time nor temperature cond satisfied
        elseif(dTwa1Hz(nIdx)>=nCoolantTempMin&&dTime1Hz(nIdx)>nTimeMin)
            dConditionCase(nIdx,1) = 3; % Both conditions met
        elseif((dTime1Hz(nIdx)<nTimeMin&&dTwa1Hz(nIdx)>=nCoolantTempMin)||dConditionCase(nIdx-1,1)==2)
            dConditionCase(nIdx,1) = 2; % Coolant temp cond satisfied either now or earlier
        else
            dConditionCase(nIdx,1) = 1; % Time condition met
        end
    else % For the first sample
        if(dConditionMet(nIdx,1)==0)
            dConditionCase(nIdx,1) = 4; % Niether time nor temperature cond satisfied
        elseif(dTwa1Hz(nIdx)>=nCoolantTempMin&&dTime1Hz(nIdx)>nTimeMin)
            dConditionCase(nIdx,1) = 3; % Both conditions met
        elseif(dTime1Hz(nIdx)<nTimeMin&&dTwa1Hz(nIdx)>=nCoolantTempMin)
            dConditionCase(nIdx,1) = 2; % Coolant temp cond satisfied either now or earlier
        else
            dConditionCase(nIdx,1) = 1; % Time condition met
        end
    end
    dPowerInstant(nIdx,1)=(2*pi*dNmotw1Hz(nIdx,1)*dMeffw1Hz(nIdx,1))/(1000*60); % Instantaneous Power Calculation P=2piNT/6000 in kW
    dPowerInstant(nIdx,1)=(dPowerInstant(nIdx,1)+abs(dPowerInstant(nIdx,1)))/2; % For Converting negative values to Zero
    if(dPowerInstant(nIdx,1)>0)
        dNOxgkwh(nIdx,1) = dMnoxhn1Hz(nIdx,1)/dPowerInstant(nIdx,1); % Instantaneous NOx in g/kWh
    else
        dNOxgkwh(nIdx,1) = 0; % % Division by zero exclusion
    end
    if(nIdx~=1)
        if(dConditionMet(nIdx,1)==0)
            dPowerCumulative(nIdx,1)=0; % Whenever the conditions are not satisfied resetting will happen for cumulative NOx calculation
        else
            dPowerCumulative(nIdx,1)=dPowerCumulative(nIdx-1,1)+dPowerInstant(nIdx,1); %Cumulative value of Power in kW
        end
    end
    dWorkInstant(nIdx,1)=(2*pi*dNmotw1Hz(nIdx,1)*dMeffw1Hz(nIdx,1))/(1000*60*3600); % Instantaneous Work Calculation P=2piNT/(6000*3600) in kWh
    dWorkInstant(nIdx,1)=(dWorkInstant(nIdx,1)+abs(dWorkInstant(nIdx,1)))/2; % For Converting negative values to Zero
    if(nIdx~=1)
        if(dConditionMet(nIdx,1)==0)
            dWorkCumulative(nIdx,1)=0;% if condition are not met reset will happen for cumulative work calculation
        else
            dWorkCumulative(nIdx,1)=dWorkCumulative(nIdx-1,1)+dWorkInstant(nIdx,1); %Cumulative value of work in kWh
        end
    end
    dWorkRequired(nIdx,1)=dWorkCumulative(nIdx,1)-nWhtcWork; %Difference between hot WHTC work and Cumulative work in kWh
    
    if(nIdx~=1)
        if(dConditionMet(nIdx,1)==0)
            dNoxCumulative(nIdx,1)=dNoxCumulative(nIdx-1,1);% condition not met for work calculation
            dVehSpeedCumulative(nIdx,1)=dVehSpeedCumulative(nIdx-1,1);% condition not met for work calculation
            dT9N1HzCumulative(nIdx,1) = dT9N1HzCumulative(nIdx-1,1);
        else
            dNoxCumulative(nIdx,1)=dNoxCumulative(nIdx-1,1)+dMnoxhn1Hz(nIdx,1); %Cumulative value of Nox in g/h
            dVehSpeedCumulative(nIdx,1)=dVehSpeedCumulative(nIdx-1,1)+dVehSpeed(nIdx,1);% Cumulative value of Veh speed in m/s
            dT9N1HzCumulative(nIdx,1) = dT9N1HzCumulative(nIdx-1,1)+dT9N1Hz(nIdx,1);
        end
    end
end

%% Window Calculation Starts
% Initialising the window variables
dWindowStart = nan(length(dTime1Hz),1); % Start of the window
dWindowEnd = dTime1Hz; % At each sample the window end is the sample itself
dWindowSize = nan(length(dTime1Hz),1); % Window size is difference between win start and end
dWindowPowerStart = nan(length(dTime1Hz),1); % Start value of the power for the window in kW
dWindowPowerEnd= dPowerCumulative; % End value of the power for the window in kW
dWindowPowerAvg = nan(length(dTime1Hz),1); % Average Power in the window in kW
dWindowPercentAvgPower = nan(length(dTime1Hz),1); % window avg power percent is calculated dynamically
dWindowActive = nan(length(dTime1Hz),1); % If hWHTC work of the cycle has been crossed then window calculation is active
dWindowValid = nan(length(dTime1Hz),1); % When ever the percentage of average power in a window crosses the power threshold the window is valid
dWindowNoxStart = nan(length(dTime1Hz),1); %Start value of the NOx for a window g/h
dWindowNoxEnd = dNoxCumulative; % End value of the NOx for a window in g/h
dWindowNoxAvg = nan(length(dTime1Hz),1); % Average NOx value for the window in g/h
dWindowCF = nan(length(dTime1Hz),1); % CF for each window
dWindowVehSpeedStart = nan(length(dTime1Hz),1); %Start value of the Vehicle speed for a window m/s
dWindowVehSpeedEnd = dVehSpeedCumulative; % End value of the Vehicle speed for a window m/s
dWindowVehSpeedAvg = nan(length(dTime1Hz),1); % Average vehicle speed value for the window in m/s
dWindowT9N1HzStart = nan(length(dTime1Hz),1); %Start value of the SCR out temp for a window in degreeC
dWindowT9N1HzEnd = dT9N1HzCumulative;  %End value of the SCR out temp for a window in degreeC
dWindowT9N1HzAvg = nan(length(dTime1Hz),1); %Average value of the SCR out temp for a window in degreeC
dWindowNoxAvgOPower = nan(length(dTime1Hz),1); % Average NOx by Average Power for the window in g/kWh
dWindowNoxAvgOPowerValid = nan(length(dTime1Hz),1); % dWindowNoxAvgOPower value if window is valid

nWindowCalcStart = find(dWorkRequired>=0,1); % To find out the first point where the first window condition is achieved
for nIdx=nWindowCalcStart:length(dTime1Hz)
    %dWindowStart(nIdx,1) = find(dWorkRequired(nIdx,1)>dWorkCumulative,1,'last'); % Finding the start point for the window
    dWindowStart(nIdx,1) = find(dWorkRequired(nIdx,1)>dWorkCumulative,1,'last');
    if dTwa1Hz(dWindowStart(nIdx,1))<nCoolantTempMax% Condition check for cold windows if start coolant temperature less than threshold
        dWindowSize(nIdx,1) = dWindowEnd(nIdx,1)-dWindowStart(nIdx,1)+1; % Calculation for size of the window 1 is added for zero index correction in matlab
        dWindowPowerStart(nIdx,1) = dPowerCumulative(dWindowStart(nIdx,1)); % Value of the cumulative power at the found location in kW
        dWindowPowerAvg(nIdx,1) = (dWindowPowerEnd(nIdx,1)-dWindowPowerStart(nIdx,1))/dWindowSize(nIdx,1); % Average of power in the window in kW
        dWindowPercentAvgPower(nIdx,1) = (dWindowPowerAvg(nIdx,1)/nRatedPower)*100; % Percent power=avg power for the window / Rated power  in %
        if(dWorkCumulative(nIdx,1)<nWorkMax)
            if(~isnan(dWindowSize(nIdx,1)))
                dWindowActive(nIdx,1) = 1;% cumulative work within max limit of 1000 kWh and window present
            else
                dWindowActive(nIdx,1) = 0; % minimum work limit for window hasnt reached yet
            end
        else
            dWindowActive(nIdx,1) = 0; % Cumulative work crossed max limit of 1000 kWh
        end
        
        if(dWorkCumulative(nIdx,1)<nWorkMax)
            if(dWindowPercentAvgPower(nIdx,1)>nPowerThreshold)
                dWindowValid(nIdx,1) = 1;% cumulative work within max limit of 1000 kWh and avg window power greather than power threshold
            else
                dWindowValid(nIdx,1) = 0; % avg window power less than the power threshold
            end
        else
            dWindowValid(nIdx,1) = 0; % Cumulative work crossed max limit of 1000 kWh
        end
        
        dWindowNoxStart(nIdx,1) = dNoxCumulative(dWindowStart(nIdx,1)); %Start value of the NOx for the window in g/h
        dWindowNoxAvg(nIdx,1) = (dWindowNoxEnd(nIdx,1)-dWindowNoxStart(nIdx,1))/dWindowSize(nIdx,1); % Average value of NOx in the window in g/h
        dWindowNoxAvgOPower(nIdx,1) = dWindowNoxAvg(nIdx,1)/dWindowPowerAvg(nIdx,1); % NOX/Power of each window in g/kWh
        if(isnan(dWindowNoxAvgOPower(nIdx,1))||(dWindowValid(nIdx,1)== 0))
        else
            dWindowNoxAvgOPowerValid(nIdx,1) = dWindowNoxAvgOPower(nIdx,1); % Takes the value if only the power threshold is crossed for the window
            dWindowCF(nIdx,1) = dWindowNoxAvgOPowerValid(nIdx,1)/0.46; % CF factor calculation for each window
        end
        
        dWindowVehSpeedStart(nIdx,1) =  dVehSpeedCumulative(dWindowStart(nIdx,1)); %Start value of the Vehicle speed for a window m/s
        dWindowVehSpeedAvg(nIdx,1) =(dWindowVehSpeedEnd(nIdx,1)-dWindowVehSpeedStart(nIdx,1))/dWindowSize(nIdx,1); % Average vehicle speed value for the window in m/s
        dWindowT9N1HzStart(nIdx,1) =  dT9N1HzCumulative(dWindowStart(nIdx,1)); %Start value of the Vehicle speed for a window m/s
        dWindowT9N1HzAvg(nIdx,1) =(dWindowT9N1HzEnd(nIdx,1)-dWindowT9N1HzStart(nIdx,1))/dWindowSize(nIdx,1); % Average vehicle speed value for the window in m/s
    end
end

% Values which should be returned to the parent function

dIdxWindowStart = (dConditionMet==1);
xReturn.nTimeWindowStart = dTime1Hz(find(dIdxWindowStart,1,'first'));
[xReturn.nPercentile90, xReturn.nCF90, ~, ~] = pnt_PercentileCalc(dWindowNoxAvgOPowerValid,90); % 90 Percentile Value of NOx [g/kWh]
[xReturn.nPercentile95, xReturn.nCF95, ~, ~] = pnt_PercentileCalc(dWindowNoxAvgOPowerValid,95); % 95 Percentile Value of NOx [g/kWh]
[xReturn.nPercentile100, xReturn.nCF100, ~, ~] = pnt_PercentileCalc(dWindowNoxAvgOPowerValid,100); % 100 Percentile Value of NOx [g/kWh]
[xReturn.nPercentileReq, xReturn.nCFReq, xReturn.dCF, xReturn.dIdxCF] = pnt_PercentileCalc(dWindowNoxAvgOPowerValid,nRequiredPercentile); % Required Percentile Value of NOx [g/kWh]
xReturn.nWindowTotal = sum(dWindowActive(~isnan(dWindowActive))); % Total number of windows
xReturn.nWindowValid = sum(dWindowValid(~isnan(dWindowValid))); % Valid windows
xReturn.nWindowValidPerc = (xReturn.nWindowValid/xReturn.nWindowTotal)*100; % Percentage of windows which are valid [%]
xReturn.nWorkCumulativeEnd = max(dWorkCumulative); % The cumulative work at the last sample [kWh]
xReturn.nWorkCumOverWorkWindow = xReturn.nWorkCumulativeEnd/nWhtcWork; % Total Cumulative work over hWHTC work
xReturn.nTotalNoxOverWork = sum(dMnoxhn1Hz)/(xReturn.nWorkCumulativeEnd*3600); % Total Nox per total work [g/kWh]
xReturn.nWindowNoxMin = min(dWindowNoxAvgOPowerValid); % minimum value of window NOx [g/kWh]
xReturn.nWindowNoxMax = max(dWindowNoxAvgOPowerValid); % Maximum value of window NOx [g/kWh]
xReturn.nAvgWindowNox = (sum(dWindowNoxAvgOPowerValid(~isnan(dWindowNoxAvgOPowerValid))))/xReturn.nWindowValid; % Average of Window NOx [g/kWh]
xReturn.dTime1Hz = dTime1Hz; % Time samples in 1 Hz [s]
xReturn.dMeffw1Hz = dMeffw1Hz; % Effective Torque in 1 Hz [Nm]
xReturn.dNmotw1Hz = dNmotw1Hz; % Engine Speed in 1 Hz [rpm]
xReturn.dTWa1Hz = dTwa1Hz; % Coolant temperature in 1 Hz [degree C]
xReturn.dMnoxhn1Hz = dMnoxhn1Hz; % Mass flow rate of tail pipe NOx [g/h]
xReturn.dConditionCase = dConditionCase; % Condition satisfied 1,2,3,4
xReturn.dConditionMet = dConditionMet; % Whether condition is satisfied or not
xReturn.dPowerInstant = dPowerInstant; % Instantaneous power [kW]
xReturn.dPowerCumulative = dPowerCumulative; % Cumulative power [kW]
xReturn.dWorkInstant = dWorkInstant; % Instantaneous Work [kWh]
xReturn.dWorkCumulative = dWorkCumulative; % Cumulative Work [kWh]
xReturn.dWindowSize = dWindowSize; % Size of the NOx calculation window
xReturn.dWindowStart = dWindowStart; % Index of NOx calculation window starts
xReturn.dWindowEnd = dWindowEnd; % time sample at wich window ended
xReturn.dWindowPowerStart = dWindowPowerStart; % Cumulative power value at window start [kW]
xReturn.dWindowPowerEnd = dWindowPowerEnd; % Cumulative power value at window end [kW]
xReturn.dWindowPowerAvg = dWindowPowerAvg; % Average Power in the window [kW]
xReturn.dWindowPercentAvgPower = dWindowPercentAvgPower; % Percent of Average power over the rated power [%]
xReturn.dWindowActive = dWindowActive; % Window is active if required hWHTC work is reached 0,1
xReturn.dWindowValid = dWindowValid; % Window is valid if the percent power crosses the power threshold 0,1
xReturn.dNoxCumulative =dNoxCumulative; % Cumulative NOx value [g/h]
xReturn.dWindowNoxStart = dWindowNoxStart; % Cumulative NOx value at window start [g/h]
xReturn.dWindowNoxEnd = dWindowNoxEnd; % Cumulative NOx value at window end [g/h]
xReturn.dWindowNoxAvg = dWindowNoxAvg; % Average Value of NOx in the window [g/h]
xReturn.dWindowNoxAvgOPower = dWindowNoxAvgOPower; % Average value of NOx over power in the window [g/kWh]
xReturn.dWindowNoxAvgOPowerValid = dWindowNoxAvgOPowerValid; % Average value of NOx over power in the window where window is valid [g/kWh]
xReturn.dWindowVehSpeedStart = dWindowVehSpeedStart; % Start value of the vehicle speed for a window in m/s
xReturn.dWindowVehSpeedEnd = dWindowVehSpeedEnd;% End value of the Vehicle speed for a window m/s
xReturn.dWindowVehSpeedAvg = dWindowVehSpeedAvg; % Average vehicle speed value for the window in m/s
xReturn.dWindowT9N1HzStart = dWindowT9N1HzStart; %Start value of the SCR out temp for a window in degreeC
xReturn.dWindowT9N1HzEnd = dWindowT9N1HzEnd;  %End value of the SCR out temp for a window in degreeC
xReturn.dWindowT9N1HzAvg = dWindowT9N1HzAvg; % Average SCR out temp for a window in degree C
xReturn.dNOxgkwh = dNOxgkwh; % Instantaneous NOx in g/kWh
xReturn.dWindowCF = dWindowCF; % Window CF
xReturn.dVehSpeed = dVehSpeed; % Vehicle speed
xReturn.nPowerThreshold = nPowerThreshold; % Power threshold [%]

end

