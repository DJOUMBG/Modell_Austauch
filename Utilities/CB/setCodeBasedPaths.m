function setCodeBasedPaths(sWorkspacePath)
% SETCODEBASEDPATHS add all scripting paths of DIVe CodeBased to Matlab
% path
%
% Syntax:
%   setCodeBasedPaths
%   setCodeBasedPaths(sWorkspacePath)
%
% Inputs:
%   sWorkspacePath - string [optional]:
%       rootpath of local DIVe workspace
%
%
% Example: 
%   setCodeBasedPaths(sWorkspacePath)
%
%
% Author: Elias Rohrer, TE/PTC-H, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-05-06

% get current path
sCbUtilitiesPath = fullfile(fileparts(mfilename('fullpath')));

if nargin < 1
    % get workspace path from current location
    sWorkspacePath = fullfile(fileparts(fileparts(sCbUtilitiesPath)));
    if not(exist(sWorkspacePath,'dir'))
        error('No workspace path could be found.');
    end
end

% create DIVe function path
sDiveFunctionPath = fullfile(sWorkspacePath,'Function');
if not(exist(sDiveFunctionPath,'dir'))
    error('DIVe function path "%s" does not exist.',sDiveFunctionPath);
end

% create CB function path
sCbFunctionPath = fullfile(sCbUtilitiesPath,'Transformation','Coding','functions');
if not(exist(sCbFunctionPath,'dir'))
    error('Cb function path "%s" does not exist.',sCbFunctionPath);
end

% create CB class path
sCbClassPath = fullfile(sCbUtilitiesPath,'Transformation','Coding','classes');
if not(exist(sCbClassPath,'dir'))
    error('Cb class path "%s" does not exist.',sCbClassPath);
end

% add paths to Matlab path
addpath(genpath(sDiveFunctionPath));
addpath(genpath(sCbFunctionPath));
addpath(genpath(sCbClassPath));

end % setCodeBasedPaths
