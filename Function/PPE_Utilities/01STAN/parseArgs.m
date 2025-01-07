function [xArg,cRest] = parseArgs(cArgDefault,varargin)
% PARSEARGS parse arguments according default cell. Argument names are
% handled case insensitive. Non-conform/not processed arguments are passed
% as output.
%
% Syntax:
%   xArg = parseArgs(cArgDefault,varargin)
%   [xArg,cRest] = parseArgs(cArgDefault,varargin)
%
% Inputs:
%   cArgDefault - cell (mx3) with 
%                   (m,1) - string with argument parameter name
%                   (m,2) - default value of argument
%                   (m,3) - [optional] string with variable name of
%                           argument in cell (otherwise = (m,1))
%      varargin - cell with arbitrary numer of parameter & value pairs
%
% Outputs:
%    xArg - structure with fields: 
%           <argument variable name>
%   cRest - cell (1xn) with arguments, which do not comply with argument/
%           value pairs
%
% Example: 
%   [xArg,cRest] = parseArgs({'Arg1','StringValue','sArg1';'Arg2',3,[]},'arg1','bla','aRG2',2)
%   xArg = parseArgs({'Arg1','StringValue','sArg1';'Arg2',3,[]},varargin{:})
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-13

% initialization with default structure
xArg = struct;
for nIdxArg = 1:size(cArgDefault,1)
    if isempty(cArgDefault{nIdxArg,3}) % no variable/field name specified
        xArg.(cArgDefault{nIdxArg,1}) = cArgDefault{nIdxArg,2}; % use argument name as variable name
    else
        xArg.(cArgDefault{nIdxArg,3}) = cArgDefault{nIdxArg,2}; % use specific variable name
    end
end

% parse arguments
nIdxArg = 1;
nRest = [];
while nIdxArg < numel(varargin)
    [bValid,nID] = ismember(lower(varargin{nIdxArg}),lower(cArgDefault(:,1)));
    if bValid % argument valid
        if isempty(cArgDefault{nID,3}) % no variable/field name specified
            xArg.(cArgDefault{nID,1}) = varargin{nIdxArg+1}; % use argument name as variable name
        else
            xArg.(cArgDefault{nID,3}) = varargin{nIdxArg+1}; % use specific variable name
        end
        nIdxArg = nIdxArg + 2;
    else
        % no match - mark argument for "rest"
        nRest = [nRest nIdxArg]; %#ok<AGROW>
        nIdxArg = nIdxArg + 1;
    end % if argument valid
end % for each argument pair

% collect final rest argument
if nIdxArg == numel(varargin)
    nRest = [nRest nIdxArg];
end

% prepare "rest" argument cell
cRest = varargin(nRest);
return
