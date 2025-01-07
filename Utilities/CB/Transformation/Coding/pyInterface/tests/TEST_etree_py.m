close all
clear
clc

cd(fileparts(mfilename('fullpath')));

% DIVe config xml
sConfigXml = 'D:\DIVe\ddc_dev\Configuration\Vehicle_Other\DIVeCBdev\devCB_minimal_sfcn.xml';

% Silver Python
sPythonExe = 'C:\scApps\Silver\U-2023.03\common\ext-tools\python3\python.exe';

% Script path
sPyScript = 'test_etree.py';

% Call script
[code,txt] = system([sPythonExe,' ',sPyScript,' ',sConfigXml],'-echo');

