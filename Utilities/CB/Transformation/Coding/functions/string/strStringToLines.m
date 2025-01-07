function cLines = strStringToLines(sTxt)
% STRSTRINGTOLINES splits each line from string into seperate string by
% searching for every newline character.
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
%   cLines = strStringToLines(sTxt)
%
% Inputs:
%   sTxt - string: text as strings, e.g. from file 
%
% Outputs:
%   cLines - cell of strings (mx1): list of each line in text as a single string  
%
% Example: 
%   cLines = strStringToLines(sTxt)
%
% see also: strLinesToString
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-19


%% split up lines

cLines = strsplit(sTxt,{char(13),char(10)},'CollapseDelimiters',true)';


return