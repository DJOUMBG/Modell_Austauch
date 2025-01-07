close all
clear
clc

% wheel package
sPackage = 'lxml';

% path to wheel file
sWheelFilePath = 'D:\DIVe\dac_main\Utilities\CB\python_wheels';

% silver python exe
sSilverPyExe = fullfile(getenv('SILVER_HOME'),'common\ext-tools\python3\python.exe');

% call instalation
sArgs =  '-m pip install --no-index --find-links=';
[code,txt] = system([sSilverPyExe,' ',sArgs,sWheelFilePath,' ',sPackage],'-echo');