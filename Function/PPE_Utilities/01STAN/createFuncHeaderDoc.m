function sDoc = createFuncHeaderDoc(varargin) 
% CREATEFUNCHEADERDOC creates a header for the interface of a function,
% which first line (function ...) is in the clipboard or passed as input
% argument.
%
% The interface of a function describes all input and output parameters e.
% g. 'function [<o1>,<o2>] = <name>(<i1>,<i2>,...)' as well as information
% of internal subfunction and external function calls, used files,
% associated files (See also) and examples of useage.
%
% Syntax:
%   sDoc = createFuncHeaderDoc(varargin)
%
% Inputs:
%   varargin - [unsused] cell (1x2) with
%       {1,1} javahandle_withcallbacks.com.mathworks.mde.editor.EditorSyntaxTextPane
%       {1,2} java.awt.event.KeyEvent
%
% Outputs:
%   sDoc - string with function definition line including header documentation
%
% Example: 
%   sDoc = createFuncHeaderDoc(varargin)
%
%
% Subfunctions: addCredentials, addDependency, addLine, addSyntax,
% addVariable, createCommaList, createHeaderString, determineVarType,
% findFunctionInternal 
% Private functions: 
% Other m-files required: 
% MAT-files required:
%
% See also: EditorMacro (Matlab File Exchange)
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2010-05-16

% initialize 
sClipboard = '';
bClipboard = false;

% get selected string from editor
xVersion = ver('MATLAB');
sVersionMatlab = regexprep(xVersion.Version,'(?<=\d+\.\d+)\.',''); % remove second point of patch releases
vVersionMatlab = str2double(sVersionMatlab);
if vVersionMatlab > 7.10 && vVersionMatlab < 7.12
    jEditorApp = com.mathworks.mde.editor.MatlabEditorApplication.getInstance;
    activeEditor = jEditorApp.getActiveEditor;
    sClipboard = char(activeEditor.getSelection);
elseif vVersionMatlab >= 7.12 % solution 2011a
    activeEditor = matlab.desktop.editor.getActive; % get active editor file
    sClipboard = char(activeEditor.SelectedText);
end

if isempty(sClipboard)
    fprintf(1,'createFunctionHeaderDoc: Editor determination failed, checking clipboard.\n');
    % get function definition from clipboard
    sClipboard = clipboard('paste');
    bClipboard = true;
    if isempty(sClipboard)
        fprintf(1,'createFunctionHeaderDoc: Clipboard was empty - exit.\n');
    else
        fprintf(1,'createFunctionHeaderDoc: Clipboard contained:\n%s\n',sClipboard);
    end
end

% create string
[sDoc] = createHeaderString(sClipboard);

% write string to editor
% try
%     disp('try write')
%     activeEditor.replaceSelection(sDoc);
%     disp('write done')
% catch ME
%     disp('createFuncHeaderDoc:Fail')
%     rethrow(ME)
% end

% backup via clipboard
if bClipboard || nargin < 1
    clipboard('copy', sDoc)
end
return

% =========================================================================

function [sDoc] = createHeaderString(sClipboard)
% CREATEHEADERSTRING create the header string based on passed function
% definition.
%
% Syntax:
%   sDoc = createHeaderString(sClipboard)
%
% Inputs:
%   sClipboard - string with clipboard content (function header line)
%
% Outputs:
%   sDoc - string array containing the function header template
%
% Example: 
%   sDoc = createHeaderString(sClipboard)

%% get function string elements
% get function name (replace all parts of line, to leave only function name)
sName = regexprep(sClipboard,{char(10),char(13),'function\s+', '.+=\s*', '\(.*\)\s*', '%.*'},''); %#ok<CHARTEN>
% get function output variables
if isempty(strfind(sClipboard,'=')) %#ok<STREMP> - contains function only since R2016b
    sOutputs = ''; % no outputs in function
else
    sOutputs = regexprep(sClipboard,{'function\s+','\s*=.*','\[','\]'},''); % string with outputs
end
if isempty(sOutputs)
    cOutput = {};
else
    cOutput = textscan(sOutputs,'%s','Delimiter',','); % divide string into single outputs
    cOutput = cOutput{1}; % remove double cell
end
% get function input variables
sInputs = regexp(sClipboard,'(?<=\().*(?=\))','match','once'); % string with inputs listed
if isempty(sInputs)
    cInput = {};
else
    cInput = textscan(sInputs,'%s','Delimiter',','); % divide string into single inputs
    cInput = cInput{1}; % remove double cell
end


%% Create String
sDoc  = '';
sDoc = addLine(sDoc, regexprep(sClipboard,{char(10),char(13)},'')); %#ok<CHARTEN>
sDoc = addLine(sDoc, ['% ' upper(sName) ' <one line description>']);
sDoc = addLine(sDoc, '% <Optional file header info (to give more details about the function than in the H1 line)>');
sDoc = addLine(sDoc, '%');
sDoc = addLine(sDoc, '% Syntax:');
sDoc = addLine(sDoc, addSyntax(sName,cInput,cOutput));
sDoc = addLine(sDoc, '%');
sDoc = addLine(sDoc, '% Inputs:');
sDoc = addLine(sDoc, addVariable(cInput));
sDoc = addLine(sDoc, '% Outputs:');
sDoc = addLine(sDoc, addVariable(cOutput));
sDoc = addLine(sDoc, '% Example: ');
sDoc = addLine(sDoc, addSyntax(sName,cInput,cOutput));
if exist([sName '.m'],'file') == 2 % add only for m-file main functions
    sDoc = addLine(sDoc, '%');
    sDoc = addLine(sDoc, '%');
    sDoc = addLine(sDoc, findFunctionInternal(sName));
    sDoc = addLine(sDoc, addDependency(sName, 1));
    sDoc = addLine(sDoc, '% Other m-files required:');
    sDoc = addLine(sDoc, '% MAT-files required:');
    sDoc = addLine(sDoc, '%');
    sDoc = addLine(sDoc, addDependency(sName));
    sDoc = addLine(sDoc, '%');
    sDoc = addLine(sDoc, addCredentials); % add author information and date
end
return

% =========================================================================

function [sDoc] = addCredentials
% ADDCREDENTIALS generates a string array with author and credential
% information.
%
% Syntax:
%   sDoc = addCredentials
%
% Inputs:
%
% Outputs:
%   sDoc - string array containing description lines for author... 
%
% Example: 
%   sDoc = addCredentials

% initialize output
sDoc = '';

% predefine detailed author information
cAuthor = { % <userID> <userFullName> <userDepart.> <userPhone> <userEmail>
    'rafrey5','Rainer Frey','TT/XCI-6','+49-711-8485-3325','rainer.r.frey@daimlertruck.com';
    'frmoelle','Frank Möller','TT/XCI-6','+49-160-8620723','frank.moeller@daimlertruck.com';
    'gerhajo','Johannes Gerhard','TT/XCD-5','+49-711-17-33397','johannes.gerhard@daimlertruck.com';
    'hillenb','Christoph Hillenbrand','TT/XCD-5','+49-711-17-55077','christoph.hillenbrand@daimlertruck.com';
    'ploch37','Peter Loch','TT/XCD-3','+49-711-17-26756','peter.p.loch@daimlertruck.com';
    'rohrere','Elias Rohrer','TE/PTC-H','+49-160-8695728','elias.rohrer@daimlertruck.com';
    };

% get actual user
sUserName = lower(getenvOwn('USERNAME'));
[bAuthor,nAuthor] = ismember(sUserName,cAuthor(:,1));

if bAuthor % add details
    sDoc = addLine(sDoc, ['% Author: ' cAuthor{nAuthor,2} ', ' cAuthor{nAuthor,3} ', Daimler Truck AG']);
    sDoc = addLine(sDoc, ['%  Phone: ' cAuthor{nAuthor,4}]);
    sDoc = addLine(sDoc, ['% MailTo: ' cAuthor{nAuthor,5}]);
else % add userID only
    sDoc = addLine(sDoc, ['% Author: ' sUserName]);
end
sDoc = addLine(sDoc, ['%   Date: ' datestr(now, 'yyyy-mm-dd')]); % add date
return

% =========================================================================

function [sDoc] = addVariable(cVar)
% ADDVARIABLE adds definition lines of a variable list.
% For each item of string cell a line is added with space padding and dash
% as separator. If the variable name follows the rules described below, the
% variable type is added as initial comment.
%
% Syntax:
%   sDoc = addVariable(cVar)
%
% Inputs:
%   cVar - cell (1xn) with strings containing single variable names 
%
% Outputs:
%   sDoc - string array containing description lines for variables
%
% Example: 
%   sDoc = addVariable({'bBoolVar','sStringVar','cCellVar'})

% initialize output
sDoc = '';

% predefine variable type descriptions
cTypeDef = {...
    'b','boolean (1x1) ';
    'v','vector (1x1) ';
    'm','matrix (mxn) ';
    'n','integer (1x1) ';
    's','string ';
    'c','cell (mxn) ';
    'x','structure with fields: ';
    'h','handle (1x1) ';
    'o','object (1x1) ';
    };

% create variable definition strings
nLength = cellfun(@length,cVar);
nMaxLength = max(nLength);
for k = 1:length(cVar)
    sBlanks = char(32 * ones(1, nMaxLength - nLength(k)));
    strLine = ['%   ' sBlanks, cVar{k}, ' - ' determineVarType(cVar{k},cTypeDef)];
    sDoc = sprintf('%s%s\n', sDoc, strLine);
end
sDoc = sprintf('%s%s', sDoc, '%'); % add follow up comment
return

% =========================================================================

function sType = determineVarType(sVar,cTypeDef)
% DETERMINEVARTYPE determine variable type according specified variable
% name and type definition slist
%
% Syntax:
%   sType = determineVarType(sVar,cTypeDef)
%
% Inputs:
%       sVar - string 
%   cTypeDef - cell (mxn) 
%
% Outputs:
%   sType - string 
%
% Example: 
%   sType = determineVarType('sVarName',cTypeDef)

if length(sVar) > 1 &&...
        (sVar(2) - 'A') >= 0 && ... % if second character is upper character
        (sVar(2) - 'Z') <= 0
    
    % check first character for being a variable type identifier
    [bType,nType] = ismember(sVar(1),cTypeDef(:,1));
    
    if bType % if identfier, get description string
        sType = cTypeDef{nType,2};
    else
        sType = '';
    end
else
    sType = '';
end
return

% =========================================================================

function [sFunctionString] = addDependency(sFunctionName, bPrivate)
% ADDDEPENDENCY creates information string lines with sub-function calls.
% The m-file in question must be saved on the MATLAB path and the filename
% must match the main function name.
%
% Syntax:
%   sFunctionString = addDependency(sFunctionName,bPrivate)
%
% Inputs:
%   sFunctionName - string with function name
%        bPrivate - boolean for call with feedback string of 
%                       false: associated function in external files
%                       true:  subfunctions in same function file
%
% Outputs:
%   sFunctionString - string 
%
% Example: 
%   sFunctionString = addDependency('createFuncHeaderDoc',true)

% care for reduced call
if nargin < 2
    bPrivate = false;
end

% create dependency function list
if exist(sFunctionName,'file') == 2
    if verLessThanMATLAB('8.3')
        cFunction = depfun(sFunctionName,'-toponly','-quiet'); % only direct dependencies
    else
        cFunction = matlab.codetools.requiredFilesAndProducts(sFunctionName,'toponly');
    end
    
    if isempty(cFunction)
        cFunction = '';
    else
        cFunction(1) = []; % first function is own
        sMatlabRoot = matlabroot;
        idx = ~strncmp(sMatlabRoot,cFunction, length(sMatlabRoot)); % reduce to non-MATLAB functions
        cFunction = cFunction(idx);
        bListPriv = false(size(cFunction));
        for k = 1:length(cFunction) % for all functions
            [sPathstr, sName] = fileparts(cFunction{k});
            cFunction{k} = sName; % reduce to function
            if strncmp('etavirp', fliplr(sPathstr), 7) % if function is private
                bListPriv(k) = 1;
            end
        end
    end
else
    cFunction = '';
end

% create output string
[cFunction, idx] = sort(cFunction); % resort functions
if bPrivate % header according call
    sFunctionString = '% Private functions:';
else
    sFunctionString = '% See also:';
end
if isempty(cFunction) % backup string
     if ~bPrivate
        sFunctionString = [sFunctionString ' <OTHER_FUNCTION_NAME1>, <OTHER_FUNCTION_NAME2> '];
     end
else % string with associated functions
    bListPriv = bListPriv(idx);
    if bPrivate
        sFunctionString = [sFunctionString sprintf(' %s,', cFunction{bListPriv})];
    else
        sFunctionString = [sFunctionString sprintf(' %s,', cFunction{~bListPriv})]; 
    end
    sFunctionString(end) = []; % remove last comma
end
return

% =========================================================================

function [sAllLines] = addLine(sAllLines, sLine)
% ADDLINE add a string or string array to existing string
%
% Syntax:
%   sAllLines = addLine(sAllLines,sLine)
%
% Inputs:
%   sAllLines - string with previous lines
%       sLine - string with additonal lines
%
% Outputs:
%   sAllLines - string including all content
%
% Example: 
%   sAllLines = addLine('bla','blob')
sAllLines = [sAllLines sLine char(13)];
return

% =========================================================================

function [sSubFuncStr] = findFunctionInternal(sFunctionName)
% FINDFUNCTIONINTERNAL return all internal m-file functions in a
% subfunction string.
%
% Syntax:
%   sSubFuncStr = findFunctionInternal(sFunctionName)
%
% Inputs:
%   sFunctionName - string with function name
%
% Outputs:
%   sSubFuncStr - string with listed subfunctions
%
% Example: 
%   sSubFuncStr = findFunctionInternal('createFuncHeaderDoc')

% initialize output
sSubFuncStr = '% Subfunctions:';

% ensure file extension
if ~strcmp('.m', sFunctionName(end-1:end))
    sFunctionName = [sFunctionName '.m'];
end

% read file
cSubFunctions = {}; % initialize list
if exist(sFunctionName,'file') == 2 
    fid = fopen(sFunctionName,'r');
    cLines = textscan(fid, '%[^\n]', 'CommentStyle', '%');
    fclose(fid);
    cLines = cLines{1};
else
    return
end

% reduce to function definition lines
cLines = cLines(strncmp('function', cLines, 8));
if ~isempty(cLines) && length(cLines) > 1
    cLines = cLines(2:end); % first name is function itself
    cSubFunctions{length(cLines),1} = ''; % initialize cSubFunctions 
    for k = 1:length(cLines)
        % replace all parts of line, to leave only function name
        cSubFunctions{k} =  regexprep(cLines{k},{'function\s+','.+=\s*','\(.*\)\s*'},''); 
    end
end

% create string
if ~isempty(cSubFunctions)
    cSubFunctions = sort(cSubFunctions);
    sSubFuncStr = ['% Subfunctions:' sprintf(' %s,', cSubFunctions{:})];
    sSubFuncStr(end) = []; % remove last comma
end
return

% =========================================================================

function [sSyntax] = addSyntax(sName,cInput,cOutput)
% ADDSYNTAX create syntax string of function
%
% Syntax:
%   sSyntax = addSyntax(sName,cInput,cOutput)
%
% Inputs:
%     sName - string with function name
%    cInput - cell (1xm) with strings of input arguments
%   cOutput - cell (1xn) with strings of output arguments
%
% Outputs:
%   sSyntax - string with syntax description of function
%
% Example: 
%   sSyntax = addSyntax('addSyntax',{'sName','cInput','cOutput'},{'cOutput'})


% create output string
switch length(cOutput)
    case 0
        sOut = '';
    case 1
        sOut = [cOutput{1} ' = '];
    otherwise
        sOut = ['[' createCommaList(cOutput) '] = '];
end

% create input string
switch length(cInput)
    case 0
        sIn = '';
    case 1
        sIn = ['(' cInput{1} ')'];
    otherwise
        sIn = ['(' createCommaList(cInput) ')'];
end

% build line
sSyntax = ['%   ' sOut sName sIn];
return

% =========================================================================

function sList = createCommaList(cItem)
% CREATECOMMALIST creates string with comma separated items.
%
% Syntax:
%   sList = createCommaList(cItem)
%
% Inputs:
%   cItem - cell (1xn) with strings
%
% Outputs:
%   sList - string with comma separated content
%
% Example: 
%   sList = createCommaList({'bla','blob'})

sList = sprintf('%s,', cItem{:});
sList = sList(1:end-1); % remove last comma
return
