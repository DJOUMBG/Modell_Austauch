function [nOutPerc,nOutCF,dOutCF,dIdxCF] = pnt_PercentileCalc(dData,nPercentile)
%pnt_PercentileCalc function takes the data vector and the required percentile
%as input removes the NaN values from the data and gives the
%percentile data as nOutput
% Syntax:
%   pnt_PercentileCalc(dData,nPercentile)
%
% Inputs:
%                 dData : Vector of length (nX1) for which percentile has
%                         to be found
%           nPercentile : Constant percentile value which is required (1X1)
%                         range is from 0 to 100
% Outputs:
%              nOutPerc : Value of Size (1X1) in unit g/kWh
%                nOutCF : CF value for the given percentile
% Example:
% pnt_PercentileCalc(dData,nPercentile)
%               Author: Ajesh Chandran, RDI/TBP, MBRDI
%                Phone: +91-80-6149-6368
%               MailTo: ajesh.chandran@daimler.com
%    Date of Creation : 2019-09-16
% Date of Modification:
%  Userid Modification:
% Modification Content:
%%
dData = dData(~isnan(dData)); % To Remove all the NaN values before sorting
if ~isempty(dData)
    dDataSorted = sort(dData); % Data after sorting from small to large
    nIdxPercentile = max(1,floor((nPercentile/100)*length(dData))); % To find the index corresponding to the percentile
    % floor function is used to make the value round to the
    % integer value
    
    nOutPerc = dDataSorted(nIdxPercentile); % Percentile value of NOx in g/kWh
    nOutCF = nOutPerc/0.46; % CF = Value of NOx in the window / the Euro limit
else
    %fprintf('\n None of the windows are valid\n');
    nOutPerc = nan;
    nOutCF = nan; % CF = Value of NOx in the window / the Euro limit
    
end
%% Vector Caculation for plotting
dIdxPercentile = ones(100,1); % Memory allocation
dOutPerc = zeros(100,1);% Memory Allocation
if ~isempty(dData)
    for nIdx = 1:1:100
        dIdxPercentile(nIdx,1) = max(1,floor((nIdx/100)*length(dData)));
        % maximum function is used for avoiding 0 index
        dOutPerc(nIdx,1) = dDataSorted(dIdxPercentile(nIdx,1));
    end
else
    dOutPerc = zeros(100,1);
end
dOutCF = dOutPerc/0.46; % CF vector
dIdxCF = (1:1:100)';


end

