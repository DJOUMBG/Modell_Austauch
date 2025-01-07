close all
clear
clc

cd(fileparts(mfilename('fullpath')));

%% define workspace

sWorkspaceRoot = 'D:\DIVe\ddc_dev';


%% template creation

% create constant object
oCONST = cbtClassTrafoCONST(sWorkspaceRoot,...
    fullfile('data','template_testcase.xml'),false);

% create template creation class
oTemplates = cbtClassSfuTemplates(oCONST);

% run template creation method
oTemplates.createSfuTemplates;
