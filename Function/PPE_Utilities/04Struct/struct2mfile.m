function sFile = struct2mfile(varargin)
% STRUCT2MFILE export a structure to a MATLAB m-file (script), which
% creates on execution the exported structure in the MATLAB base workspace.
% Structure elements of length 0 are not covered (e. g. empty structures
% created by STRUCT).
% 
%   STRUCT2MFILE(S,N) exports the structure S with the string N as name. 
% 
%   STRUCT2MFILE(CS,CN) exports the cell of structures CS with the cell of
%   strings CN as name. CS and CN must be cell vectors of the same length.
% 
%   STRUCT2MFILE(FILENAME) loads ans exports the file identified by the
%   string FILENAME.
% 
%   STRUCT2MFILE('ws') offers a list dialogue to choose the export variable
%   from the MATLAB base workspace.
% 
%   STRUCT2MFILE('file') exports the content of the mat-file selected by
%   the file explorer.

sFile = '';

if nargin == 1 && ischar(varargin{1})
    if strcmpi(varargin{1},'ws') % Workspace import
        % get variable list of base MATLAB workspace for import
        name = evalin('base', 'who');
        Selection = listdlg('Name','Morphix: import Workspace',...
            'ListString',name,...
            'PromptString','Select variables from Workspace to import',...
            'SelectionMode','multiple',...
            'ListSize',[200 250]);
        if isempty(Selection) || all(Selection == 0), return, end
        name = name(Selection);
        
        % convert data to cell
        var = cell(1,length(name));
        for k = 1:length(name)
            var{k} = evalin('base',name{k});
        end
        
    elseif strcmpi(varargin{1},'file') % file import selection
        % load data
        [LoadName,LoadPath] = uigetfile( ...
            {'*.mat','MAT-files (*.mat)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select Data File',...
            'MultiSelect','off');
        if isempty(LoadName) || isnumeric(LoadName), return, end
        LoadDat = load(fullfile(LoadPath,LoadName));
        
        % convert data to cell
        name = fieldnames(LoadDat);
        var = cell(1,length(name));
        for k = 1:length(name)
            var{k} = LoadDat.(name{k});
        end

    elseif exist(varargin{1},'file') == 2 % file import passed
        % load data
        LoadDat = load(varargin{1});
        
        % convert data to cell
        name = fieldnames(LoadDat);
        var = cell(1,length(name));
        for k = 1:length(name)
            var{k} = LoadDat.(name{k});
        end
        
    else
        error('struct2mfile:WrongInput','The string argument to function struct2mfile is no valid file or option.');
    end
    
elseif nargin == 2 && (isstruct(varargin{1}) && ischar(varargin{2})) % function argument single
    if isvarname(varargin{2})
        var = varargin(1);
        name = varargin(2);
    else
        error('struct2mfile:WrongInput','The string argument to function struct2mfile is no valid MATLAB variable name.');
    end
elseif nargin == 2 && (iscell(varargin{1}) && iscell(varargin{2})) % function argument list
    if all(cellfun(@isvarname,varargin{2}))
        var = varargin{1};
        name = varargin{2};
    else
        error('struct2mfile:WrongInput','The cell string argument to function struct2mfile contains an invalid MATLAB variable name.');
    end
end

% generate ASCII script lines for each variable list element
cstr = {};
for k = 1:length(name)
    ecstr = createVariable(var{k},name{k});
    cstr = [cstr;ecstr]; %#ok
end

% export to m-file
if isempty(sFile)
    [SaveName,PathName] = uiputfile('*.m','Select save file name');
else
    [SaveName,PathName] = uiputfile('*.m','Select save file name',[sFile '.m']);
end
if isempty(SaveName) || isnumeric(SaveName), return, end

% write file
sFile = fullfile(PathName,SaveName);
fid = fopen(sFile,'w');
for k = 1:size(cstr,1)
    cstr{k} = fprintfStringCorrection(cstr{k}); %#ok 
    fprintf(fid,'%s\r\n',cstr{k});
end
fclose(fid);
return

% =========================================================================

function [outstring]=fprintfStringCorrection(instring)
% fprintfStringCorrection - modifies strings to be printed correctly with
% fprintf function
% e. g. percent '%' >> '%%' 
outstring = regexprep(instring, ...
                            {'%'},...
                            {'%%'});
return 

% =========================================================================

function cstr = createVariable(var,name)
% createVariable - creates the cellstring for script to create the passed
% variable.
% 
% Input variables:
% var   - structure
% name  - string with the name of the structure (has to be a valid MATLAB
%         variable name
% 
% Output variables:
% cstr  - cell string with the content to create the variable via script

% check input
if ~isstruct(var)
    warning('struct2mfile:WrongInput','The argument to function struct2mfile must be a structure');
%     return
end

% analyse structure parts
element = parsefullstruct(var);
element(1).name = name;

% create string cell with all lines of m-file
cstr = cell(length(element),1);
stack = element(1);
LineAct = 1;
for k = 1:length(element) % process all structure elements
    stack = stack(1:element(k).level-1);
    stack(end+1) = element(k); %#ok
    
    % evaluate current stack into a structure assignment statement
    if isempty(stack(end).content)
        ecstr = createEntry(stack,var);
        cstr(LineAct:LineAct+size(ecstr,1)-1,1) = ecstr;
        LineAct = LineAct + size(ecstr,1);
    end
end
cstr = cstr(1:LineAct-1);
return

% =========================================================================

function cstr = createEntry(stack,varstruct)
% createEntry - create m-file assignment string to reconstruct variable
% structure part.
% 
% Input variables:
% stack       - structure with all stack elements of variable part:
%   .type     - string, type of subelement (struct,cell,numeric,logical,char,field)
%   .size     - vector with size information
%   .level    - value with subsequent level of element
%   .name     - string with name of element (only filled for structure
%               fields)
%   .content  - vector with position of element entries directly below
%               element (only with structures and cell arrays)
%   .position - cell (1x2) with min and max value (matrices) or first and
%               last entry (cell array of characters only)
% varstruct   - structure to be exported
% 
% Output variables:
% cstr     - cell string with variable/structure assignment

% create assignment string (left handside and call string)
LhsString = expandLHS(stack);
LhsString = regexprep(LhsString,'-99',':'); % replace indicator for full dimension call

% create value strings (right hand side, RHS)
value = eval(['varstruct' LhsString(length(stack(1).name)+1:end)]);
ValSize = size(value);
nDflag = false;
if isempty(value) % structure field has no content
    if ischar(value)
        RhsCell = {''''' ;'};
    else
        RhsCell = {'[] ;'};
    end
else % create structure content assignment
    if ischar(value) % string
        if size(value,1) > 1 % character array / string matrix
            RhsCell = cell(ValSize(1),1);
            for k = 1:ValSize(1)
                RhsCell{k} = ['  ''' value(k,:) ''' ;'];
            end
            RhsCell{1,1}(1) = '[';
            RhsCell{end,1} = [RhsCell{end,1:end-1} ' ] ;'];
        else % simple string
            RhsCell = {['''' value ''' ;']};
        end
        
    elseif isnumeric(value) && max(ValSize)==1 % value
        RhsCell = {[num2str(value) ' ;']};
        
    elseif isnumeric(value) && length(ValSize)==2 && min(ValSize)==1 % vector
        if ValSize(1) == 1 % row vector
            RhsCell = {['[ ' num2str(value) ' ] ;']};
        else % column vector
            RhsCell = {['[ ' num2str(value') ' ]'' ;']};
        end
        
    elseif isnumeric(value) && length(ValSize)==2 && min(ValSize)>1 % matrix 2D
        RhsCell = cell(ValSize(1),1);
        for k = 1:ValSize(1)
            RhsCell{k} = ['  ' num2str(value(k,:)) ' ;'];
        end
        RhsCell{1,1}(1) = '[';
        RhsCell{end,1} = [RhsCell{end,1}(1:end-1) ' ] ;'];
        
    elseif isnumeric(value) && length(ValSize)>2 % matrix nD -> needs LHS correction!
        cstr = cell(0,0);
        
        % loop over dimensions >2D
        DimMat = ones(1,length(stack(end).size(3:end)));
        while ~isempty(DimMat) 
            % create dummy stack
            nstack = [stack stack(end)];
            nstack(end).type = 'struct';
            nstack(end).position = [-99 -99 DimMat]; % add identifiers for first 2D dimensions
            
            % create 2D entry
            ncstr = createEntry(nstack,varstruct);
            cstr = [cstr;ncstr]; %#ok
            
            DimMat = nextDimElem(DimMat,stack(end).size(3:end));
        end
        
        nDflag = true;
        
    else
        RhsCell = {'[] ;'};
        warning('struct2mfile:invalidVariableType',['a variable type, which is not covered by the export function is encountered with ' LhsString]);
    end
end

% combine LHS and RHS
if ~nDflag
    if size(RhsCell,1) > 1 || length(RhsCell{1})+length(LhsString) > 75
        cstr{1} = [LhsString ' = ...'];
        cstr = [cstr; RhsCell];
    else
        cstr{1} = [LhsString ' = ' RhsCell{1}];
    end
end
return

% =========================================================================

function str = expandLHS(stack)
% expandLHS - create variable assignment string from full stack.
% 
% Input variables:
% stack     - structure with all stack elements:
%   .type     - string, type of subelement (struct,cell,numeric,logical,char,field)
%   .size     - vector with size information
%   .level    - value with subsequent level of element
%   .name     - string with name of element (only filled for structure
%               fields)
%   .content  - vector with position of element entries directly below
%               element (only with structures and cell arrays)
%   .position - cell (1x2) with min and max value (matrices) or first and
%               last entry (cell array of characters only)
% 
% Output variables:
% str     - string with variable/structure assignment

cstr = cell(1,length(stack));
for k = 1:length(stack)
    cstr{k} = stackStr(stack(k:end));
end
str = horzcat(cstr{:});

% remove point of base structure
if str(1) == '.'
    str = str(2:end);
end
return

% =========================================================================

function str = stackStr(stack)
% stackStr - create appropriate variable call/assignment string from one
% stack element.
% 
% Input variables:
% stack     - structure (current element and all subsequent):
%   .type     - string, type of subelement (struct,cell,numeric,logical,char,field)
%   .size     - vector with size information
%   .level    - value with subsequent level of element
%   .name     - string with name of element (only filled for structure
%               fields)
%   .content  - vector with position of element entries directly below
%               element (only with structures and cell arrays)
%   .position - cell (1x2) with min and max value (matrices) or first and
%               last entry (cell array of characters only)
% 
% Output variables:
% str     - string with one part of a variable/structure assignment
% 

switch stack(1).type
    case 'struct' % struct matrix position (name/field handled in otherwise)
        str = ['(' vec2strCommaSeparated(stack(1).position) ')'];
    case 'cell' % cell position + name if applicable
        if ~isempty(stack(1).name)
            str = ['.' stack(1).name '{' vec2strCommaSeparated(stack(min(2,length(stack))).position) '}'];
        else
            str = ['{' vec2strCommaSeparated(stack(min(2,length(stack))).position) '}'];            
        end
    otherwise
        if ~isempty(stack(1).name)
            str = ['.' stack(1).name];
        else
            str = '';            
        end
end
return

% =========================================================================

function str = vec2strCommaSeparated(vec)
% vec2strCommaSeparated - create comma separated string with elements of a
% vector.
% 
% Input variables:
% vec - vector 
% 
% Output variables:
% str - string

% ensure horizontal orientation
if size(vec,1) > size(vec,2)
    vec = vec';
end

str = num2str(vec);
str = regexprep(str,' +',',');
return

% =========================================================================

function element = parsefullstruct(value,level,position)
% parsefullstruct - creates list of structure subelements including type and
% size information. Empty elements are omitted.
% 
% Input variables:
% value       - structure with fields and cells with further structures
% [level]     - level of currently passed value, optional intended as 1 if
%               omitted
% [position]  - vector with position of actual element
% 
% Output variables:
% element     - structure with all subelements:
%   .type     - string, type of subelement (structure,cellarray,matrice,string)
%   .size     - vector with size information
%   .level    - value with subsequent level of element
%   .name     - string with name of element (only filled for structure
%               fields)
%   .content  - vector with position of element entries directly below
%               element (only with structures and cell arrays)
%   .position - cell (1x2) with min and max value (matrices) or first and
%               last entry (cell array of characters only)
% 
% Example calls:
% element = parsefullstruct(structure)
% element = parsefullstruct(guidata(gcf))

% catch first level call
if nargin < 2, level = 1; end
if nargin < 3, position = [1 1]; end

% fill own element information and do initialization
types = {'struct','cell','numeric','logical','char','function_handle'};
for k = 1:length(types)
    if isa(value,types{k})
        element.type = types{k};
    end
end
element.size = size(value);
element.level = level;
element.name = '';
element.content = [];
element.position = position;

valuesize = size(value); % size of value
if strcmpi(element(1).type,types{1}) % struct
    element.type = 'field'; % base element of struct is the var name
    
    % add intermediate level of structure matrix position
    DimMat = ones(1,length(valuesize));
    while ~isempty(DimMat) % loop over all struct matrix elements
        DimCell = num2cell(DimMat);
        
        matelement.type = 'struct';
        matelement.size = [1 1];
        matelement.level = level+1;
        matelement.name = '';
        matelement.content = [];
        matelement.position = [DimCell{:}];
        
        % add all fields of structure
        structfields = fieldnames(value(DimCell{:}));
        for k = 1:length(structfields) % for all fields of struct
            if isempty(value(DimCell{:})) % catch structures of size 0
                subelement.type = 'struct';
                subelement.size = [0 0];
                subelement.level = level+2;
                subelement.name = structfields{k};
                subelement.content = [];
                subelement.position = [];
            else
                subelement = parsefullstruct(value(DimCell{:}).(structfields{k}),level+2);
                
                % name of structure fields
                subelement(1).name = structfields{k};
            end
            
            % position of elements
            for l = 1:length(subelement)
                if ~isempty(subelement(l).content)
                    subelement(l).content = subelement(l).content + length(element); %#ok
                end
            end
            
            % add subelement in content list of current element
            matelement(1).content = [matelement(1).content length(matelement)+1];
            
            % store subelements
            matelement(end+1:end+length(subelement)) = subelement(:);
            
            clear subelement
        end % for struct length
        
        % postprocessing of subelements
        % position of elements
        for l = 1:length(matelement)
            if ~isempty(matelement(l).content)
                matelement(l).content = matelement(l).content + length(element); %#ok
            end
        end
        
        % add element in content list
        element(1).content = [element(1).content length(element)+1];
        
        % store subelements
        element(end+1:end+length(matelement)) = matelement(:);
        
        clear matelement
        
        % next element
        DimMat = nextDimElem(DimMat,valuesize);
    end % while over all struct matrix elements 
    
elseif strcmpi(element(1).type,types{2}) % cell
    if ~isempty(value)
        DimMat = ones(1,length(valuesize));
        while ~isempty(DimMat)
            DimCell = num2cell(DimMat);
            subelement = parsefullstruct(value{DimCell{:}},level+1);
            subelement(1).position = [DimCell{:}];
            
            % postprocessing of subelements
            % position of elements
            for l = 1:length(subelement)
                if ~isempty(subelement(l).content)
                    subelement(l).content = subelement(l).content + length(element);
                end
            end
            
            % add element in content list
            element(1).content = [element(1).content length(element)+1];
            
            % store subelements
            element(end+1:end+length(subelement)) = subelement(:);
            
            % next element
            DimMat = nextDimElem(DimMat,valuesize);
        end
    end
elseif strcmpi(element(1).type,types{3}) || strcmpi(element(1).type,types{4}) % numeric or boolean
elseif strcmpi(element(1).type,types{5}) % char
end
return