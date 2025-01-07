close all
clear
clc

cd(fileparts(mfilename('fullpath')));

%% *** description ***

% script tests the functionality of function startDIVeCodeBased.m


%% user preferences

% define DIVe workspace 
sWorkspaceRoot = 'D:\DIVe\ddc_dev';


%% run tests

% create test instance
testObj = testClass_startDIVeCodeBased(sWorkspaceRoot);

% run tests
oResults = run(testObj);
