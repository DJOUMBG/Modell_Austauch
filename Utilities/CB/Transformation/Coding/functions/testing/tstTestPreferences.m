function xTestPrefs = tstTestPreferences
% TSTTESTPREFERENCES returns the preference structure for unit tests. The
% user can define all necessary preferences in this function.
%
% Syntax:
%   xTestPrefs = tstTestPreferences
%
% Inputs:
%
% Outputs:
%   xTestPrefs - structure with fields:
%       .sDiveRootFolderpath: folderpath to the DIVe workspace root
%
% Example: 
%   xTestPrefs = tstTestPreferences
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-14


%% *** DEFINIE PREFERENCES HERE! ***
% ATTENTION: Please do not change fields of structure, if they already
% exsists !

xTestPrefs.sDiveRootFolderpath = 'D:\DIVe\ddc_dev';
xTestPrefs.sConfigXmlExample = 'D:\DIVe\ddc_dev\Configuration\Vehicle_Other\DIVeDevelopment\CosimCheckTime_sfunction.xml';

end