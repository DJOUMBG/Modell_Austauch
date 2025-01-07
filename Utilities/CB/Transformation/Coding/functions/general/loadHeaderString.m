function loadHeaderString
% LOADHEADERSTRING creates a DIVe function header string of the marked
% function head from clipboard.
%
% Usage:
% 1. Create a function file and save it
% 2. Add folder with this function to Matlab path (see addpath)
% 3. Create a function head, e.g.:
%       function [out1,out2] = testFunc(in1,in2)
% 4. Mark this function head and press "ctrl + c" to copy
% 5. Run current function "loadHeaderString"
% 6. Wait for function to be finished (message in Command Window)
% 7. Paste function header string with "ctrl + v"
%
% Syntax:
%   loadHeaderString
%
% Inputs:
%
% Outputs:
%
% Example: 
%   loadHeaderString
%
%
% Other m-files required: add DIVe folder "Function" to Matlab path
%
% See also: createFuncHeaderDoc
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-10-06

%% create function header string

clc;
disp('Please wait for creation of function header string ...');
createFuncHeaderDoc;
disp('Paste header string with "ctrl + v".');

return