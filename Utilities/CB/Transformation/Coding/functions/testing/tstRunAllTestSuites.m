function [sTestReport,oTestResults] = tstRunAllTestSuites(sTestsuiteFolderpath)
% TSTRUNALLTESTSUITES runs all test suite files in given folder.
%
% Syntax:
%   [sTestReport,oTestResults] = tstRunAllTestSuites(sTestsuiteFolderpath)
%
% Inputs:
%   sTestsuiteFolderpath - string: folderpath with matlab test suite files 
%
% Outputs:
%    sTestReport - string: report of tests
%   oTestResults - object (nxm): matlab.unittest.TestResult objects
%
% Example: 
%   [sTestReport,oTestResults] = tstRunAllTestSuites(sTestsuiteFolderpath)
%
%
% See also: tstTestReportGet, fleFilesGet, sepLine
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-16

%% run test suites

% check folder exists
if ~chkFolderExists(sTestsuiteFolderpath)
    error('Test suite folder "%s" does not exist.',...
        sTestsuiteFolderpath);
end

% get test suite files from folder
cTestsuiteFilelist = fleFilesGet(sTestsuiteFolderpath,'.m');

% init test report string and result list
sTestReport = '';
oTestResults = matlab.unittest.TestResult.empty;

% run each test suite
for nTestNum=1:numel(cTestsuiteFilelist)
    % run tests
    [sReport,oResults] = tstTestReportGet(cTestsuiteFilelist{nTestNum});
    % collect reports and results
    sTestReport = sprintf('%s\n%s%s\n%s\n',...
        sTestReport,sepLine,sepLine,sReport);
    oTestResults = [oTestResults,oResults]; %#ok
end

return