function [sPath,sId] = dqsFolderCreate(xSim)
% DQSFOLDERCREATE create folder for simulation case
%
% Syntax:
%   [sPath,sId] = dqsFolderCreate(sConfig,sUser)
%
% Inputs:
%   xSim - struct (1x1) with fields
%    .pathWork      - string with working directoy
%    .configuration - string with configuration depot path
%    .user          - string with user ID
%
% Outputs:
%   sPath - string of file system path for Perforce Helix client
%     sId - string of unique ID based on Configuration name and user ID
%
% Example: 
%   [sPath,sId] = dqsFolderCreate('C:\DQS\','//DIVe/d_main/com/DIVe/Configuration/Vehicle_Other/DIVeDevelopment/CosimCheckTime.xml','rafrey5')
%
% See also: dpsFcnIdCreate, dsim, dqsPipeline
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2023-08-01

% create unique ID for folder differentiation
vTime = round(datevec(now));
sId = dpsFcnIdCreate(xSim.configuration,xSim.user,vTime*[0 0 0 3600 60 1]');

% date and time information
vNow = now;
vDate = datevec(vNow);
sDatetime = sprintf('%02i%02i%02i%02i%02i%02.0f',vDate - [2000 0 0 0 0 0]);
    
% define working directory
sFolder = strGlue({sDatetime(7:12),sId},'_');
sPath = fullfile(xSim.pathWork,sDatetime(1:6),sFolder);

mkdir(sPath);
return
