function [xOut,cOther] = hlxZtagParse(sOut)
% HLXZTAGPARSE parse the output of Perforce Helix p4 commands issued with
% the -Ztag flag.
%
% Syntax:
%   [xOut,sWarn] = hlxZtagParse(sOut)
%
% Inputs:
%   sOut - string with output of a "p4 -z tag ..." command
%
% Outputs:
%     xOut - structure (1xn) with zTag output block and fields of single
%            output elements per output block
%   cOther - cell with lines not start with -Ztag output ("... ") 
%
% Example: 
%   [xOut,sWarn] = hlxZtagParse(sOut)
%
% See also: p4
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-02-06

% initialize output
xOut = struct([]);
cOther = {};

% check input
if isempty(sOut) || ~ischar(sOut)
    return
end

% split Ztag output from warnings and additional output
cOut = strsplitOwn(sOut,char(10),false); %#ok<CHARTEN>
bEmpty = cellfun(@isempty,cOut);
bTag = cellfun(@(x)strcmp(x(1:min(numel(x),4)),'... '),cOut);
bPath = cellfun(@(x)strcmp(x(1:min(numel(x),6)),'... //'),cOut); % path based warnings
bTag = bTag & ~bPath;
bOther = ~bEmpty & ~bTag;
cOther = cOut(bOther);
cOut = cOut(~bOther);
bEmpty = bEmpty(~bOther);

% parse blocks for output elements
nEmpty = [0 find(bEmpty)' numel(cOut)+1];
for nIdxEmpty = 1:numel(nEmpty)-1
    % skip consecuting blank lines
    if nEmpty(nIdxEmpty)+1 == nEmpty(nIdxEmpty+1)
        continue
    end
    % define range and block
    nStart = nEmpty(nIdxEmpty)+1;
    nEnd = nEmpty(nIdxEmpty+1)-1;
    nStruct = numel(xOut) + 1;
    
    % loop over lines of block
    for nIdxLine = nStart:nEnd
        cSplit = strsplitOwn(cOut{nIdxLine},' ',true);
        
        % create struct field entry
        xOut(nStruct).(cSplit{2}) = strGlue(cSplit(3:end),' ');
    end
end
return
