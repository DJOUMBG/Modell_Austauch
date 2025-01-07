function [cValues,sMsg,bValid] = fleIniFileGetValues(cNameValues,cNames)
% FLEINIFILEGETVALUES returns the parameter-values of the defined
% parameter-names from an output of ini-File read (see fleIniFileRead).
%
% Syntax:
%   [cValues,sMsg,bValid] = fleIniFileGetValues(cNameValues,cNames)
%
% Inputs:
%   cNameValues - cell (mxn): name-value pairs defined as assignment in ini-File  
%       cNameValue(:,1): name  of ini-parameter
%       cNameValue(:,2): value of ini-parameter 
%        cNames - cell (mxn): parameter-names for which the values have to be returned 
%
% Outputs:
%   cValues - cell (mxn): parameter-values of parameter-names 
%      sMsg - string: message if analysis fails 
%    bValid - boolean (1x1): status of analysis, true if successful, false if not  
%
% Example: 
%   [cValues,sMsg,bValid] = fleIniFileGetValues(cNameValues,cNames)
%
%
% See also: fleIniFileRead
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-19


%% analyse name-value pairs of 

% init output
cValues = {};
sMsg = '';
bValid = true;

% get single columns for names and values
cNameList = cNameValues(:,1);
cValueList = cNameValues(:,2);

% check each names
for nName=1:numel(cNames)
    
    % current name
    sName = cNames{nName};
    
    % logical position of name-value pair in list
    bPosArray = strcmp(cNameList,sName);
    nNumber = sum(bPosArray);
    
    % error handling if paremeter-name is not defined in name list
    if nNumber == 0
        sMsg = sprintf('Parameter "%s" was not found.',sName);
        bValid = false;
        return;
    end
    
    % error handling if parameter-name appears several times in name list
    if nNumber > 1
        sMsg = sprintf('Parameter "%s" was defined several times.',sName);
        bValid = false;
        return;
    end
    
    % return value of name
    cCurValue = cValueList(bPosArray);
    
    % append lists
    cValues = [cValues;cCurValue]; %#ok<AGROW>
    
end

return