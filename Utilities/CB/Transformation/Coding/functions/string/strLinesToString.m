function sTxt = strLinesToString(cLines,bWinFormat)
% STRLINESTOSTRING merges each line of cell of string array into one text
% string by seperate text with newline characters.
%
% A line feed means moving one line forward. The code is \n.
% A carriage return means moving the cursor to the beginning of the line. The code is \r.
% Windows editors often still use the combination of both as \r\n in text files. 
% Unix uses mostly only the \n.
%
%   coding:
%       double(sprintf('\r')) = 13
%       double(sprintf('\n')) = 10
%       char(10) = '\n'
%       char(13) = '\r'
%   
% Syntax:
%   sTxt = strLinesToString(cLines,bWinFormat)
%   sTxt = strLinesToString(cLines)
%
% Inputs:
%       cLines - cell of strings (mx1): list of each line for text as a single string
%   bWinFormat - logical (1x1) [optional]: flag for using Unix-Format (false)
%                                          or Windows format (true), default: false
%
% Outputs:
%   sTxt - string: text as strings, e.g. for file 
%
% Example: 
%   sTxt = strLinesToString(cLines,bWinFormat)
%
% see also: strStringToLines
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-06-29

%% check input arguments

if nargin < 2
    bWinFormat = false;
end


%% append lines in text string

% init text string
sTxt = '';

% run through lines
for nLine=1:numel(cLines)
    
    if bWinFormat
        % windows newline format
        sTxt = sprintf('%s%s\r\n',sTxt,cLines{nLine});
    else
        % unix newline format
        sTxt = sprintf('%s%s\n',sTxt,cLines{nLine});
    end
    
end

return