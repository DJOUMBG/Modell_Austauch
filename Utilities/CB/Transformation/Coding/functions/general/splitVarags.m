function [cNames,cValues,bValid] = splitVarags(cVarargs)
% SPLITVARAGS splits a varargin cell array into a name array and a value
% array.
%
% Syntax:
%   [cNames,cValues,bValid] = splitVarags(cVarargs)
%
% Inputs:
%   cVarargs - cell (mxn): varargin cell array from function
%
% Outputs:
%    cNames - cell of strings (mxn): array with names of varargins
%   cValues - cell (mxn): array with values for every name
%    bValid - boolean (1x1): flag, if splitting was successful (true) or not(false) 
%
% Example: 
%   [cNames,cValues,bValid] = splitVarags(cVarargs)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-15

%% split name-value pairs

% init output
cNames = {};
cValues = {};
bValid = true;

% check for even number of varargs
if mod(numel(cVarargs),2)
    bValid = false;
    return;
end

% reshape vargag cell array to two column matrix
cVarargMat = reshape(cVarargs,2,numel(cVarargs)/2)';

% split names and values
cNames = cVarargMat(:,1);
cValues = cVarargMat(:,2);

% check if names are from type char
if ~iscellstr(cNames)
    bValid = false;
    return;
end

return