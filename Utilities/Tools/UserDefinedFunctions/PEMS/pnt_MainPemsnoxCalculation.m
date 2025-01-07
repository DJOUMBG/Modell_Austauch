function pnt_MainPemsnoxCalculation(sPath)
%pnt_MainPemsnoxCalculation Calculates the windows and CF from DIVe output file
%
% Syntax:
%   pnt_MainPemsnoxCalculation(sPath)
%
%
% Inputs:
%       sPath : Complete path of the results folder
%
% Outputs:
%
% Example:
%   pnt_MainPemsnoxCalculation('D:\936DTC\200408_150420_EU_Arocs_K_4x2_2017_FEPO_PEMS_2032_detPP_8t_Case07_AJCHAND')
%
% See also:  pnt_ResultsAccumulate pnt_FormulaCalc pnt_NoxCalculation
%            pnt_PercentileCalc pnt_WindowCalculation pnt_WindowCalculation
%
% Author: Ajesh Chandran, RD I/TBP, MBRDI
%  Phone: +91-80-6149-6368
% MailTo: ajesh.chandran@daimler.com
%   Date: 2020-02-18

%% Get the location of results folder


% [sPath] = uigetdir(pwd,'Select the folder with DIVe Results');
% if sPath==0
%     fprintf('Folder not selected\n');% Error Message
%     return; % End the evaluation
% end


[sFilename]= pnt_ResultsAccumulate(sPath); % Function will return the processed mat file
[sFilename]= pnt_FormulaCalc(sFilename); % Function will return the processed mat file
pnt_Cnfg_V1(sPath,sFilename);
[sPathFull] = pnt_NoxCalculation(sFilename); % Function for Window NOx Calculation
pnt_CreatePowerpoint(sPathFull); % Function for creating the powerpoint presentation
[sResultPath,~,~] = fileparts(sPathFull); % Getting the folder location
delete([sResultPath,'\NP_*.png']); % Deletes all the png files
delete([sResultPath,'\NP_*.fig']); % Deletes all the fig files
fprintf('\nSuccess \n');

end