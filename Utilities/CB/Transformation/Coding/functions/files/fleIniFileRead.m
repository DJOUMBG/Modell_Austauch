function cNameValues = fleIniFileRead(sIniFilepath,cIgnoreChars)
% FLEINIFILEREAD reads an ini file and returns a cell-matrix with the
% name-value pairs definied in ini-File. Optional there could definied a
% cell-array with character or strings, which are used for comment or
% structure of ini-file. Lines beginning with these characters or strings
% will be ignored.
%
%
% Syntax:
%   cNameValues = fleIniFileRead(sIniFilepath,cIgnoreChars)
%
% Inputs:
%   sIniFilepath - string: filepath of ini file 
%   cIgnoreChars - cell of strings (mxn) (optional): single characters or strings
%       which are used for start comments in ini-File
%
% Outputs:
%   cNameValues - cell of strings (mx2): name-value pairs defined as assignment in ini-File  
%       cNameValue(:,1): name  of ini-parameter
%       cNameValue(:,2): value of ini-parameter
%
% Example: 
%   cNameValues = fleIniFileRead(sIniFilepath,cIgnoreChars)
%
%
% See also: fleFileRead,, strStringToLines, fleIniFileGetValues
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-19


%% check input arguments

% default value for cIgnoreChars
if nargin < 2
    cIgnoreChars = {};
end


%% read ini file

% read content of ini file
sIniTxt = fleFileRead(sIniFilepath);

% create list of lines and clean lines
cIniLines = strStringToLines(sIniTxt);
cIniLines = strStringListClean(cIniLines);


%% get name-value pairs in ini file

% init output
cNameValues = {};

% analyse each line
for nLine=1:numel(cIniLines)
    
    % current line
    sLine = cIniLines{nLine};
    
    % first character in line
    sFirstChar = sLine(1);
    
    % skip line if commented
    if ismember(sFirstChar,cIgnoreChars)
       continue; 
    end
        
    % split line by equal sign
    cAssignSplit = strsplit(sLine,'=');
        
    % skip if not a valid assignment
    if length(cAssignSplit) < 2
        warning('Invalid assignment in line "%s" of file "%s".',...
            sLine,sIniFilepath);
        continue; 
    end

    % analyse lhs of assignment and get name
    sName = strtrim(cAssignSplit{1});
    
    % get rhs of assignment
    sRhs = strjoin(cAssignSplit(2:end),'');
    
    % split value and comment
    cValueComment = strsplit(sRhs,cIgnoreChars,'CollapseDelimiters',false);
    
    % get value
    sValue = strtrim(cValueComment{1});
    
    % assign name-value
    cNameValues = [cNameValues;{sName,sValue}];    %#ok<AGROW>
    
end

return