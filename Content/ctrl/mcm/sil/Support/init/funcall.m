function funcall(functionname,varargin)
% FUNCALL support file for GOLEM submit function for MATLAB function
% evaluation in outline mode. This modes open a new MATLAB instance for
% every function evaluation. funcall closes this new MATLAB instance after
% function evaluation.
%
% Syntax:
%   funcall(functionname,varargin)
%
% Inputs:
%   functionname - function name to be evaluated
%       varargin - cell containing the optional function arguments
%
% Outputs:
%
% Example: 
%   funcall(functionname,varargin)
%
% See also: feval 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2010-01-28

disp('start function evaluation')
try
    if nargin == 1
        feval(functionname);
    else
        feval(functionname,varargin{:});
    end
catch %#ok
    larr = lasterror; %#ok
    disp(['Function evaluation ends with error',larr.message]);
    exit;
end

exit;
return