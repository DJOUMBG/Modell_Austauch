function oResults = tstTestRunSilent(sTestSuite)
% TSTTESTRUNSILENT runs a test suite function file in silent but creates
% also detailed information on the results.
%
% Syntax:
%   oResults = tstTestRunSilent(sTestSuite)
%
% Inputs:
%   sTestSuite - string: filepath or name of test suite function
%
% Outputs:
%   oResults - object (nxm): matlab.unittest.TestResult objects
%
% Example: 
%   oResults = tstTestRunSilent(sTestSuite)
%
%
% See also: matlab.unittest.TestRunner, 
%   matlab.unittest.plugins.DiagnosticsRecordingPlugin
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
sInArgType = 'char';

% check class type of argument
if ~isa(sTestSuite,sInArgType)
    error('Argument %s is not from expected type %s but from type %s.',...
        'sTestSuite',sInArgType,class(sTestSuite));
end

% check if file exists
if ~chkFileExists(sTestSuite)
    error('The test suite file %s does not exist.',sTestSuite);
end


%% run tests

% create test suite objects and test runner
oSuite = testsuite(sTestSuite);
oRunner = matlab.unittest.TestRunner.withNoPlugins;
oRunner.addPlugin(matlab.unittest.plugins.DiagnosticsRecordingPlugin);

% run silent (capture console output with evalc)
evalc('oResults = run(oRunner,oSuite);');

return