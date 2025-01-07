function [sReport,oResults] = tstTestReportGet(sTestsuite)
% TSTTESTREPORTGET runs all tests in testsuite and returns the test report
% string and the test result object.
%
% Syntax:
%   [sReport,oResults] = tstTestReportGet(sTestsuite)
%
% Inputs:
%   sTestsuite - string: function name of testsuite 
%
% Outputs:
%    sReport - string: report string with test results
%	oResults - object (nxm): matlab.unittest.TestResult objects
%
% Example: 
%   [sReport,oResults] = tstTestReportGet(sTestsuite)
%
%
% See also: tstTestResultsAnalysis, tstTestRunSilent
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-19

%% run tests and create report string

oResults = tstTestRunSilent(sTestsuite);
[sTestResult,sFailReport] = tstTestResultsAnalysis(oResults);
sReport = sprintf('%s\n%s\n',sTestResult,sFailReport);

return