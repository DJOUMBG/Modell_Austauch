function sJson = struct2json(xStruct)
% STRUCT2JSON create a JSON payload from a Matlab struct.
%
% Syntax:
%   sJson = struct2json(xStruct)
%
% Inputs:
%   xStruct - structure with fields: 
%
% Outputs:
%   sJson - string with JSON payload of name/value pairs
%
% Example: 
%   sJson = struct2json(struct('text',{'a'},'double',{12.3},'int',{5}));
%   sJson = struct2json(struct('text',{'a'},'double',{12.3},'int',{5},'logical',{true},'cell',{{'a','b'}}))
%   sJson = struct2json(struct('text',{'a'},'structLvl2',struct('text',{'alvl2'})))
%
% Subfunctions: convertValue, convertValueScalar
%
% See also: RequestMessage, jsonencode (from R2016b)
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-12-02

cName = fieldnames(xStruct);
cValue = cellfun(@(x)convertValue(xStruct.(x)),cName,'UniformOutput',false);
cNameValue = cellfun(@(x,y)sprintf('"%s":%s',x,y),cName,cValue,'UniformOutput',false);
sJson = ['{' strGlue(cNameValue,',') '}']; 
return

% ==================================================================================================

function sValue = convertValue(value)
% CONVERTVALUE convert a Matlab variable value into a JSON string. This wrapper handles vector
% values of numeric, structure and cell arrays, while char vectors are converted as strings.
%
% Syntax:
%   sValue = convertValue(value)
%
% Inputs:
%   value - any matlab variable
%
% Outputs:
%   sValue - string of JSON representation of Matlab variable value
%
% Example: 
%   sValue = convertValue(value)

if numel(value) > 1
    switch class(value)
        case 'char'
            sValue = convertValueScalar(value);
        case 'cell'
            cValue = cellfun(@(x)convertValueScalar(x),value,'UniformOutput',false);
            sValue = sprintf('[%s]',strGlue(cValue,','));
        otherwise
            cValue = arrayfun(@(x)convertValueScalar(x),value,'UniformOutput',false);
            sValue = sprintf('[%s]',strGlue(cValue,','));
    end
else % scalar 
    sValue = convertValueScalar(value);
end
return

% ==================================================================================================

function sValue = convertValueScalar(value)
% CONVERTVALUESCALAR convert a scalar Matlab variable value to the representing JSON string.
%
% Syntax:
%   sValue = convertValueScalar(value)
%
% Inputs:
%   value - any scalar matlab variable
%
% Outputs:
%   sValue - string of JSON representation of Matlab variable value
%
% Example: 
%   sValue = convertValueScalar(1)
%   sValue = convertValueScalar(1.2)
%   sValue = convertValueScalar("someText")
%   sValue = convertValueScalar({'cellContentA'})
%   sValue = convertValueScalar(struct('fieldA',{'someText'},'fieldB',{1234}))

switch class(value)
    
    case 'char'
        sValue = sprintf('"%s"',escapeJson(value));
        
    case 'double'
        sValue = num2str(value);
        
    case 'logical'
        if value
            sValue = 'true';
        else
            sValue = 'false';
        end
        
    case 'cell'
        sValue = convertValue(value);

    case 'struct'
        sValue = struct2json(value);
        
    otherwise
        error('Value conversion failed with not covered variable type: %s',class(value));
end
return

% ==================================================================================================

function sChar = escapeJson(sChar)
% ESCAPEJSON escapes for characters in JSON
%
% Syntax:
%   sChar = escapeJson(sChar)
%
% Inputs:
%   sChar - string | char array 
%
% Outputs:
%   sChar - string with escaped characters for JSON
%
% Example: 
%   sChar = escapeJson('some\special/strings"andmore')

% JSON escape characters except backspace \b and format \f
cEscape = {'\','\\'};
%            '/','\/'
%            '"','\"'
%            char(10),'\n'
%            char(13),'\r'
%            char(9),'\t'}; %#ok<CHARTEN>

for nIdxEscape = 1:size(cEscape,1)
    sChar = strrep(sChar,cEscape{nIdxEscape,1},cEscape{nIdxEscape,2});
end
return


