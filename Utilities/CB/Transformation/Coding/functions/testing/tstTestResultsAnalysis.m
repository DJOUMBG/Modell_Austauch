function [sTestResult,sFailReport] = tstTestResultsAnalysis(oResultList)
% TSTTESTRESULTSANALYSIS creates a result string from test result objects.
%
% Syntax:
%   [sTestResult,sFailReport] = tstTestResultsAnalysis(oResultList)
%
% Inputs:
%   oResultList - object (nxm): matlab.unittest.TestResult objects
%
% Outputs:
%   sTestResult - string: test result summary as table format
%   sFailReport - string: report of each failed test
%
% Example: 
%   [sTestResult,sFailReport] = tstTestResultsAnalysis(oResultList)
%
%
% Subfunctions: getResultReportString
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-14

%% arguments

% check number of arguments
if nargin > 1 || nargin < 1
    error('Incorrect number of arguments. Argument number is %d.',...
        nargin);
end

% object class of input argument
sInArgType = 'matlab.unittest.TestResult';

% check class type of argument
if ~isa(oResultList,sInArgType)
    error('Argument %s is not from expected type %s but from type %s.',...
        'oResultList',sInArgType,class(oResultList));
end

%% result string

% convert to table
tResults = table(oResultList);  %#ok called with evalc

% get table as string
sTestResult = evalc('disp(tResults)');


%% fail report string

% init fail report string
sFailReport = '';

% collect details of failed tests
for nResNum=1:numel(oResultList)
    % current test result
    oResult = oResultList(nResNum);
    % check for failure
    bFailed = oResult.('Failed');
    % follow up if failed
    if bFailed
        % get details from test result
        xDetails = oResult.('Details');
        % get report string from test result details
        sResultReport = getResultReportString(xDetails);
        % add report to fail reports
        sFailReport = sprintf('%s\n\n%s',sFailReport,sResultReport);
    end
end

return

% =========================================================================

function sResultReport = getResultReportString(xDetails)
% GETRESULTREPORTSTRING returns the report string from a 
% matlab.unittest.TestResult, only if test failed.
%
% Syntax:
%   sResultReport = getResultReportString(xDetails)
%
% Inputs:
%   xDetails - structure with fields:
%       see matlab.unittest.TestResult.Details
%
% Outputs:
%   sResultReport - string: formatted string with test report
%
% Example: 
%   sResultReport = getResultReportString(xDetails)

% init output string
sResultReport = 'WARNING: No report was created during test!';

% get report string from details
if isfield(xDetails,'DiagnosticRecord')
    if isprop(xDetails.('DiagnosticRecord'),'Report')
        sResultReport = xDetails.('DiagnosticRecord').('Report');
    end
end

return
