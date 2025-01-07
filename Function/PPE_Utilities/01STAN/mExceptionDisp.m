function mExceptionDisp(MException,nTarget)
% MEXCEPTIONDISP create thorough MException display with links to open files in command window via
% fprintf alike standard error stack display.
%
% Syntax:
%   mExceptionDisp(MException)
%
% Inputs:
%   MException - standard Matlab exception object with stack structure
%
% Outputs:
%   <Command window display of error message and stack trace with opentoline links>
% Example: 
%   mExceptionDisp(struct('message',{'Some test exception'},'stack',{struct('file',{which('mExceptionDisp'),which('mExceptionDisp')},'line',{14,24},'name',{'mExceptionDisp','mExceptionDisp'})}))
% 
% See also: fprintf, MException
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2023-02-02

% check input
if nargin < 2
    nTarget = 2;
end

% create command window output
fprintf(nTarget,'  %s\n',MException.message);
for nIdxStack = 1:numel(MException.stack)
    xStack = MException.stack(nIdxStack);
   fprintf(nTarget,'   Error (stack %i) in <a href="matlab:opentoline(''%s'',%i)">%s (line %i)</a>\n',...
           nIdxStack,xStack.file,xStack.line,xStack.name,xStack.line);
end
return
