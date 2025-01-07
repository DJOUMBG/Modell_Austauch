function [sPathFull] = pnt_NoxCalculation( sPath )
%pnt_NoxCalculation
% pnt_NoxCalculation Takes the complete path of the processed mat file from
% pnt_FormulaCalc function as the input, gives the required input data to
% pnt_WindowCalculation function. Generate the required plots

% Syntax:
%   pnt_NoxCalculation( sPath )
%
% Inputs:
%                sPath  : Path of the post processed file
%
% Outputs:
%               sPathFull: Full path of the processed output file
%               containing the result vector
% Example:
%       sPathFull = pnt_NoxCalculation( 'D:\B45_Atego_detailed_1018L4x2_L967W244_5t8_constCoolant_diffGPS_PEMSNOX.mat' )
%
% See also:  pnt_ResultsAccumulate pnt_FormulaCalc pnt_PemsnoxCalculation
%
%               Author: Ajesh Chandran - RDI/TBP, MBRDI
%                Phone: +91-80-6149-6368
%               MailTo: ajesh.chandran@daimler.com
%    Date of Creation : 2019-02-21
% Date of Modification:
%  Userid Modification:
% Modification Content:


%%

xData = load(sPath);  % Loading the post processed mat file
[sPath,sMatFile,~] = fileparts(sPath);
if(~isempty(strfind(xData.sEngName,'OM47'))) % HDEP engines
    load('HDEP_WHTC_Work_List.mat'); % Loading the Reference WHTC Work for HDEP engines
elseif (~isempty(strfind(xData.sEngName,'OM93')))
    load('MDEG_WHTC_Work_List.mat'); % Loading the Reference WHTC Work for MDEG engines
elseif (~isempty(strfind(xData.sEngName,'OM92')))
    load('Classic_WHTC_Work_List.mat'); % Loading the Reference WHTC Work for MDEG engines    
else
    fprintf('Engine Type Unknown.Stopping the Evaluation\n');% Error Message
    return
end
cEngContent = cMatContent(find(strcmp(xData.sEngName,cMatContent)),:);% Filtering out the cell for particular engine
cPowerContent = cEngContent(find(xData.nPowerRating==cell2mat(cEngContent(:,2))),:);
nWhtcWork = cell2mat(cPowerContent(find(xData.nEngMaxTorque==cell2mat(cPowerContent(:,4))),3));
xData.nWhtcWork = nWhtcWork; % for PEMS route validation
if isempty(nWhtcWork)
    fprintf('\n Sorry. WHTC work of the specified engine,power,max torque missing\n');
    return
else
    fprintf('\n Engine = %s, Power = %dkW, MaxTorque = %dNm, WHTC Work = %4.2fkWh\n'....
        ,xData.sEngName,xData.nPowerRating,xData.nEngMaxTorque,nWhtcWork);
end
%% Creating the structure to be passed
xPassFunction.sPath = sPath;
xPassFunction.dTime1Hz=xData.time;
xPassFunction.dMeffw1Hz=xData.MEFFW;
xPassFunction.dNmotw1Hz=xData.NMOTW;
xPassFunction.dTwa1Hz=xData.TWA;
xPassFunction.dMnoxhn1Hz=xData.MNOXHN;
xPassFunction.dT7V1Hz=xData.T7VEE;
xPassFunction.dT7N1Hz=xData.T7NEE;
xPassFunction.dT9V1Hz=xData.T9VEE;
xPassFunction.dT9N1Hz=xData.T9NEE;
xPassFunction.dVehSpeed = xData.can_vehicle_speed;
xPassFunction.nCoolantTempMax = 200;% Maximum temperature upto which the ...
                                    %window Calculation can happen for cold windows
                                    % 200 selected as coolant temperature
                                    % never reaches this temperature
%% 1 kWh NOx window Calculation for plotting only
xPassFunction.nRatedPower = xData.nPowerRating; % The rated power of the engine in kW
xPassFunction.nWorkMax = 1000; %Maximum possible work in the cycle in kWh
xPassFunction.nRequiredPercentile = 100; % Percentnile NOx value required for calculation
xPassFunction.nPowerThreshold = 0; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nWhtcWork = 1; % Moving average calculation of NOX for better visualisation
xPassFunction.nTimeMin = 0; % Calculation should start from 1st instance
xPassFunction.nCoolantTempMin = -35; % Calculation should start from 1st instance
xPassFunction.sType = '1kWhWindow'; % Name used for plotting
sPathFull = fullfile(sPath,'xPassFuntionfile.mat');
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
x1kWhWindow = pnt_WindowCalculation(sPathFull);

%% EURO6eCOLD_PT00 Calculation
xPassFunction.nWhtcWork = nWhtcWork; % The hot WHTC work for the cycle in kWh
xPassFunction.nPowerThreshold = 0; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nTimeMin = 600; % Minimum time for window calculation start in sec for COLD
xPassFunction.nCoolantTempMin = 30; % Minimum coolant temperature for window calculation start for COLD
xPassFunction.nCoolantTempMax = 70; % Window calc not required for window start above this temp
xPassFunction.nRequiredPercentile = 100; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6eCOLD_PT00'; % Name used for plotting
xPassFunction.sName = sMatFile; % Name of the current file for naming the graphs
sPathFull = fullfile(sPath,'xPassFuntionfile.mat');
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eColdResults_PT00 = pnt_WindowCalculation(sPathFull);

%% EURO6eCOLD_PT06 Calculation
xPassFunction.nPowerThreshold = 6; % only power thrershold differences present
xPassFunction.sType = 'EURO6eCOLD_PT06'; % Name used for plotting
sPathFull = fullfile(sPath,'xPassFuntionfile.mat');
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eColdResults_PT06 = pnt_WindowCalculation(sPathFull);

%% EURO6eCOLD_PT09 Calculation
xPassFunction.nPowerThreshold = 9; % only power thrershold differences present
xPassFunction.sType = 'EURO6eCOLD_PT09'; % Name used for plotting
sPathFull = fullfile(sPath,'xPassFuntionfile.mat');
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eColdResults_PT09 = pnt_WindowCalculation(sPathFull);

%% EURO6eCOLD_PT10 Calculation
xPassFunction.nPowerThreshold = 10; % only power thrershold differences present
xPassFunction.sType = 'EURO6eCOLD_PT10'; % Name used for plotting
sPathFull = fullfile(sPath,'xPassFuntionfile.mat');
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eColdResults_PT10 = pnt_WindowCalculation(sPathFull);

%% EURO6eHOT_PT00 Calculation
xPassFunction.nPowerThreshold = 0; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nTimeMin = Inf; % Time calculation absent in Hot calculation
xPassFunction.nCoolantTempMin = 70; % Minimum coolant temperature for window calculation start for Hot
xPassFunction.nCoolantTempMax = 200; % parameter required for cold for hot 200 is never reached so no constrains
xPassFunction.nRequiredPercentile = 95; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6eHOT_PT00'; % Name used for plotting
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eHotResults_PT00 = pnt_WindowCalculation(sPathFull);

%% EURO6eHOT_PT06 Calculation
xPassFunction.nPowerThreshold = 9; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 100; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6eHOT_PT09'; % Name used for plotting
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eHotResults_PT06= pnt_WindowCalculation(sPathFull);

%% EURO6eHOT_PT09 Calculation
xPassFunction.nPowerThreshold = 9; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 95; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6eHOT_PT09'; % Name used for plotting
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eHotResults_PT09= pnt_WindowCalculation(sPathFull);

%% EURO6eHOT_PT10 Calculation
xPassFunction.nPowerThreshold = 10; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 90; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6eHOT_PT10'; % Name used for plotting
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6eHotResults_PT10 = pnt_WindowCalculation(sPathFull);

%% EURO6d_PT00 Calculation
xPassFunction.nTimeMin = 900; % minimum time required for start of window calculation in s
xPassFunction.nCoolantTempMin = 70; % Minimum coolant temperature for window calculation start for Hot
xPassFunction.nPowerThreshold = 0; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 95; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6d_PT00'; % Euro6d Calculation this variable is used for naming the graphs
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6dResults_PT00 = pnt_WindowCalculation(sPathFull);

%% EURO6d_PT09 Calculation
xPassFunction.nPowerThreshold = 9; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 95; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6d_PT09'; % Euro6d Calculation this variable is used for naming the graphs
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6dResults_PT09 = pnt_WindowCalculation(sPathFull);

%% EURO6d_PT10 Calculation
xPassFunction.nPowerThreshold = 10; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 90; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6d_PT10'; % Euro6d Calculation this variable is used for naming the graphs
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6dResults_PT10 = pnt_WindowCalculation(sPathFull);

%% EURO6c_PT20 Calculation
xPassFunction.nTimeMin = 900; % minimum time required for start of window calculation in s
xPassFunction.nCoolantTempMin = 70; % Minimum coolant temperature for window calculation start for Hot
xPassFunction.nPowerThreshold = 20; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 90; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO6c_PT20'; % Euro6d Calculation this variable is used for naming the graphs
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro6cResults_PT20 = pnt_WindowCalculation(sPathFull);

%% EuroVII Check Calculations

%% EURO7_PT00 Calculation
xPassFunction.nTimeMin = 0; % minimum time required for start of window calculation in s
xPassFunction.nCoolantTempMin = -35; % Minimum coolant temperature for window calculation start for Hot
xPassFunction.nPowerThreshold = 0; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 100; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO7_PT00'; % Euro6d Calculation this variable is used for naming the graphs
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro7Results_PT00 = pnt_WindowCalculation(sPathFull);

%% EURO7_PT06 Calculation
xPassFunction.nTimeMin = 0; % minimum time required for start of window calculation in s
xPassFunction.nCoolantTempMin = -35; % Minimum coolant temperature for window calculation start for Hot
xPassFunction.nPowerThreshold = 6; % Power threshold percentage for checking whether a window is valid or not.
xPassFunction.nRequiredPercentile = 100; % Percentnile NOx value required for calculation
xPassFunction.sType = 'EURO7_PT06'; % Euro6d Calculation this variable is used for naming the graphs
save(sPathFull,'-struct','xPassFunction'); % Saving the required variables for calculation into one file
xEuro7Results_PT06 = pnt_WindowCalculation(sPathFull);

nWindowNoxEuro7PT00P100 = xEuro7Results_PT00.nPercentile100; % g/kWh
xData.CF_EUVII_PT00P100 = xEuro7Results_PT00.nCF100; % CF

nWindowNoxEuro7PT06P100 = xEuro7Results_PT06.nPercentile100; % g/kWh
xData.CF_EUVII_PT06P100 = xEuro7Results_PT06.nCF100; % CF

%% Euro 6E cumulative calculation of hot and cold
% Wightage is 0.14 for cold 0.86 for cold
nWindowNoxEuro6eStd = 0.14*xEuro6eColdResults_PT10.nPercentile100 + 0.86*xEuro6eHotResults_PT10.nPercentile90; % cumulative calculation for hot and cold togother
xData.CF_EUVIe_Std = nWindowNoxEuro6eStd/0.46; % CF calculation needed later for table preperation

nWindowNoxEuro6ePT00P100 = 0.14*xEuro6eColdResults_PT00.nPercentile100 + 0.86*xEuro6eHotResults_PT00.nPercentile100; % cumulative calculation for hot and cold togother
xData.CF_EUVIe_PT00P100 = nWindowNoxEuro6ePT00P100/0.46; % CF calculation needed later for table preperation

nWindowNoxEuro6ePT06P100 = 0.14*xEuro6eColdResults_PT06.nPercentile100 + 0.86*xEuro6eHotResults_PT06.nPercentile100; % cumulative calculation for hot and cold togother
xData.CF_EUVIe_PT06P100 = nWindowNoxEuro6ePT06P100/0.46; % CF calculation needed later for table preperation

nWindowNoxEuro6ePT09P095 = 0.14*xEuro6eColdResults_PT09.nPercentile100 + 0.86*xEuro6eHotResults_PT09.nPercentile95; % cumulative calculation for hot and cold togother
xData.CF_EUVIe_PT09P095 = nWindowNoxEuro6ePT09P095/0.46; % CF calculation

nWindowNoxEuro6ePT00P095 = 0.14*xEuro6eColdResults_PT00.nPercentile100+ 0.86*xEuro6eHotResults_PT00.nPercentile95; % cumulative calculation for hot and cold togother
xData.CF_EUVIe_PT00P095 = nWindowNoxEuro6ePT00P095/0.46; % CF calculation

nWindowNoxEuro6eColdPT09P100 = xEuro6eColdResults_PT09.nPercentile100; % g/kWh
xData.CF_EUVIe_cold_PT09P100 = xEuro6eColdResults_PT09.nCF100; % CF

nWindowNoxEuro6eColdPT00P100 = xEuro6eColdResults_PT00.nPercentile100; % g/kWh
xData.CF_EUVIe_cold_PT00P100 = xEuro6eColdResults_PT00.nCF100; % CF

nWindowNoxEuro6eColdStd = xEuro6eColdResults_PT10.nPercentile100; % g/kWh
xData.CF_EUVIe_cold_Std = xEuro6eColdResults_PT10.nCF100; % CF

nWindowNoxEuro6eHotPT09P095 = xEuro6eHotResults_PT09.nPercentile95; % g/kWh
xData.CF_EUVIe_hot_PT09P095 = xEuro6eHotResults_PT09.nCF95; % CF

nWindowNoxEuro6eHotPT00P095 = xEuro6eHotResults_PT00.nPercentile95; % g/kWh
xData.CF_EUVIe_hot_PT00P095 = xEuro6eHotResults_PT00.nCF95; % CF

nWindowNoxEuro6eHotStd = xEuro6eHotResults_PT10.nPercentile90; % g/kWh
xData.CF_EUVIe_hot_Std = xEuro6eHotResults_PT10.nCF90; % CF

nWindowNoxEuro6dPT09P095 = xEuro6dResults_PT09.nPercentile95; % g/kWh
xData.CF_EUVId_PT09P095 = xEuro6dResults_PT09.nCF95; % CF

nWindowNoxEuro6dPT00P095 = xEuro6dResults_PT00.nPercentile95; % g/kWh
xData.CF_EUVId_PT00P095 = xEuro6dResults_PT00.nCF95; % CF

nWindowNoxEuro6dStd = xEuro6dResults_PT10.nPercentileReq; % g/kWh
xData.CF_EUVId_Std = xEuro6dResults_PT10.nCFReq; % CF

nWindowNoxEuro6cStd = xEuro6cResults_PT20.nPercentileReq; % g/kWh
xData.CF_EUVIc_Std = xEuro6cResults_PT20.nCFReq; % CF

%% Checking whether valid windows are present

if xEuro6cResults_PT20.nWindowValidPerc>0
    fprintf('EURO6c PT20 : Window Valid Percent = %3.2f\n',...
        xEuro6cResults_PT20.nWindowValidPerc);
    if xEuro6cResults_PT20.nWindowValidPerc<50
        disp('Evaluation is void as 50% of Windows are not valid');
    end
else
    fprintf('EURO6c PT20 : None of the windows are valid\n');
end
if xEuro6dResults_PT00.nWindowValidPerc>0
    fprintf('EURO6d PT0 : Window Valid Percent = %3.2f\n',...
        xEuro6dResults_PT00.nWindowValidPerc);
else
    fprintf('EURO6d PT0 : None of the windows are valid\n');
end

if xEuro6dResults_PT09.nWindowValidPerc>0
    fprintf('EURO6d PT9 : Window Valid Percent = %3.2f\n',...
        xEuro6dResults_PT09.nWindowValidPerc);
else
    fprintf('EURO6d PT9 : None of the windows are valid\n');
end

if xEuro6dResults_PT10.nWindowValidPerc>0
    fprintf('EURO6d PT10 : Window Valid Percent = %3.2f\n',...
        xEuro6dResults_PT10.nWindowValidPerc);
else
    fprintf('EURO6d PT10 : None of the windows are valid\n');
end

if xEuro6eColdResults_PT00.nWindowValidPerc>0
    fprintf('EURO6eCold PT0 : Window Valid Percent = %3.2f\n',...
        xEuro6eColdResults_PT00.nWindowValidPerc);
else
    fprintf('EURO6eCold PT0 : None of the windows are valid\n');
end

if xEuro6eColdResults_PT06.nWindowValidPerc>0
    fprintf('EURO6eCold PT6 : Window Valid Percent = %3.2f\n',...
        xEuro6eColdResults_PT09.nWindowValidPerc);
else
    fprintf('EURO6eCold PT6 : None of the windows are valid\n');
end

if xEuro6eColdResults_PT09.nWindowValidPerc>0
    fprintf('EURO6eCold PT9 : Window Valid Percent = %3.2f\n',...
        xEuro6eColdResults_PT09.nWindowValidPerc);
else
    fprintf('EURO6eCold PT9 : None of the windows are valid\n');
end

if xEuro6eColdResults_PT10.nWindowValidPerc>0
    fprintf('EURO6eCold PT10 : Window Valid Percent = %3.2f\n',...
        xEuro6eColdResults_PT10.nWindowValidPerc);
else
    fprintf('EURO6eCold PT10 : None of the windows are valid\n');
end

if xEuro6eHotResults_PT00.nWindowValidPerc>0
    fprintf('EURO6eHot PT0 : Window Valid Percent = %3.2f\n',...
        xEuro6eHotResults_PT00.nWindowValidPerc);
else
    fprintf('EURO6eHot PT0 : None of the windows are valid\n');
end

if xEuro6eHotResults_PT06.nWindowValidPerc>0
    fprintf('EURO6eHot PT6 : Window Valid Percent = %3.2f\n',...
        xEuro6eHotResults_PT06.nWindowValidPerc);
else
    fprintf('EURO6eHot PT6 : None of the windows are valid\n');
end

if xEuro6eHotResults_PT09.nWindowValidPerc>0
    fprintf('EURO6eHot PT9 : Window Valid Percent = %3.2f\n',...
        xEuro6eHotResults_PT09.nWindowValidPerc);
else
    fprintf('EURO6eHot PT9 : None of the windows are valid\n');
end

if xEuro6eHotResults_PT10.nWindowValidPerc>0
    fprintf('EURO6eHot PT10 : Window Valid Percent = %3.2f\n',...
        xEuro6eHotResults_PT10.nWindowValidPerc);
else
    fprintf('EURO6eHot PT10 : None of the windows are valid\n');
end

if xEuro7Results_PT00.nWindowValidPerc>0
    fprintf('EURO7 PT00 : Window Valid Percent = %3.2f\n',...
        xEuro7Results_PT00.nWindowValidPerc);
else
    fprintf('EURO7 PT00 : None of the windows are valid\n');
end

if xEuro7Results_PT06.nWindowValidPerc>0
    fprintf('EURO7 PT06 : Window Valid Percent = %3.2f\n',...
        xEuro7Results_PT06.nWindowValidPerc);
else
    fprintf('EURO7 PT06 : None of the windows are valid\n');
end

%% Plotting Starts

% setting the size for labels and title

nLabelSize = 14; % Size of the label
nTitleSize = 22; % Size for the title of the graph
nLegendSize = 8; % Size of the legend

%% NOx cumulaive plots

nYLimit = max(xEuro6eColdResults_PT10.dWindowNoxAvgOPowerValid); % yaxis limit
if isnan(nYLimit)
    nYLimit = max(xEuro6eHotResults_PT10.dWindowNoxAvgOPowerValid);
end
hNoxFig = figure('Position',get(0,'Screensize'));% Creates a new figure window and maximize it
hAxes{1} = subplot(4,1,1); % Creating a tiled plot with 4 rows 1 column & selecting the first tile as current axes
hPlot1kWhWindow = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid); % 1kWh average value of NOX
hPlot1kWhWindow.Color = [.3 .3 .3]; % grey colour
hPlot1kWhWindow.LineStyle = '--'; % Line style
hold on
hPlotEuro6c = plot(xEuro6cResults_PT20.dTime1Hz,xEuro6cResults_PT20.dWindowNoxAvgOPowerValid); % Plotting the window value nox vs time
hPlotEuro6c.Color = 'blue';
%nYLimit = max(xEuro6dResults.dWindowNoxAvgOPowerValid); % yaxis limit
hPlotEuro6c.LineWidth = 1;
legend('NOx 1kWh','Window NOx');
if ~isnan(nYLimit)
    set(hAxes{1},'ylim',[0 nYLimit]);
end
ylabel('NOx [g/kWh]'); % Y label
%xlabel('Time [s]'); % X label
set(gca,'FontSize',nLabelSize,'Xticklabel',[]); % setting the label and tickmarks font size
title('EU VIc NOx','FontSize',nTitleSize);% setting the titlesize

hAxes{2} = subplot(4,1,2); % Creating a tiled plot with 3 rows 1 column & selecting the first tile as current axes
hPlot1kWhWindow = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid); % 1kWh average value of NOX
hPlot1kWhWindow.Color = [.3 .3 .3]; % grey colour
hPlot1kWhWindow.LineStyle = '--'; % Line style
hold on
hPlotEuro6d = plot(xEuro6dResults_PT10.dTime1Hz,xEuro6dResults_PT10.dWindowNoxAvgOPowerValid); % Plotting the window value nox vs time
hPlotEuro6d.Color = 'blue';
%nYLimit = max(xEuro6dResults.dWindowNoxAvgOPowerValid); % yaxis limit
hPlotEuro6d.LineWidth = 1;
legend('NOx 1kWh','Window NOx');
if ~isnan(nYLimit)
    set(hAxes{2},'ylim',[0 nYLimit]);
end
ylabel('NOx [g/kWh]'); % Y label
%xlabel('Time [s]'); % X label
set(gca,'FontSize',nLabelSize,'Xticklabel',[]); % setting the label and tickmarks font size
title('EU VId NOx','FontSize',nTitleSize);% setting the titlesize

hAxes{3} = subplot(4,1,3); % Second subplot selected
hPlot1kWhWindow = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid); % 1kWh average value of NOX
hPlot1kWhWindow.Color = [.3 .3 .3]; % grey colour
hPlot1kWhWindow.LineStyle = '--'; % Line style
hold on
hPlotEuro6eCold = plot(xEuro6eColdResults_PT10.dTime1Hz,xEuro6eColdResults_PT10.dWindowNoxAvgOPowerValid); % Plotting the window value nox vs timehPlotEuro6eHot.Color = 'blue';
%nYLimit = max(xEuro6eColdResults.dWindowNoxAvgOPowerValid); % yaxis limit
hPlotEuro6eCold.Color = 'blue';
hPlotEuro6eCold.LineWidth = 1;
legend('NOx 1kWh','Window NOx');
if ~isnan(nYLimit)
    set(hAxes{3},'ylim',[0 nYLimit]);
end
%ylim([0 nYLimit]); % Setting the temperature limits in which the vehicle operates
ylabel('NOx [g/kWh]'); % Y label
%xlabel('Time [s]'); % X label
set(gca,'FontSize',nLabelSize,'Xticklabel',[]); % setting the label and tickmarks font size
title('EU VIe Cold NOx','FontSize',nTitleSize);% setting the titlesize

hAxes{4} = subplot(4,1,4); % Third subplot selected
hPlot1kWhWindow = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid); % 1kWh average value of NOX
hPlot1kWhWindow.Color = [.3 .3 .3]; % grey colour
hPlot1kWhWindow.LineStyle = '--'; % Line style
hold on
hPlotEuro6eHot = plot(xEuro6eHotResults_PT10.dTime1Hz,xEuro6eHotResults_PT10.dWindowNoxAvgOPowerValid); % Plotting the window value nox vs time
hPlotEuro6eHot.Color = 'blue';
%nYLimit = max(xEuro6eHotResults.dWindowNoxAvgOPowerValid); % yaxis limit
hPlotEuro6eHot.LineWidth = 1;
legend('NOx 1kWh','Window NOx');
if ~isnan(nYLimit)
    set(hAxes{4},'ylim',[0 nYLimit]);
end
%ylim([0 nYLimit]); % Setting the temperature limits in which the vehicle operates
ylabel('NOx [g/kWh]'); % Y label
xlabel('Time [s]'); % X label
set(gca,'FontSize',nLabelSize); % setting the label and tickmarks font size
title('EU VIe Hot NOx','FontSize',nTitleSize);% setting the titlesize

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
savefig(hNoxFig,[sPath,'\NP_07 Window NOx Cumulative']); % Save the figure to file
saveas(hNoxFig,[sPath,'\NP_07 Window NOx Cumulative.png'],'png'); % Exporting the PNG figure
close (hNoxFig);
clear hNoxFig hPlotEuro6 hPlotEuro6eHot hPlotEuro6c hPlotEuro6d hPlotEuro6eCold hPlot1kWhWindow;


%% Cumulative power plot

hPowFig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(3,1,1); % Creating a tiled plot with 3 rows 1 column & selecting the first tile as current axes
hPlotEuro6dLeft = plot(xEuro6dResults_PT10.dTime1Hz,xEuro6dResults_PT10.dWindowPowerAvg); % Plotting the window value nox vs time
hPlotEuro6dLeft.Color = 'blue';
hPlotEuro6dLeft.LineWidth = 1;
ylabel('Avg Power [kW]'); % Y label
%xlabel('Time [s]'); % X label
% nMaxLimit = max(xEuro6dResults_PT10.dWindowPowerAvg); % Finding the maximum work for setting the axes limit
% if ~isnan(nMaxLimit)
% ylim([0 nMaxLimit]); % Setting the Y axis limit
% end
nPlotLim = get(gca,'YLim');% get the lower and higher limits of the plot
set(gca,'YTick',linspace(nPlotLim(1),nPlotLim(2),6));% to put yticks at specified points
set(gca,'YLim',nPlotLim);% Setting the plot limits
set(gca,'FontSize',nLabelSize); % setting the label and tickmarks font size
hold on;
yyaxis right; % Add a yaxis to the right
hPlotEuro6dRight = plot(xEuro6dResults_PT10.dTime1Hz,xEuro6dResults_PT10.dWindowPercentAvgPower); % Plotting the window value of Relative Power
hPlotEuro6dRight.Color = 'red';
hPlotEuro6dRight.LineStyle = '--';
hPlotEuro6dRight.LineWidth = 1;
%ylim([0 50]); % Settin the Y axis limit
%,'Ytick',[0:10:50]
%'YLim',[0 50],'YTick',[0:10:50]
%nPlotLim = get(gca,'YLim');% get the lower and higher limits of the plot
nPlotMaxValue = max(xEuro6eColdResults_PT10.dWindowPercentAvgPower);
if ~isnan(nPlotMaxValue)
    if nPlotMaxValue>50
        set(gca,'YTick',linspace(0,100,6));% to put yticks at specified points
        set(gca,'YLim',[0 100]);% Setting the plot limits
    elseif nPlotMaxValue>0&&nPlotMaxValue<=50
        set(gca,'YTick',linspace(0,50,6));% to put yticks at specified points
        set(gca,'YLim',[0 50]);% Setting the plot limits
    else
        disp('Unexpected Error in Window power plotting');
    end
end
set(gca,'ycolor','black'); % for setting the axes colour as black
ylabel('Relative Power [%]'); % Y label
hLegend = legend('Window Power','Relative Window Power');
%hLegend.Location = 'northwest';
set(gca,'FontSize',nLabelSize,'Xticklabel',[],'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VIc & EU VId Window Power & Relative Window Power','FontSize',nTitleSize);% setting the titlesize

hAxes{2} = subplot(3,1,2); % Selecting teh 2nd subplot
hPlotEuro6eColdLeft = plot(xEuro6eColdResults_PT10.dTime1Hz,xEuro6eColdResults_PT10.dWindowPowerAvg); % Plotting the window value nox vs time
hPlotEuro6eColdLeft.Color = 'blue';
hPlotEuro6eColdLeft.LineWidth = 1;
ylabel('Avg Power [kW]'); % Y label
%xlabel('Time [s]'); % X label
% nMaxLimit = max(xEuro6eColdResults_PT10.dWindowPowerAvg); % Finding the maximum work for setting the axes limit
% if ~isnan(nMaxLimit)
% ylim([0 (nMaxLimit+5)]); % Setting the Y axis limit
% end
nPlotLim = get(gca,'YLim');% get the lower and higher limits of the plot
set(gca,'YTick',linspace(nPlotLim(1),nPlotLim(2),6));% to put yticks at specified points
set(gca,'YLim',nPlotLim);% Setting the plot limits
set(gca,'FontSize',nLabelSize,'Xticklabel',[]); % setting the label and tickmarks font size
hold on;
yyaxis right; % Add a yaxis to the right
hPlotEuro6eColdRight = plot(xEuro6eColdResults_PT10.dTime1Hz,xEuro6eColdResults_PT10.dWindowPercentAvgPower); % Plotting the window value of Relative Power
hPlotEuro6eColdRight.Color = 'red';
hPlotEuro6eColdRight.LineStyle = '--';
hPlotEuro6eColdRight.LineWidth = 1;
%ylim([0 50]); % Settin the Y axis limit
nPlotMaxValue = max(xEuro6eColdResults_PT10.dWindowPercentAvgPower);
if ~isnan(nPlotMaxValue)
    if nPlotMaxValue>50
        set(gca,'YTick',linspace(0,100,6));% to put yticks at specified points
        set(gca,'YLim',[0 100]);% Setting the plot limits
    elseif nPlotMaxValue>0&&nPlotMaxValue<=50
        set(gca,'YTick',linspace(0,50,6));% to put yticks at specified points
        set(gca,'YLim',[0 50]);% Setting the plot limits
    else
        disp('Unexpected Error in Window power plotting');
    end
end
set(gca,'ycolor','black'); % for setting the axes colour as black
ylabel('Relative Power [%]'); % Y label
hLegend = legend('Window Power','Relative Window Power');
%hLegend.Location = 'northwest';
set(gca,'FontSize',nLabelSize,'Xticklabel',[],'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VIe Cold Window Power & Relative Window Power','FontSize',nTitleSize);% setting the titlesize

hAxes{3} = subplot(3,1,3); % Selecting teh 3rd subplot
hPlotEuro6eHotLeft = plot(xEuro6eHotResults_PT10.dTime1Hz,xEuro6eHotResults_PT10.dWindowPowerAvg); % Plotting the window value nox vs time
hPlotEuro6eHotLeft.Color = 'blue';
hPlotEuro6eHotLeft.LineWidth = 1;
ylabel('Avg Power [kW]'); % Y label
xlabel('Time [s]'); % X label
% nMaxLimit = max(xEuro6eHotResults_PT10.dWindowPowerAvg); % Finding the maximum work for setting the axes limit
% if ~isnan(nMaxLimit)
% ylim([0 nMaxLimit]); % Setting the Y axis limit
% end
nPlotLim = get(gca,'YLim');% get the lower and higher limits of the plot
set(gca,'YTick',linspace(nPlotLim(1),nPlotLim(2),6));% to put yticks at specified points
set(gca,'YLim',nPlotLim);% Setting the plot limits
set(gca,'FontSize',nLabelSize);
hold on;
yyaxis right; % Add a yaxis to the right
hPlotEuro6eHotRight = plot(xEuro6eHotResults_PT10.dTime1Hz,xEuro6eHotResults_PT10.dWindowPercentAvgPower); % Plotting the window value of Relative Power
hPlotEuro6eHotRight.Color = 'red';
hPlotEuro6eHotRight.LineStyle = '--';
hPlotEuro6eHotRight.LineWidth = 1;
%ylim([0 50]); % Settin the Y axis limit
nPlotMaxValue = max(xEuro6eColdResults_PT10.dWindowPercentAvgPower);
if ~isnan(nPlotMaxValue)
    if nPlotMaxValue>50
        set(gca,'YTick',linspace(0,100,6));% to put yticks at specified points
        set(gca,'YLim',[0 100]);% Setting the plot limits
    elseif nPlotMaxValue>0&&nPlotMaxValue<=50
        set(gca,'YTick',linspace(0,50,6));% to put yticks at specified points
        set(gca,'YLim',[0 50]);% Setting the plot limits
    else
        disp('Unexpected Error in Window power plotting');
    end
end
set(gca,'ycolor','black'); % for setting the axes colour as black
ylabel('Relative Power [%]'); % Y label
hLegend = legend('Window Power','Relative Window Power');
%hLegend.Location = 'northwest';
set(gca,'FontSize',nLabelSize,'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VIe Hot Window Power & Relative Window Power','FontSize',nTitleSize);% setting the titlesize

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
xlim([0 max(xEuro6eHotResults_PT10.dTime1Hz)]);
savefig(hPowFig,[sPath,'\NP_12 Window Power Cumulative']); % Save the figure to file
saveas(hPowFig,[sPath,'\NP_12 Window Power Cumulative.png'],'png'); % Exporting the PNG figure
close (hPowFig);
clear hPowFig hLegend hPlotEuro6dLeft hPlotEuro6eColdLeft hPlotEuro6eHotLeft...
    hPlotEuro6dRight hPlotEuro6eColdRight hPlotEuro6eHotRight nPlotLim;

%ends

%% Structure Creation for Table
cListVariablesSummary = {'Work_Total' 'MBONL_Total' 'MNOX_Total' 'MNOXN_Total'...
    'MHST_Total' 'MHSTdenied_Total' 'time_MHSTdenied_perc' 'BSFC' 'ETA' ...
    'T2SEE_Mean' 'T31_Mean' 'T32_Mean' 'T4_Mean' 'TAB_Mean' 'T7VEE_Mean' ...
    'T9VEE_Mean' 'T9NEE_Mean' 'cTM1' 'cTM3' 'cTM5' 'Idling_Total' 'Coasting_Total' ...
    'CF_EUVIc_Std' 'CF_EUVId_Std' 'CF_EUVIe_Std' 'CF_EUVIe_hot_Std' 'CF_EUVIe_cold_Std' ...
    'CF_EUVId_PT09P095' 'CF_EUVId_PT00P095' 'CF_EUVIe_PT09P095' ...
    'CF_EUVIe_hot_PT09P095' 'CF_EUVIe_cold_PT09P100' 'CF_EUVIe_PT00P095' ...
    'CF_EUVIe_hot_PT00P095' 'CF_EUVIe_cold_PT00P100'};
    % List of variables which should be printed in the table

cListUnitSummary = {' [kWh]' ' [kg]' ' [g]' ' [g]' ...
    ' [g]' ' [g]' ' [%]' ' [g/kWh]' ' [%]' ...
    ' [C]' ' [C]' ' [C]' ' [C]' ' [C]' ' [C]' ...
    ' [C]' ' [C]' ' [%]' ' [%]' ' [%]' ' [%]'  ' [%]'...
    ' [-]' ' [-]' ' [-]' ' [-]' ' [-]' ...
    ' [-]' ' [-]' ' [-]' ...
    ' [-]' ' [-]' ' [-]' ...
    ' [-]' ' [-]' }; % List of Units which should be printed in the table

for nIdx =1:numel(cListVariablesSummary) % For storing the variable names 
   xTable.VarName{nIdx,1} = [cListVariablesSummary{nIdx} cListUnitSummary{nIdx}] ; % Assigning the varible names
end

for nIdx =1:numel(cListVariablesSummary) % For storing the Values 
   xTable.Values(nIdx,1) = eval(['xData.',cListVariablesSummary{nIdx}]);
end

% %% 3 Variables for Simon to be commented later
%  fprintf('\nEuro6e CF = %d\n',xData.CF_EUVIe_Std);
%  fprintf('Tailpipe NOx [g/kWh] = %d\n',(xData.MNOXN_Total/xData.Work_Total));
%  fprintf('Min T9_900 [°C] =  %d\n',min(xData.T9VEE(901:end)));
 %% 
cHdr = xData.cHdrOut;
% structHdr = cell2struct(cHdr,{'Parameter' 'Values'},2);

%%  
%% Save all the required result to mat file

delete (sPathFull); % Deleting the temperory file created
sPathFull = [sPath,'\',sMatFile,'_Data.mat']; % giving as output argument
save([sPath,'\',sMatFile,'_Data.mat'],'xData','xTable','cHdr',...
'xEuro6cResults_PT20','xEuro6dResults_PT00','xEuro6dResults_PT09','xEuro6dResults_PT10',...
'xEuro6eColdResults_PT00','xEuro6eColdResults_PT06', 'xEuro6eColdResults_PT09','xEuro6eColdResults_PT10',...
'xEuro6eHotResults_PT00','xEuro6eHotResults_PT06', 'xEuro6eHotResults_PT09','xEuro6eHotResults_PT10',...
'xEuro7Results_PT00', 'xEuro7Results_PT06',...
'nWindowNoxEuro7PT00P100','nWindowNoxEuro7PT06P100',...
'nWindowNoxEuro6ePT00P100','nWindowNoxEuro6ePT06P100',...
'nWindowNoxEuro6eStd','nWindowNoxEuro6ePT09P095','nWindowNoxEuro6ePT00P095',...
'nWindowNoxEuro6cStd','nWindowNoxEuro6dStd','nWindowNoxEuro6dPT09P095','nWindowNoxEuro6dPT00P095',...
'nWindowNoxEuro6eColdStd','nWindowNoxEuro6eColdPT09P100','nWindowNoxEuro6eColdPT00P100',...
'nWindowNoxEuro6eHotStd','nWindowNoxEuro6eHotPT09P095','nWindowNoxEuro6eHotPT00P095');

%% Plot for Engine Speed,Torque and Coolant Temperature
hSpeedTorqueFig = figure('Position',get(0,'Screensize'));
hAxes{1} = subplot(3,1,1); % Creating a tiled plot with 3 rows 1 column & selecting the first tile as current axes
hPlotSpeedLeft = plot(xData.time,xData.NMOTW); % Plotting the window value nox vs time
hPlotSpeedLeft.Color = 'blue';
hPlotSpeedLeft.LineWidth = 1;
ylabel('Engine Speed [rpm]'); % Y label
%xlabel('Time [s]'); % X label
set(hAxes{1},'FontSize',nLabelSize,'YLim',[0,2500],'YTick',0:500:2500,...
    'Xticklabel',[],'XGrid','on','YGrid','on');
title('Engine Speed','FontSize',nTitleSize); % Title of the graph

hAxes{2} = subplot(3,1,2); % Selecting the 2nd subplot
hPlotTorqueRight = plot(xData.time,xData.MEFFW); % MEFFW plot
hPlotTorqueRight.Color = 'blue';
hPlotTorqueRight.LineWidth = 1;
%set(gca,'ycolor','black'); % for setting the axes colour as black
ylabel('Torque [Nm]'); % Y label
%xlabel('Time [s]'); % X label
nYLimitMax = max(xData.MEFFW);
if isnan(nYLimitMax)
    nYLimitMax=3000;% if max is NaN
end
nYLimitMin = min(xData.MEFFW);
if isnan(nYLimitMin)
    nYLimitMin = -1000;% if min is NaN
end
set(gca,'FontSize',nLabelSize,'YLim',[nYLimitMin,nYLimitMax],...
    'Xticklabel',[],'XGrid','on','YGrid','on');
title('Torque','FontSize',nTitleSize); % Title of the graph

hAxes{3} = subplot(3,1,3); % Selecting the 3 subplot
hPlotTWALeft = plot(xData.time,xData.TWA); % Coolant temperature plot
hPlotTWALeft.Color = 'blue';
hPlotTWALeft.LineWidth = 1;
dCoolColdThrd = 30*ones(length(xData.time),1);
hold on;
hPlotTWA2Left = plot(xData.time,dCoolColdThrd); % Coolant temperature plot
hPlotTWA2Left.Color = 'green';
hPlotTWA2Left.LineStyle = '--';
hPlotTWA2Left.LineWidth = 1;
dCoolHotThrd = 70*ones(length(xData.time),1);
hold on;
hPlotTWA3Left = plot(xData.time,dCoolHotThrd); % Coolant temperature plot
hPlotTWA3Left.Color = 'red';
hPlotTWA3Left.LineStyle = '--';
hPlotTWA3Left.LineWidth = 1;
clear dCoolColdThrd dCoolHotThrd
%set(gca,'ycolor','black'); % for setting the axes colour as black
ylabel('TWA [deg C]'); % Y label
xlabel('Time [s]'); % X label
%legend('Engine Speed','Torque')
nYLimitMax = max(xData.TWA);
if isnan(nYLimitMax)
    nYLimitMax=110;% if max is NaN
end
nYLimitMin = min(xData.TWA);
if isnan(nYLimitMin)
    nYLimitMin = -7;% if min is NaN
end
set(gca,'FontSize',nLabelSize,'YLim',[nYLimitMin,nYLimitMax],'XGrid','on','YGrid','on');
title('Coolant Temperature','FontSize',nTitleSize); % Title of the graph

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
%set(gca,'ActivePositionProperty','outerposition');
savefig(hSpeedTorqueFig,[sPath,'\NP_02 Speed Torque']); % Save the figure to file
saveas(hSpeedTorqueFig,[sPath,'\NP_02 Speed Torque.png'],'png'); % Exporting the PNG figure
close(hSpeedTorqueFig);
clear hSpeedTorqueFig hPlotSpeedLeft hPlotTorqueRight hAxes hPlotTWALeft...
      hPlotTWA2Left hPlotTWA3Left nYLimitMax nYLimitMin

%% Plot 1 Engine speed, Vehicle Speed, Ambient Temperature & Pressure,Altitude
hPlot1Fig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(5,1,1); % Creating a tiled plot with 5 rows 1 column & selecting the first tile as current axes
hPlot1SpeedLeft = plot(xData.time,xData.NMOTW); % Engine speed [rpm]
hPlot1SpeedLeft.Color = 'blue';
hPlot1SpeedLeft.LineWidth = 1;
ylabel('NMOTW [rpm]'); % Y label
%xlabel('Time [s]'); % X label
set(hAxes{1},'YLim',[0 2500],'YTick',[0:1250:2500])
set(hAxes{1},'Xticklabel',[],'FontSize',nLabelSize);
title('General Parameters','FontSize',nTitleSize); % Title of the graph

hAxes{2} = subplot(5,1,2); % current axes is 2
hPlot1VehSpeedLeft = plot(xData.time,xData.can_vehicle_speed);% Vehicle speed [km/h]
hPlot1VehSpeedLeft.Color = 'blue';
hPlot1VehSpeedLeft.LineWidth = 1;
ylabel('Veh Speed [km/h]'); % Y label
%set(gca,'FontSize',nLabelSize);
%xlabel('Time [s]'); % X label
set(hAxes{2},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);

hAxes{3} = subplot(5,1,3); % Current axes is 3
hPlot1AmbTempLeft = plot(xData.time,xData.TL);% Ambient Temperature [dec C]
hPlot1AmbTempLeft.Color = 'blue';
hPlot1AmbTempLeft.LineWidth = 1;
ylabel('Ambient T [C]'); % Y label
set(gca,'FontSize',nLabelSize);
%xlabel('Time [s]'); % X label
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);

hAxes{4} = subplot(5,1,4); % Current axes is 4
hPlot1AmbPressureLeft = plot(xData.time,xData.PL);% Ambient Pressure [mbar]
hPlot1AmbPressureLeft.Color = 'blue';
hPlot1AmbPressureLeft.LineWidth = 1;
if max(xData.PL)~=min(xData.PL)
    nPlotMaxValue =ceil(max(xData.PL)/10)*10;
    nPlotMinValue = floor(min(xData.PL)/10)*10;
    if ((nPlotMaxValue-nPlotMinValue)>3)
        set(hAxes{4},'YLim',[nPlotMinValue nPlotMaxValue]);
        set(hAxes{4},'YTick',ceil(linspace(nPlotMinValue,nPlotMaxValue,3)));
    end
end

ylabel('Ambient P [mbar]'); % Y label
set(gca,'FontSize',nLabelSize);
%xlabel('Time [s]'); % X label
set(hAxes{4},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);

hAxes{5} = subplot(5,1,5); % Current axes is 5
hPlot1AltLeft = plot(xData.time,xData.env_altitude_m);% Altitude [m]
hPlot1AltLeft.Color = 'blue';
hPlot1AltLeft.LineWidth = 1;
if max(xData.env_altitude_m)~=min(xData.env_altitude_m)
    nPlotMaxValue =ceil(max(xData.env_altitude_m)/100)*100;
    set(hAxes{5},'YLim',[0 nPlotMaxValue]);
    set(hAxes{5},'YTick',ceil(linspace(0,nPlotMaxValue,4)));
end

ylabel('Altitude [m]'); % Y label
xlabel('Time [s]'); % X label
set(hAxes{5},'FontSize',nLabelSize);

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
savefig(hPlot1Fig,[sPath,'\NP_01 General Parameters']); % Save the figure to file
saveas(hPlot1Fig,[sPath,'\NP_01 General Parameters.png'],'png'); % Exporting the PNG figure
close(hPlot1Fig);
clear hPlot1Fig hAxes hPlot1SpeedLeft hPlot1VehSpeedLeft hPlot1AmbTempLeft...
    hPlot1AmbPressureLeft hPlot1AltLeft nPlotMinValue nPlotMaxValue

%% Plot 2.1 NOx windows with Standard Calculation (PT 10)
hPlot2Fig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(7,1,1); % Creating a tiled plot with 5 rows 1 column & selecting the first tile as current axes
hPlot2Urea = plot(xData.time,xData.MHST); % Urea [g/h]
hPlot2Urea.Color = 'blue';
hPlot2Urea.LineWidth = 1;
ylabel('Urea [g/h]'); % Y label
yyaxis right; % Creating a y axis on right side
hPlot2UreaCum = plot(xData.time,xData.MHST_Cum); % Urea [g/h]
hPlot2UreaCum.Color = 'red';
hPlot2UreaCum.LineWidth = 1;
ylabel('Cum[g]'); % Y label
set(gca,'ycolor','black');
%xlabel('Time [s]'); % X label
set(hAxes{1},'Xticklabel',[],'FontSize',nLabelSize);
title('Window NOx Standard','FontSize',nTitleSize);% Graph title
hLegend = legend('Urea','Urea Cumulative');
hLegend.FontSize = nLegendSize;
hLegend.Location = 'southeast';

hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot21Temperature = plot(xData.time,xData.T7VEE);% t_doc_in [C]
hPlot21Temperature.Color = 'green';
hPlot21Temperature.LineWidth = 1;
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot22Temperature = plot(xData.time,xData.T9VEE);% t_scr_in [C]
hPlot22Temperature.Color = 'red';
hPlot22Temperature.LineWidth = 1;
hPlot22Temperature.LineStyle = '--';
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot23Temperature = plot(xData.time,xData.T9NEE);% t_scr_out [C]
hPlot23Temperature.Color = 'blue';
hPlot23Temperature.LineWidth = 1;
hPlot23Temperature.LineStyle = ':';
nPlotMaxValue = ceil(max(xData.T7VEE)/100)*100;
set(hAxes{2},'YLim',[-10,nPlotMaxValue]);
set(hAxes{2},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
hLegend =legend('T7VEE','T9VEE','T9NEE');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
ylabel('EATS T[C]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{3} = subplot(7,1,3); % Current axes is 3
hPlot2WinPowerPerc = plot(xEuro6eColdResults_PT10.dTime1Hz,xEuro6eColdResults_PT10.dWindowPercentAvgPower);% Average window power[%]
hPlot2WinPowerPerc.Color = 'green';
hPlot2WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
hPlot22WinPowerPerc = plot(xEuro6eHotResults_PT10.dTime1Hz,xEuro6eHotResults_PT10.dWindowPercentAvgPower);% Average window power[%]
hPlot22WinPowerPerc.Color = 'blue';
hPlot22WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
dPowerThreshold = ones(length(xEuro6eHotResults_PT10.dTime1Hz),1)*xEuro6eHotResults_PT10.nPowerThreshold; % converting to vector for plotting
hPlot2WinPowerThrd = plot(xEuro6eHotResults_PT10.dTime1Hz,dPowerThreshold);
hPlot2WinPowerThrd.Color = 'red';
hPlot2WinPowerThrd.LineWidth = 1;
hPlot2WinPowerThrd.LineStyle = '--';
hLegend =legend('Cold','Hot','Threshold');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
%xlabel('Time [s]'); % X label

hAxes{4} = subplot(7,1,4); % Current axes is 4
hPlot2Tmc = plot(xData.time,xData.TMCEE);% TMC status [-]
hPlot2Tmc.Color = 'blue';
hPlot2Tmc.LineWidth = 1;
set(hAxes{4},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('TM Mode [-]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{5} = subplot(7,1,5); % Current axes is 5
hPlot21Nox = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid);% NOx with 1kWh window [g/kWh]
hPlot21Nox.Color = [.3 .3 .3]; % grey colour
hPlot21Nox.LineWidth = 1;
hold on
hPlot22Nox = plot(xEuro6dResults_PT10.dTime1Hz,xEuro6dResults_PT10.dWindowNoxAvgOPowerValid);% EU6d Window NOx [g/kWh]
hPlot22Nox.Color = 'green';
hPlot22Nox.LineWidth = 1;
hold on
hPlot23Nox = plot(xEuro6eColdResults_PT10.dTime1Hz,xEuro6eColdResults_PT10.dWindowNoxAvgOPowerValid);% EU6de cold Window NOx [g/kWh]
hPlot23Nox.Color = 'blue';
hPlot23Nox.LineStyle = '--';
hPlot23Nox.LineWidth = 1;
hold on
hPlot24Nox = plot(xEuro6eHotResults_PT10.dTime1Hz,xEuro6eHotResults_PT10.dWindowNoxAvgOPowerValid);% EU6de hot Window NOx [g/kWh]
hPlot24Nox.Color = 'red';
hPlot24Nox.LineStyle = ':';
hPlot24Nox.LineWidth = 1;
ylabel('NOx[g/kWh]'); % Y label
nMaxLimit = max(xEuro6eColdResults_PT00.dWindowNoxAvgOPower); % Finding the maximum value for setting the axes limit
if ~isnan(nMaxLimit)
    set(hAxes{5},'ylim',[0 nMaxLimit]);
end
set(hAxes{5},'Xticklabel',[],'FontSize',nLabelSize);
hLegend = legend('NOx 1kWh Window','NOx EU6d','NOx EU6eCold','NOx EU6eHot');
hLegend.FontSize = nLegendSize;
%hLegend.Location = 'northwest';
clear nMaxLimit
%xlabel('Time [s]'); % X label

hAxes{6} = subplot(7,1,6); % Current axes is 6
hPlot2alt = plot(xData.time,xData.env_altitude_m);% Altitude [m]
hPlot2alt.Color = 'blue';
hPlot2alt.LineWidth = 1;
if max(xData.env_altitude_m)~=min(xData.env_altitude_m)
    nPlotMaxValue =ceil(max(xData.env_altitude_m)/100)*100;
    set(hAxes{6},'YLim',[0 nPlotMaxValue]);
    set(hAxes{6},'YTick',linspace(0,nPlotMaxValue,4));
end
set(hAxes{6},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('Altitude [m]'); % Y label

hAxes{7} = subplot(7,1,7); % Current axes is 7
hPlot2speed = plot(xData.time,xData.NMOTW);% Engine Speed [rpm]
hPlot2speed.Color = 'blue';
hPlot2speed.LineWidth = 1;
set(hAxes{7},'ylim',[0 2600],'FontSize',nLabelSize);
ylabel('NMOTW [rpm]'); % Y label
xlabel('Time [s]'); % x label

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
savefig(hPlot2Fig,[sPath,'\NP_11 Window NOx Standard']); % Save the figure to file
saveas(hPlot2Fig,[sPath,'\NP_11 Window NOx Standard.png'],'png'); % Exporting the PNG figure
close(hPlot2Fig);
clear hPlot2Fig hPlot2Urea hPlot21Temperature hPlot22Temperature ...
    hPlot23Temperature hPlot2WinPowerPerc hPlot2WinPowerThrd hPlot2Tmc ...
    hPlot21Nox hPlot22Nox hPlot23Nox hPlot24Nox hPlot2alt hPlot2speed ...
    hPlot2Vel hAxes hLegend nPlotMaxValue hPlot2UreaCum


%% Plot 2.2 NOx windows with PT 10%
hPlot2Fig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(7,1,1); % Creating a tiled plot with 5 rows 1 column & selecting the first tile as current axes
hPlot2Urea = plot(xData.time,xData.MHST); % Urea [g/h]
hPlot2Urea.Color = 'blue';
hPlot2Urea.LineWidth = 1;
ylabel('Urea [g/h]'); % Y label
%xlabel('Time [s]'); % X label
yyaxis right; % Creating a y axis on right side
hPlot2UreaCum = plot(xData.time,xData.MHST_Cum); % Urea [g/h]
hPlot2UreaCum.Color = 'red';
hPlot2UreaCum.LineWidth = 1;
ylabel('Cum[g]'); % Y label
set(gca,'ycolor','black');
%xlabel('Time [s]'); % X label
set(hAxes{1},'Xticklabel',[],'FontSize',nLabelSize);
title('Window NOx 10% PT','FontSize',nTitleSize);% Graph title
hLegend = legend('Urea','Urea Cumulative');
hLegend.FontSize = nLegendSize;
hLegend.Location = 'southeast';


hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot21Temperature = plot(xData.time,xData.T7VEE);% t_doc_in [C]
hPlot21Temperature.Color = 'green';
hPlot21Temperature.LineWidth = 1;
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot22Temperature = plot(xData.time,xData.T9VEE);% t_scr_in [C]
hPlot22Temperature.Color = 'red';
hPlot22Temperature.LineWidth = 1;
hPlot22Temperature.LineStyle = '--';
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot23Temperature = plot(xData.time,xData.T9NEE);% t_scr_out [C]
hPlot23Temperature.Color = 'blue';
hPlot23Temperature.LineWidth = 1;
hPlot23Temperature.LineStyle = ':';
nPlotMaxValue = ceil(max(xData.T7VEE)/100)*100;
set(hAxes{2},'YLim',[-10,nPlotMaxValue]);
set(hAxes{2},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
hLegend =legend('T7VEE','T9VEE','T9NEE');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
ylabel('EATS T[C]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{3} = subplot(7,1,3); % Current axes is 3
hPlot2WinPowerPerc = plot(xEuro6eColdResults_PT10.dTime1Hz,xEuro6eColdResults_PT10.dWindowPercentAvgPower);% Average window power[%]
hPlot2WinPowerPerc.Color = 'green';
hPlot2WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
hPlot22WinPowerPerc = plot(xEuro6eHotResults_PT10.dTime1Hz,xEuro6eHotResults_PT10.dWindowPercentAvgPower);% Average window power[%]
hPlot22WinPowerPerc.Color = 'blue';
hPlot22WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
dPowerThreshold = ones(length(xEuro6eHotResults_PT10.dTime1Hz),1)*xEuro6eHotResults_PT10.nPowerThreshold; % converting to vector for plotting
hPlot2WinPowerThrd = plot(xEuro6eHotResults_PT10.dTime1Hz,dPowerThreshold);
hPlot2WinPowerThrd.Color = 'red';
hPlot2WinPowerThrd.LineWidth = 1;
hPlot2WinPowerThrd.LineStyle = '--';
hLegend =legend('Cold','Hot','Threshold');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
%xlabel('Time [s]'); % X label

hAxes{4} = subplot(7,1,4); % Current axes is 4
hPlot2Tmc = plot(xData.time,xData.TMCEE);% TMC status [-]
hPlot2Tmc.Color = 'blue';
hPlot2Tmc.LineWidth = 1;
set(hAxes{4},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('TM Mode [-]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{5} = subplot(7,1,5); % Current axes is 5
hPlot21Nox = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid);% NOx with 1kWh window [g/kWh]
hPlot21Nox.Color = [.3 .3 .3]; % grey colour
hPlot21Nox.LineWidth = 1;
hold on
hPlot22Nox = plot(xEuro6dResults_PT10.dTime1Hz,xEuro6dResults_PT10.dWindowNoxAvgOPowerValid);% EU6d Window NOx [g/kWh]
hPlot22Nox.Color = 'green';
hPlot22Nox.LineWidth = 1;
hold on
hPlot23Nox = plot(xEuro6eColdResults_PT10.dTime1Hz,xEuro6eColdResults_PT10.dWindowNoxAvgOPowerValid);% EU6de cold Window NOx [g/kWh]
hPlot23Nox.Color = 'blue';
hPlot23Nox.LineStyle = '--';
hPlot23Nox.LineWidth = 1;
hold on
hPlot24Nox = plot(xEuro6eHotResults_PT10.dTime1Hz,xEuro6eHotResults_PT10.dWindowNoxAvgOPowerValid);% EU6de hot Window NOx [g/kWh]
hPlot24Nox.Color = 'red';
hPlot24Nox.LineStyle = ':';
hPlot24Nox.LineWidth = 1;
ylabel('NOx[g/kWh]'); % Y label
nMaxLimit = max(xEuro6eColdResults_PT00.dWindowNoxAvgOPower); % Finding the maximum value for setting the axes limit
if ~isnan(nMaxLimit)
   set(hAxes{5},'ylim',[0 nMaxLimit] );
end
set(hAxes{5},'Xticklabel',[],'FontSize',nLabelSize);
hLegend = legend('NOx 1kWh Window','NOx EU6d','NOx EU6eCold','NOx EU6eHot');
hLegend.FontSize = nLegendSize;
%hLegend.Location = 'northwest';
clear nMaxLimit
%xlabel('Time [s]'); % X label

hAxes{6} = subplot(7,1,6); % Current axes is 6
hPlot2alt = plot(xData.time,xData.env_altitude_m);% Altitude [m]
hPlot2alt.Color = 'blue';
hPlot2alt.LineWidth = 1;
if max(xData.env_altitude_m)~=min(xData.env_altitude_m)
    nPlotMaxValue =ceil(max(xData.env_altitude_m)/100)*100;
    set(hAxes{6},'YLim',[0 nPlotMaxValue]);
    set(hAxes{6},'YTick',linspace(0,nPlotMaxValue,4));
end
set(hAxes{6},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('Altitude [m]'); % Y label

hAxes{7} = subplot(7,1,7); % Current axes is 7
hPlot2speed = plot(xData.time,xData.NMOTW);% Engine Speed [rpm]
hPlot2speed.Color = 'blue';
hPlot2speed.LineWidth = 1;
set(hAxes{7},'ylim',[0 2600],'FontSize',nLabelSize);
ylabel('NMOTW[rpm]'); % Y label
xlabel('Time [s]'); % x label

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
savefig(hPlot2Fig,[sPath,'\NP_10 Window NOx Power Threshold 10']); % Save the figure to file
saveas(hPlot2Fig,[sPath,'\NP_10 Window NOx Power Threshold 10.png'],'png'); % Exporting the PNG figure
close(hPlot2Fig);
clear hPlot2Fig hPlot2Urea hPlot21Temperature hPlot22Temperature ...
    hPlot23Temperature hPlot2WinPowerPerc hPlot2WinPowerThrd hPlot2Tmc ...
    hPlot21Nox hPlot22Nox hPlot23Nox hPlot24Nox hPlot2alt hPlot2speed ...
    hPlot2Vel hAxes hLegend nPlotMaxValue hPlot2UreaCum


%% Plot 2.3 NOx windows with PT 09%
hPlot2Fig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(7,1,1); % Creating a tiled plot with 5 rows 1 column & selecting the first tile as current axes
hPlot2Urea = plot(xData.time,xData.MHST); % Urea [g/h]
hPlot2Urea.Color = 'blue';
hPlot2Urea.LineWidth = 1;
ylabel('Urea [g/h]'); % Y label
%xlabel('Time [s]'); % X label
set(hAxes{1},'Xticklabel',[],'FontSize',nLabelSize);
%title('Window NOX 09% PT','FontSize',nTitleSize);% Graph title
yyaxis right; % Creating a y axis on right side
hPlot2UreaCum = plot(xData.time,xData.MHST_Cum); % Urea [g/h]
hPlot2UreaCum.Color = 'red';
hPlot2UreaCum.LineWidth = 1;
ylabel('Cum[g]'); % Y label
set(gca,'ycolor','black');
%xlabel('Time [s]'); % X label
set(hAxes{1},'Xticklabel',[],'FontSize',nLabelSize);
title('Window NOx 9% PT','FontSize',nTitleSize);% Graph title
hLegend = legend('Urea','Urea Cumulative');
hLegend.FontSize = nLegendSize;
hLegend.Location = 'southeast';

hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot21Temperature = plot(xData.time,xData.T7VEE);% t_doc_in [C]
hPlot21Temperature.Color = 'green';
hPlot21Temperature.LineWidth = 1;
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot22Temperature = plot(xData.time,xData.T9VEE);% t_scr_in [C]
hPlot22Temperature.Color = 'red';
hPlot22Temperature.LineWidth = 1;
hPlot22Temperature.LineStyle = '--';
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot23Temperature = plot(xData.time,xData.T9NEE);% t_scr_out [C]
hPlot23Temperature.Color = 'blue';
hPlot23Temperature.LineWidth = 1;
hPlot23Temperature.LineStyle = ':';
nPlotMaxValue = ceil(max(xData.T7VEE)/100)*100;
set(hAxes{2},'YLim',[-10,nPlotMaxValue]);
set(hAxes{2},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
hLegend =legend('T7VEE','T9VEE','T9NEE');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
ylabel('EATS T [C]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{3} = subplot(7,1,3); % Current axes is 3
hPlot2WinPowerPerc = plot(xEuro6eColdResults_PT09.dTime1Hz,xEuro6eColdResults_PT09.dWindowPercentAvgPower);% Average window power[%]
hPlot2WinPowerPerc.Color = 'green';
hPlot2WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
hPlot22WinPowerPerc = plot(xEuro6eHotResults_PT09.dTime1Hz,xEuro6eHotResults_PT09.dWindowPercentAvgPower);% Average window power[%]
hPlot22WinPowerPerc.Color = 'blue';
hPlot22WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
dPowerThreshold = ones(length(xEuro6eHotResults_PT09.dTime1Hz),1)*xEuro6eHotResults_PT09.nPowerThreshold; % converting to vector for plotting
hPlot2WinPowerThrd = plot(xEuro6eHotResults_PT09.dTime1Hz,dPowerThreshold);
hPlot2WinPowerThrd.Color = 'red';
hPlot2WinPowerThrd.LineWidth = 1;
hPlot2WinPowerThrd.LineStyle = '--';
hLegend =legend('Cold','Hot','Threshold');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
%xlabel('Time [s]'); % X label

hAxes{4} = subplot(7,1,4); % Current axes is 4
hPlot2Tmc = plot(xData.time,xData.TMCEE);% TMC status [-]
hPlot2Tmc.Color = 'blue';
hPlot2Tmc.LineWidth = 1;
set(hAxes{4},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('TM Mode [-]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{5} = subplot(7,1,5); % Current axes is 5
hPlot21Nox = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid);% NOx with 1kWh window [g/kWh]
hPlot21Nox.Color = [.3 .3 .3]; % grey colour
hPlot21Nox.LineWidth = 1;
hold on
hPlot22Nox = plot(xEuro6dResults_PT09.dTime1Hz,xEuro6dResults_PT09.dWindowNoxAvgOPowerValid);% EU6d Window NOx [g/kWh]
hPlot22Nox.Color = 'green';
hPlot22Nox.LineWidth = 1;
hold on
hPlot23Nox = plot(xEuro6eColdResults_PT09.dTime1Hz,xEuro6eColdResults_PT09.dWindowNoxAvgOPowerValid);% EU6de cold Window NOx [g/kWh]
hPlot23Nox.Color = 'blue';
hPlot23Nox.LineStyle = '--';
hPlot23Nox.LineWidth = 1;
hold on
hPlot24Nox = plot(xEuro6eHotResults_PT09.dTime1Hz,xEuro6eHotResults_PT09.dWindowNoxAvgOPowerValid);% EU6de hot Window NOx [g/kWh]
hPlot24Nox.Color = 'red';
hPlot24Nox.LineStyle = ':';
hPlot24Nox.LineWidth = 1;
ylabel('NOx[g/kWh]'); % Y label
nMaxLimit = max(xEuro6eColdResults_PT00.dWindowNoxAvgOPower); % Finding the maximum value for setting the axes limit
if ~isnan(nMaxLimit)
    set(hAxes{5},'ylim',[0 nMaxLimit]);
end
set(hAxes{5},'Xticklabel',[],'FontSize',nLabelSize);
hLegend = legend('NOx 1kWh Window','NOx EU6d','NOx EU6eCold','NOx EU6eHot');
hLegend.FontSize = nLegendSize;
clear nMaxLimit
%hLegend.Location = 'northwest';
%xlabel('Time [s]'); % X label

hAxes{6} = subplot(7,1,6); % Current axes is 6
hPlot2alt = plot(xData.time,xData.env_altitude_m);% Altitude [m]
hPlot2alt.Color = 'blue';
hPlot2alt.LineWidth = 1;
if max(xData.env_altitude_m)~=min(xData.env_altitude_m)
    nPlotMaxValue =ceil(max(xData.env_altitude_m)/100)*100;
    set(hAxes{6},'YLim',[0 nPlotMaxValue]);
    set(hAxes{6},'YTick',linspace(0,nPlotMaxValue,4));
end
set(hAxes{6},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('Altitude [m]'); % Y label

hAxes{7} = subplot(7,1,7); % Current axes is 7
hPlot2speed = plot(xData.time,xData.NMOTW);% Engine Speed [rpm]
hPlot2speed.Color = 'blue';
hPlot2speed.LineWidth = 1;
set(hAxes{7},'ylim',[0 2600],'FontSize',nLabelSize);
ylabel('NMOTW [rpm]'); % Y label
xlabel('Time [s]'); % x label

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
savefig(hPlot2Fig,[sPath,'\NP_09 Window NOx Power Threshold 09']); % Save the figure to file
saveas(hPlot2Fig,[sPath,'\NP_09 Window NOx Power Threshold 09.png'],'png'); % Exporting the PNG figure
close(hPlot2Fig);
clear hPlot2Fig hPlot2Urea hPlot21Temperature hPlot22Temperature ...
    hPlot23Temperature hPlot2WinPowerPerc hPlot2WinPowerThrd hPlot2Tmc ...
    hPlot21Nox hPlot22Nox hPlot23Nox hPlot24Nox hPlot2alt hPlot2speed ...
    hPlot2Vel hAxes hLegend nPlotMaxValue hPlot2UreaCum

%% Plot 2.4 NOx windows with PT 0%

hPlot2Fig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(7,1,1); % Creating a tiled plot with 5 rows 1 column & selecting the first tile as current axes
hPlot2Urea = plot(xData.time,xData.MHST); % Urea [g/h]
hPlot2Urea.Color = 'blue';
hPlot2Urea.LineWidth = 1;
ylabel('Urea [g/h]'); % Y label
%xlabel('Time [s]'); % X label
yyaxis right; % Creating a y axis on right side
hPlot2UreaCum = plot(xData.time,xData.MHST_Cum); % Urea [g/h]
hPlot2UreaCum.Color = 'red';
hPlot2UreaCum.LineWidth = 1;
ylabel('Cum[g]'); % Y label
set(gca,'ycolor','black');
%xlabel('Time [s]'); % X label
set(hAxes{1},'Xticklabel',[],'FontSize',nLabelSize);
title('Window NOx 00% PT','FontSize',nTitleSize);% Graph title
hLegend = legend('Urea','Urea Cumulative');
hLegend.FontSize = nLegendSize;
hLegend.Location = 'southeast';

hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot21Temperature = plot(xData.time,xData.T7VEE);% t_doc_in [C]
hPlot21Temperature.Color = 'green';
hPlot21Temperature.LineWidth = 1;
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot22Temperature = plot(xData.time,xData.T9VEE);% t_scr_in [C]
hPlot22Temperature.Color = 'red';
hPlot22Temperature.LineWidth = 1;
hPlot22Temperature.LineStyle = '--';
hold on
%hAxes{2} = subplot(7,1,2); % current axes is 2
hPlot23Temperature = plot(xData.time,xData.T9NEE);% t_scr_out [C]
hPlot23Temperature.Color = 'blue';
hPlot23Temperature.LineWidth = 1;
hPlot23Temperature.LineStyle = ':';
nPlotMaxValue = ceil(max(xData.T7VEE)/100)*100;
set(hAxes{2},'YLim',[-10,nPlotMaxValue]);
set(hAxes{2},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
hLegend =legend('T7VEE','T9VEE','T9NEE');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
ylabel('EATS T [C]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{3} = subplot(7,1,3); % Current axes is 3
hPlot2WinPowerPerc = plot(xEuro6eColdResults_PT00.dTime1Hz,xEuro6eColdResults_PT00.dWindowPercentAvgPower);% Average window power[%]
hPlot2WinPowerPerc.Color = 'green';
hPlot2WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
hPlot22WinPowerPerc = plot(xEuro6eHotResults_PT00.dTime1Hz,xEuro6eHotResults_PT00.dWindowPercentAvgPower);% Average window power[%]
hPlot22WinPowerPerc.Color = 'blue';
hPlot22WinPowerPerc.LineWidth = 1;
set(hAxes{3},'Xticklabel',[],'FontSize',nLabelSize);
ylabel('WinPowPerc[%]'); % Y label
hold on
dPowerThreshold = ones(length(xEuro6eHotResults_PT00.dTime1Hz),1)*xEuro6eHotResults_PT00.nPowerThreshold; % converting to vector for plotting
hPlot2WinPowerThrd = plot(xEuro6eHotResults_PT00.dTime1Hz,dPowerThreshold);
hPlot2WinPowerThrd.Color = 'red';
hPlot2WinPowerThrd.LineWidth = 1;
hPlot2WinPowerThrd.LineStyle = '--';
hLegend =legend('Cold','Hot','Threshold');
hLegend.FontSize = nLegendSize;% Setting the fontsize for legend
%xlabel('Time [s]'); % X label

hAxes{4} = subplot(7,1,4); % Current axes is 4
hPlot2Tmc = plot(xData.time,xData.TMCEE);% TMC status [-]
hPlot2Tmc.Color = 'blue';
hPlot2Tmc.LineWidth = 1;
set(hAxes{4},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('TM Mode [-]'); % Y label
%xlabel('Time [s]'); % X label

hAxes{5} = subplot(7,1,5); % Current axes is 5
hPlot21Nox = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid);% NOx with 1kWh window [g/kWh]
hPlot21Nox.Color = [.3 .3 .3]; % grey colour
hPlot21Nox.LineWidth = 1;
hold on
hPlot22Nox = plot(xEuro6dResults_PT00.dTime1Hz,xEuro6dResults_PT00.dWindowNoxAvgOPowerValid);% EU6d Window NOx [g/kWh]
hPlot22Nox.Color = 'green';
hPlot22Nox.LineWidth = 1;
hold on
hPlot23Nox = plot(xEuro6eColdResults_PT00.dTime1Hz,xEuro6eColdResults_PT00.dWindowNoxAvgOPowerValid);% EU6de cold Window NOx [g/kWh]
hPlot23Nox.Color = 'blue';
hPlot23Nox.LineStyle = '--';
hPlot23Nox.LineWidth = 1;
hold on
hPlot24Nox = plot(xEuro6eHotResults_PT00.dTime1Hz,xEuro6eHotResults_PT00.dWindowNoxAvgOPowerValid);% EU6de hot Window NOx [g/kWh]
hPlot24Nox.Color = 'red';
hPlot24Nox.LineStyle = ':';
hPlot24Nox.LineWidth = 1;
ylabel('NOx[g/kWh]'); % Y label
nMaxLimit = max(xEuro6eColdResults_PT00.dWindowNoxAvgOPower); % Finding the maximum value for setting the axes limit
if ~isnan(nMaxLimit)
    set(hAxes{5},'ylim',[0 nMaxLimit]);
end
set(hAxes{5},'Xticklabel',[],'FontSize',nLabelSize);
hLegend = legend('NOx 1kWh Window','NOx EU6d','NOx EU6eCold','NOx EU6eHot');
hLegend.FontSize = nLegendSize;
%hLegend.Location = 'northwest';
clear nMaxLimit
%xlabel('Time [s]'); % X label

hAxes{6} = subplot(7,1,6); % Current axes is 6
hPlot2alt = plot(xData.time,xData.env_altitude_m);% Altitude [m]
hPlot2alt.Color = 'blue';
hPlot2alt.LineWidth = 1;
if max(xData.env_altitude_m)~=min(xData.env_altitude_m)
    nPlotMaxValue =ceil(max(xData.env_altitude_m)/100)*100;
    set(hAxes{6},'YLim',[0 nPlotMaxValue]);
    set(hAxes{6},'YTick',linspace(0,nPlotMaxValue,4));
end
set(hAxes{6},'Xticklabel',[],'YAxisLocation','right','FontSize',nLabelSize);
ylabel('Altitude [m]'); % Y label

hAxes{7} = subplot(7,1,7); % Current axes is 7
hPlot2speed = plot(xData.time,xData.NMOTW);% Engine Speed [rpm]
hPlot2speed.Color = 'blue';
hPlot2speed.LineWidth = 1;
set(hAxes{7},'ylim',[0 2600],'FontSize',nLabelSize);
ylabel('NMOTW [rpm]'); % Y label
xlabel('Time [s]'); % x label

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
savefig(hPlot2Fig,[sPath,'\NP_08 Window NOx Power Threshold 0']); % Save the figure to file
saveas(hPlot2Fig,[sPath,'\NP_08 Window NOx Power Threshold 0.png'],'png'); % Exporting the PNG figure
close(hPlot2Fig);
clear hPlot2Fig hPlot2Urea hPlot21Temperature hPlot22Temperature ...
    hPlot23Temperature hPlot2WinPowerPerc hPlot22WinPowerPerc hPlot2WinPowerThrd hPlot2Tmc ...
    hPlot21Nox hPlot22Nox hPlot23Nox hPlot24Nox hPlot2alt hPlot2speed ...
    hPlot2Vel hAxes hLegend nPlotMaxValue 


%% Plot3 NOx cold CF vs Percentile and NOx hot CF vs Percentile

hPlot3Fig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(2,1,1); % Creating a tiled plot with 2 rows 1 column & selecting the first tile as current axes
hPlot3ColdPT09CF = plot(xEuro6eColdResults_PT09.dIdxCF,xEuro6eColdResults_PT09.dCF); % Cold CF with PT 09
hPlot3ColdPT09CF.Color = 'blue';
hPlot3ColdPT09CF.LineWidth = 1;
hold on
hPlot3ColdPT10CF = plot(xEuro6eColdResults_PT10.dIdxCF,xEuro6eColdResults_PT10.dCF); % Cold CF with PT 10
hPlot3ColdPT10CF.Color = 'red';
hPlot3ColdPT10CF.LineWidth = 1;
hPlot3ColdPT10CF.LineStyle = '--';
ylabel('NOx Cold CF [-]'); % Y label
xlabel('Percentile [%]'); % X label
hLegend = legend('PT = 9%','PT = 10%');
hLegend.Location = 'north';
set(hAxes{1},'FontSize',nLabelSize,'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VIe NOx Confirmity Factor Cold','FontSize',nTitleSize);% setting the titlesize

hAxes{2} = subplot(2,1,2); % 2nd axis selected
hPlot3HotPT09CF = plot(xEuro6eHotResults_PT09.dIdxCF,xEuro6eHotResults_PT09.dCF); % Urea [g/h]
hPlot3HotPT09CF.Color = 'blue';
hPlot3HotPT09CF.LineWidth = 1;
hold on
hPlot3HotPT10CF = plot(xEuro6eHotResults_PT10.dIdxCF,xEuro6eHotResults_PT10.dCF); % Urea [g/h]
hPlot3HotPT10CF.Color = 'red';
hPlot3HotPT10CF.LineWidth = 1;
hPlot3HotPT10CF.LineStyle = '--';
ylabel('NOx Warm CF [-]'); % Y label
xlabel('Percentile [%]'); % X label
hLegend = legend('PT = 9%','PT = 10%');
hLegend.Location = 'north';
set(hAxes{2},'FontSize',nLabelSize,'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VIe NOx Confirmity Factor Warm','FontSize',nTitleSize);% setting the titlesize

%linkaxes([hAxes{:}],'xy'); % To link x axes of subplots
savefig(hPlot3Fig,[sPath,'\NP_06 Window NOx Confirmity Factor EUVIe']); % Save the figure to file
saveas(hPlot3Fig,[sPath,'\NP_06 Window NOx Confirmity Factor EUVIe.png'],'png'); % Exporting the PNG figure
close(hPlot3Fig);
clear hAxes hPlot3ColdPT09CF hPlot3HotPT10CF hPlot3HotPT09CF hPlot3ColdPT10CF...
      hPlot3Fig hLegend
%% Plot 4 Ambient Temperature and altiude
hPlot4Fig = figure('Position',get(0,'Screensize'));
hPlot4AmbTemp = scatter(xData.env_altitude_m, xData.TL); % 
ylim([-30 50]); % Setting the temperature limits in which the vehicle operates
xlim([0 2500]); % Setting the altitude limits in m
ylabel('Ambient Temperature [C]'); % Y label
xlabel('Altitude [m]'); % X label
set(gca,'FontSize',nLabelSize); % setting the label and tickmarks font size
title('Ambient Temperature Variation with Altitude','FontSize',nTitleSize);% setting the titlesize
savefig(hPlot4Fig,[sPath,'\NP_03 Temperature Altitude']); % Save the figure to file
saveas(hPlot4Fig,[sPath,'\NP_03 Temperature Altitude.png'],'png'); % Exporting the PNG figure
close(hPlot4Fig);
clear hPlot4Fig hPlot4AmbTemp

%% Plot5 EUVI c&d CF vs Percentile plot

hPlot5Fig = figure('Position',get(0,'Screensize'));% Creating a new figure window
hAxes{1} = subplot(2,1,1); % Creating a tiled plot with 2 rows 1 column & selecting the first tile as current axes
hPlot5EUVIcPT10CF = plot(xEuro6dResults_PT10.dIdxCF,xEuro6dResults_PT10.dCF); % Cold CF with PT 09
hPlot5EUVIcPT10CF.Color = 'blue';
hPlot5EUVIcPT10CF.LineWidth = 1;
hold on
hPlot5EUVIcPT20CF = plot(xEuro6cResults_PT20.dIdxCF,xEuro6cResults_PT20.dCF); % Cold CF with PT 10
hPlot5EUVIcPT20CF.Color = 'red';
hPlot5EUVIcPT20CF.LineWidth = 1;
hPlot5EUVIcPT20CF.LineStyle = '--';
ylabel('NOx CF [-]'); % Y label
xlabel('Percentile [%]'); % X label
hLegend = legend('PT = 10%','PT = 20%');
hLegend.Location = 'north';
set(hAxes{1},'FontSize',nLabelSize,'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VIc NOx Confirmity Factor','FontSize',nTitleSize);% setting the titlesize

hAxes{2} = subplot(2,1,2); % 2nd axis selected
hPlot5EUVIdPT09CF = plot(xEuro6dResults_PT09.dIdxCF,xEuro6dResults_PT09.dCF); % Urea [g/h]
hPlot5EUVIdPT09CF.Color = 'blue';
hPlot5EUVIdPT09CF.LineWidth = 1;
hold on
hPlot5EUVIdPT10CF = plot(xEuro6dResults_PT10.dIdxCF,xEuro6dResults_PT10.dCF); % Urea [g/h]
hPlot5EUVIdPT10CF.Color = 'red';
hPlot5EUVIdPT10CF.LineWidth = 1;
hPlot5EUVIdPT10CF.LineStyle = '--';
ylabel('NOx CF [-]'); % Y label
xlabel('Percentile [%]'); % X label
hLegend = legend('PT = 9%','PT = 10%');
hLegend.Location = 'north';
set(hAxes{2},'FontSize',nLabelSize,'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VId NOx Confirmity Factor','FontSize',nTitleSize);% setting the titlesize

%linkaxes([hAxes{:}],'xy'); % To link x axes of subplots
savefig(hPlot5Fig,[sPath,'\NP_05 Window NOx Confirmity Factor EUVIc & EUVId']); % Save the figure to file
saveas(hPlot5Fig,[sPath,'\NP_05 Window NOx Confirmity Factor EUVIc & EUVId.png'],'png'); % Exporting the PNG figure
close(hPlot5Fig);
clear hAxes hPlot5EUVIdPT10CF hPlot5EUVIdPT09CF hPlot5EUVIcPT20CF hPlot5EUVIcPT10CF...
      hPlot5Fig hLegend

%% EU VIc Plots

nYLimit = max(xEuro6dResults_PT00.dWindowNoxAvgOPowerValid); % yaxis limit
hEUVIcFig = figure('Position',get(0,'Screensize'));% Creates a new figure window and maximize it
hAxes{1} = subplot(2,1,1); % Creating a tiled plot with 2 rows 1 column & selecting the first tile as current axes
hPlot1kWhWindow = plot(x1kWhWindow.dTime1Hz,x1kWhWindow.dWindowNoxAvgOPowerValid); % 1kWh average value of NOX
hPlot1kWhWindow.Color = [.3 .3 .3]; % grey colour
hPlot1kWhWindow.LineStyle = '--'; % Line style
hold on
hPlotEuro6c_PT00 = plot(xEuro6dResults_PT00.dTime1Hz,xEuro6dResults_PT00.dWindowNoxAvgOPowerValid); % Plotting the window value nox vs time
hPlotEuro6c_PT00.Color = 'green';
hPlotEuro6c_PT00.LineWidth = 1;
hold on
hPlotEuro6c_PT10 = plot(xEuro6dResults_PT10.dTime1Hz,xEuro6dResults_PT10.dWindowNoxAvgOPowerValid); % Plotting the window value nox vs time
hPlotEuro6c_PT10.Color = 'blue';
hPlotEuro6c_PT10.LineWidth = 1;
hPlotEuro6c_PT10.LineStyle = '--'; % Line style
hold on
hPlotEuro6c_PT20 = plot(xEuro6cResults_PT20.dTime1Hz,xEuro6cResults_PT20.dWindowNoxAvgOPowerValid); % Plotting the window value nox vs time
hPlotEuro6c_PT20.Color = 'red';
hPlotEuro6c_PT20.LineWidth = 1;
%hPlotEuro6c_PT20.LineStyle = '--'; % Line style
legend('NOx 1kWh','Window NOx PT 0','Window NOx PT 10','Window NOx PT 20');
if ~isnan(nYLimit)
    set(hAxes{1},'ylim',[0 nYLimit]);
end
ylabel('NOx [g/kWh]'); % Y label
%xlabel('Time [s]'); % X label
set(gca,'FontSize',nLabelSize,'Xticklabel',[],'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('Euro VIc NOx','FontSize',nTitleSize);% setting the titlesize

hAxes{2} = subplot(2,1,2); % Creating a tiled plot with 2 rows 1 column & selecting the first tile as current axes
hPlotEuro6cLeft = plot(xEuro6cResults_PT20.dTime1Hz,xEuro6cResults_PT20.dWindowPowerAvg); % Plotting the window value nox vs time
hPlotEuro6cLeft.Color = [1 .843137 0];
hPlotEuro6cLeft.LineWidth = 1;
ylabel('Avg Power [kW]'); % Y label
%xlabel('Time [s]'); % X label
% nMaxLimit = max(xEuro6dResults_PT10.dWindowPowerAvg); % Finding the maximum work for setting the axes limit
% if ~isnan(nMaxLimit)
% ylim([0 nMaxLimit]); % Setting the Y axis limit
% end
nPlotLim = get(gca,'YLim');% get the lower and higher limits of the plot
set(gca,'YTick',linspace(nPlotLim(1),nPlotLim(2),6));% to put yticks at specified points
set(gca,'YLim',nPlotLim);% Setting the plot limits
set(gca,'FontSize',nLabelSize); % setting the label and tickmarks font size
hold on;
yyaxis right; % Add a yaxis to the right
hPlotEuro6cRight = plot(xEuro6cResults_PT20.dTime1Hz,xEuro6cResults_PT20.dWindowPercentAvgPower); % Plotting the window value of Relative Power
hPlotEuro6cRight.Color = [.309804 .309804 .184314];
%hPlotEuro6cRight.LineStyle = '--';
hPlotEuro6cRight.LineWidth = 1;
set(gca,'ycolor','black'); % for setting the axes colour as black
hold on 
dPowerThreshold(:,1)=20;% EUVIc PT is 20%
hPlotEuro6cRight2 = plot(xEuro6cResults_PT20.dTime1Hz,dPowerThreshold); % Plotting the window value of Relative Power
hPlotEuro6cRight2.Color = 'red';
hPlotEuro6cRight2.LineStyle = '--';
hPlotEuro6cRight2.LineWidth = 1;
hold on 
dPowerThreshold(:,1)=10;% EUVId PT is 20%
hPlotEuro6cRight3 = plot(xEuro6cResults_PT20.dTime1Hz,dPowerThreshold); % Plotting the window value of Relative Power
hPlotEuro6cRight3.Color = 'blue';
hPlotEuro6cRight3.LineStyle = '--';
hPlotEuro6cRight3.LineWidth = 1;

nPlotMaxValue = max(xEuro6cResults_PT20.dWindowPercentAvgPower);
if ~isnan(nPlotMaxValue)
    if nPlotMaxValue>50
        set(gca,'YTick',linspace(0,100,6));% to put yticks at specified points
        set(gca,'YLim',[0 100]);% Setting the plot limits
    elseif nPlotMaxValue>0&&nPlotMaxValue<=50
        set(gca,'YTick',linspace(0,50,6));% to put yticks at specified points
        set(gca,'YLim',[0 50]);% Setting the plot limits
    else
        disp('Unexpected Error in Window power plotting');
    end
end
set(gca,'ycolor','black'); % for setting the axes colour as black
ylabel('Relative Power [%]'); % Y label
xlabel('Time [s]');% x label
hLegend = legend('Window Power','Relative Window Power', 'EU VIc Power Threshold', 'EU VId Power Threshold');
%hLegend.Location = 'northwest';
set(gca,'FontSize',nLabelSize,'XGrid','on','YGrid','on'); % setting the label and tickmarks font size
title('EU VIc Window Power, Relative Window Power & Power Threshold','FontSize',nTitleSize);% setting the titlesize

linkaxes([hAxes{:}],'x'); % To link x axes of subplots
savefig(hEUVIcFig,[sPath,'\NP_04 Window NOx & Power EUVIc']); % Save the figure to file
saveas(hEUVIcFig,[sPath,'\NP_04 Window NOx & Power EUVIc.png'],'png'); % Exporting the PNG figure
close (hEUVIcFig);
clear hAxes hLegend nYLimit hEUVIcFig hPlot1kWhWindow hPlotEuro6c_PT00 hPlotEuro6c_PT10 hPlotEuro6c_PT20 hPlotEuro6cLeft hPlotEuro6cRight hPlotEuro6cRight2 hPlotEuro6cRight3;

fprintf('\nWindow NOx Calculation Finished\n');