function varargout = structExtract(structure,listcell) %#ok used in eval
% structExtract - extracts the structure fields, which are listed by
% full name in a cell into the return structure.
% 
% Input variables:
% structure     - structure including the extraction elements
% listcell      - cell with strings with the full element description 
% 
% Output variables:
% structure     - structure containing only the requested elements
% 
% Example calls:
% sMP = structExtract(s,{'num','vec'})
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-02-07

% get passed struct name
pos = strfind(listcell{1},'.');
if isempty(pos)
    warning('structExACT:wrongInput','The passed list cell contains non-structure element requests.');
end
structname = listcell{1}(1:pos(1)-1);

% extract structure elements
for k = 1:length(listcell)
    eval([listcell{k} ' = structure'  listcell{k}(pos(1):end) ';']);
end

varargout{1} = eval(structname);
return
