function bValid = silCheckSfcnModelIsStd(sContext,sFamily,sModelSet)
% SILCHECKSFCNMODELISSTD returns if tupel is standard sfuntion from context
% control, family sil (privious Python function: checkIfSfunForSilver)
%
% Syntax:
%   bValid = silCheckSfcnModelIsStd(sContext,sFamily,sModelSet)
%
% Inputs:
%    sContext - string: DIVe context 
%     sFamily - string: DIVe family 
%   sModelSet - string: model set 
%
% Outputs:
%   bValid - boolean (1x1): flag if tupel is valid 
%
% Example: 
%   bValid = silCheckSfcnModelIsStd(sContext,sFamily,sModelSet)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-10

%% check for model

if strcmp(sContext,'ctrl') && strcmp(sFamily,'sil') && strncmp(sModelSet,'sfcn',4)
    bValid = true;
else
    bValid = false;
end

return