function [nInfoId,sMsg] = saveVars2Script(...
    sFilepath__saveVars2Script,...
    xVarStruct__saveVars2Script,...
    nElemLim__saveVars2Script,...
    nStringLim__saveVars2Script)
% SAVEVARS2SCRIPT <one line description>
% <Optional file header info (to give more details about the function than in the H1 line)>
%   
%   In this function the most variable names are tagged with a suffix
%   "__saveVars2Script" to ensure that there are no overlaps in the 
%   function workspace with the variables from the given structure.
%   The suffixes were omitted in the syntax description for reasons of 
%   clarity.
%   
% Syntax:
%   saveVars2Script(sFilepath,xVarStruct,nElemLim,nStringLim)
%   saveVars2Script(sFilepath,xVarStruct,nElemLim)
%   saveVars2Script(sFilepath,xVarStruct)
%   nInfoId = saveVars2Script(__)
%   [nInfoId,sMsg] = saveVars2Script(__)
%
% Inputs:
%    sFilepath - string: 
%       filepath of resulting Matlab script (*.m) respectively resulting  
%       Matlab binary file (*.mat) if necessary.
%       Note: The resulting File will always have default Matlab
%       extensions. User defined extension in filepath is ignored.
%   xVarStruct - structure with fields: 
%       fields: names of variables to be saved
%       values of fields: values of variables to be saved
%     nElemLim - integer (1x1) [optional]: default 1000
%       maximum number of elements per numeric value that should be
%       written as text in .m file.
%       Otherwise these variables are saved in a additional .mat file  
%   nStringLim - integer (1x1) [optional]: default 76
%       maximum number of characters per string value that should be 
%       written as text in .m file.
%       Otherwise these variables are saved in a additional .mat file
%
% Outputs:
%   nInfoId - integer (1x1):
%       1 - successfully finished
%       0 - no files were written because of empty values
%      sMsg - string: 
%        
%
% Example: 
%   [nInfoId,sMsg] = saveVars2Script(sFilepath,xVarStruct,nElemLim,nStringLim)
%
%
% Subfunctions: deleteCommentLines
%
% See also: matlab.io.saveVariablesToScript
%
% Author: Elias Rohrer, TT/XCI, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-12-21

%% handling input arguments

% init execution option list
cOptions__saveVars2Script = {};

% recreate filepath of resulting m file
[sDir,sName] = fileparts(char(sFilepath__saveVars2Script));
sFilepath__saveVars2Script = fullfile(sDir,[sName,'.m']);

% check structure with variables
if ~isstruct(xVarStruct__saveVars2Script)
    error('Argument must be a structure with fields.');
end

% check 3th argument (optional)
if nargin > 2 && ~isempty(nElemLim__saveVars2Script)
    
    % append option maximum number of elments in arrays
    cOptions__saveVars2Script = [cOptions__saveVars2Script,...
        {'MaximumArraySize',nElemLim__saveVars2Script}];
    
end

% check 4th argument (optional)
if nargin > 3 && ~isempty(nStringLim__saveVars2Script)
    
    % append option maximum character number in strings
    cOptions__saveVars2Script = [cOptions__saveVars2Script,...
        {'MaximumTextWidth',nStringLim__saveVars2Script}];
    
end


%% check variables in function workspace and structure

% init variables in function workspace to see them with "who"
cEqualFunctionVars__saveVars2Script = {}; %#ok<NASGU>
nElem__saveVars2Script = []; %#ok<NASGU>
value__saveVars2Script = []; %#ok<NASGU>

% get variable names
cVarNames__saveVars2Script = fieldnames(xVarStruct__saveVars2Script);
if isempty(xVarStruct__saveVars2Script) || isempty(cVarNames__saveVars2Script)
    nInfoId = 0;
    sMsg = 'Empty structure with variables.';
    return;
end

% get existing variable names in function 
cThisFunctionVars = who;

% check if variables already exist as function varibales
nLoc = ismember(cThisFunctionVars,cVarNames__saveVars2Script);
cEqualFunctionVars__saveVars2Script = cThisFunctionVars(nLoc);

% error if function variables also exists in input structure
if ~isempty(cEqualFunctionVars__saveVars2Script)
    error('Invalid variable names:\n%s\n',...
        strjoin(cEqualFunctionVars__saveVars2Script,'\n'));
end


%% create variables in function workspace and save them to file

% assign all variables from input structure in this function workspace
for nElem__saveVars2Script=1:numel(cVarNames__saveVars2Script)
    
    % get value of variable
    value__saveVars2Script = xVarStruct__saveVars2Script.(...
        cVarNames__saveVars2Script{nElem__saveVars2Script});
    
    % assign variable with value in this function workspace
    feval(@()assignin('caller',cVarNames__saveVars2Script{nElem__saveVars2Script},...
        value__saveVars2Script));
    
end

% create Matlab script file with variable assignments
warning('off'); %#ok<WNOFF>
[cScriptVars,cBinVars] = matlab.io.saveVariablesToScript(...
    sFilepath__saveVars2Script,...
    cVarNames__saveVars2Script,...
    cOptions__saveVars2Script{:});
pause(0.1);
warning('on'); %#ok<WNON>

% delete comment lines in created Matlab script
deleteCommentLines(sFilepath__saveVars2Script);

% create message
sMsg = sprintf('TEXT written variables:\n%s\nBINARY written variables:\n%s\n',...
    strjoin(cScriptVars,'\n'),strjoin(cBinVars,'\n'));

% success variable
nInfoId = 1;

return

% =========================================================================

function deleteCommentLines(sFilepath)

% open file
nFileId = fopen(sFilepath,'r');
if nFileId < 0
    error('File "%s" can not be read.',sFilepath);
end

% read file content as char
sTxt = fread(nFileId,'*char')';

% close file
fclose(nFileId);

% convert string lines to cellstr
cLines = strsplit(sTxt,'\n')';

% init new line list
cNewLines = {};

% check for comment lines
for nLine=1:numel(cLines)
    
    % get trimmed line
    sLine = strtrim(cLines{nLine});
    
    % only store lines without leading comment
    if numel(sLine) > 0
        
        % append line if not is comment line
        if ~strcmp(sLine(1),'%')
            cNewLines = [cNewLines;cLines(nLine)]; %#ok<AGROW>
        end
        
    else
        cNewLines = [cNewLines;cLines(nLine)]; %#ok<AGROW>
    end
    
end

% open file again and write updated lines
nFileId = fopen(sFilepath,'w');
if nFileId < 0
    error('File "%s" can not be written.',sFilepath);
end
fwrite(nFileId,strjoin(cNewLines,'\n'));
fclose(nFileId);

return % deleteCommentLines
