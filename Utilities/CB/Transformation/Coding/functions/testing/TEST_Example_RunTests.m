close all
clear
clc

cd(fileparts(mfilename('fullpath')));

%% Run test

sTestSuite = 'tstExample_solverTest.m';

oResults = tstTestRunSilent(sTestSuite);
[sTestResult,sFailReport] = tstTestResultsAnalysis(oResults);
disp(sTestResult);
disp(sFailReport);
