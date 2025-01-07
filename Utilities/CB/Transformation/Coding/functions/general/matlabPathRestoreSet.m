function sPrePath = matlabPathRestoreSet(sPostPath)
% MATLABPATHRESTORESET restores the Matlab search path by removing all user
% added paths and then add new user paths. 
% It also resturns the path before reset.
%
% Syntax:
%   (see Example)
%
% Inputs:
%   sPostPath - string: path string with path seperator containing paths 
%       that should be added to path after reset 
%
% Outputs:
%   sPrePath - string: path string with path seperator containing the paths 
%       in Matlab search path before reset  
%
% Example: 
%   sPrePath = matlabPathRestoreSet(sPostPath)
%       - removes user added paths from Matlab search path
%       - add user paths defined in sPostPath to Matlab search path
%       - returns the Matlab search path string before reset
%
%   matlabPathRestoreSet(sPostPath)
%       - resets user added paths in Matlab search path
%       - add user paths defined in sPostPath to Matlab search path
%
%   sPrePath = matlabPathRestoreSet
%       - removes user added paths from Matlab search path
%       - returns the Matlab search path string before reset
%
%   matlabPathRestoreSet
%       - only removes user added paths from Matlab search path
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-02

%% restore Matlab path

% get current path
sPrePath = path;

% reset Matlab path
warning('off','all');
restoredefaultpath;

% add new paths
if nargin > 0
    addpath(sPostPath);
end
warning('on','all');

return