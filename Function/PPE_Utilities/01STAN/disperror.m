function disperror(xError)
% DISPERROR display a Matlab stack structure alike a Matlab error output.
% This includes affected functions and current lines of code execution.
%
% Syntax:
%   disperror(xError)
%
% Inputs:
%   xError - structure with fields of "lasterror" output
%
% Outputs:
%
% Example: 
%   disperror(lasterror)
%
% See also: lasterror, dbstack
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2007-06-01

if nargin == 0
    xError = lasterror; %#ok<LERR>
end

if isempty(xError.stack)
    disp('Error stack is empty.');
else
    disp(['Error (Display) using ==> <a href="matlab: '... 
          'opentoline(''' xError.stack(1).file ''',' num2str(xError.stack(1).line) ')">' ...
          xError.stack(1).name ' at ' num2str(xError.stack(1).line) '</a>']);
    disp(xError.message);
    for k = 2:length(xError.stack)
        disp(['<a href="matlab: '...
              'opentoline(''' xError.stack(k).file ''',' num2str(xError.stack(k).line) ')">' ...
              'In ' xError.stack(k).name ' at ' num2str(xError.stack(k).line) '</a>']);
    end
end
return