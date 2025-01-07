close all
clear
clc

cd(fileparts(mfilename('fullpath')));

%% preferences

% DESCRIPTION: copy filepaths of config xmls into file LIST_cbtTrafo.txt

% configuration xml file list
cConfigXmlFiles = fleGetPathListFromFile('Z_LISTS\LIST_cbtTrafo.txt');

% workspace root
sWorkspaceRoot = 'D:\DIVe\ddc_dev';

% transformation type => ATTENTION: Not like startDIVeCodeBased.m !
%       0: open Silver GUI stopped
%       1: run simulation with Silver GUI
%       2: only transform configuration
%       3: island transformation (outdated)
%       4: run silent simulation (regression)
nRunType = 2;


%% run transformation

addpath(sWorkspaceRoot);
for nFile=1:numel(cConfigXmlFiles)
    dveRunCbTrafoForList(cConfigXmlFiles,sWorkspaceRoot,'',nRunType);
end
