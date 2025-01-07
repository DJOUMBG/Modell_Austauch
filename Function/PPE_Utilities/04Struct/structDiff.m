function [xBaseDiff,xNewDiff,xBaseXor,xNewXor] = structDiff(xBase,xNew,nOutput) 
% STRUCTDIFF gives the difference between two structures of maximum
% depth level 1.
%
% Syntax:
%   [xBaseDiff,xNewDiff,xBaseXor,xNewXor] = structDiff(xBase,xNew)
%   [xBaseDiff,xNewDiff,xBaseXor,xNewXor] = structDiff(xBase,xNew,nOutput)
%
% Inputs:
%   xBase - structure with one level of fields
%    xNew - structure with one level of fields, to be compared to values of
%           base fields
% nOutput - integer, if output shall be displayed on command window
%
% Outputs:
%   xBaseDiff - structure with fields of xBase different with xNew 
%    xNewDiff - structure with fields of xNew different with xBase
%    xBaseXor - structure with fields of xBase not in xNew
%     xNewXor - structure with fields of xNew not in xBase
%
% Example: 
%   structDiff(struct('a',{11},'b',{11},'c',{11}),struct('b',{22},'c',{0},'d',{33}))
%   [xBaseDiff,xNewDiff,xBaseXor,xNewXor] = structDiff(struct('a',{11},'b',{11},'c',{11}),struct('b',{22},'c',{0},'d',{33}))
%
% See also: fieldnames, structAdd, structUpdate, structDiff, structExtract,
% structFind, structDisp
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-11-16

% check input 
if nargin < 3
    if nargout == 0
        nOutput = 1;
    else
        nOutput = 0;
    end
end

% initialize
xBaseDiff = struct;
xNewDiff = struct;
xBaseXor = struct;
xNewXor = struct;

% get fieldnames
cBase = fieldnames(xBase);
cNew = fieldnames(xNew);

% check occurence
bBaseInNew = ismember(cBase,cNew);
bNewInBase = ismember(cNew,cBase);
cBoth = cBase(bBaseInNew);
cBaseXor = cBase(~bBaseInNew);
cNewXor = cNew(~bNewInBase);

% process different content of same fields
for nIdxField = 1:numel(cBoth)
    if ~isempty(xNew.(cBoth{nIdxField})) && ... % not empty
            ~isstruct(xNew.(cBoth{nIdxField})) && ... % no structure
            ~ischar(xNew.(cBoth{nIdxField})) && ... % no string
            ~iscell(xNew.(cBoth{nIdxField})) && ... % no cell
            (any(size(xNew.(cBoth{nIdxField}))~=size(xBase.(cBoth{nIdxField}))) || ... % not same size
             ~all(all(xNew.(cBoth{nIdxField})==xBase.(cBoth{nIdxField})))) % not same values
        xBaseDiff.(cBoth{nIdxField}) = xBase.(cBoth{nIdxField});
        xNewDiff.(cBoth{nIdxField}) = xNew.(cBoth{nIdxField});
        
    elseif ischar(xNew.(cBoth{nIdxField})) && ... % string
            ~strcmp(xNew.(cBoth{nIdxField}),xBase.(cBoth{nIdxField}))
        xBaseDiff.(cBoth{nIdxField}) = xBase.(cBoth{nIdxField});
        xNewDiff.(cBoth{nIdxField}) = xNew.(cBoth{nIdxField});
    end
end

% generate singular field subsets of structures...
% ... for xBase
for nIdxField = 1:numel(cBaseXor)
    xBaseXor.(cBaseXor{nIdxField}) = xBase.(cBaseXor{nIdxField});
end
% ... for xNew
for nIdxField = 1:numel(cNewXor)
    xNewXor.(cNewXor{nIdxField}) = xNew.(cNewXor{nIdxField});
end

% command line display
if nOutput
    cDiff = fieldnames(xBaseDiff);
    disp([num2str(numel(cBaseXor)) ' unique fields in first struct, ' ...
          num2str(numel(cNewXor)) ' unique fields in second struct, ' ...
          num2str(numel(fieldnames(xBaseDiff))) ' different fields'])
    if ~isempty(cBaseXor)
        disp('Unique fields in first structure: ')
        for nIdxField = 1:numel(cBaseXor)
            fprintf(1,'\t%s\n',cBaseXor{nIdxField});
        end
    end
    if ~isempty(cNewXor)
        disp('Unique fields in second structure: ')
        for nIdxField = 1:numel(cNewXor)
            fprintf(1,'\t%s\n',cNewXor{nIdxField});
        end
    end
    if ~isempty(cDiff)
        disp('Fields in both structures, but different content:')
        for nIdxField = 1:numel(cDiff)
            fprintf(1,'\t Field: %s\n',cDiff{nIdxField});
            fprintf(1,'\t\t Struct1: \n');
            disp(xBaseDiff.(cDiff{nIdxField}))
            fprintf(1,'\t\t Struct2: \n');
            disp(xNewDiff.(cDiff{nIdxField}))
        end
    end
end
return
