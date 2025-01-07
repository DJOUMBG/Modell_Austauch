function cField = p4FieldExpand(sField,cValue)
% P4FIELDEXPAND expand cell values into p4 field command for direct form
% filling.
% 
% perforce info on field usage:
% single field
% p4 --field Description="my test" change -o | p4 change -i
% 
% multiline fields (first field standard, each followup with "+=")
% p4 --field Files=//depot/tiny.file --field Files+=//depot/target.txt ...
% 
%
% Syntax:
%   cField = p4FieldExpand(sField,cValue)
%
% Inputs:
%   sField - string with name of form field
%   cValue - cell (1xn) with field command and value (description s. above)
%
% Outputs:
%   cField - cell (1xn) 
%
% Example: 
%   cField = p4FieldExpand('Users',{'rafrey5','pethama'})
%
% See also: p4 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-06-15

% init output
cField = {};

% check input
if size(cValue,1)>1 
    if size(cValue,2)==1
        % transpose to row cell
        cValue = cValue';
    else % no matrix handling possible
        error('p4FieldExpand:inputCellMatrix',...
            ['p4FieldExpand value input for field "%s" has a '...
             'multidimensional cell (%ix%i) - only row vectors are allowed!'],...
             sField,size(cValue,1),size(cValue,2));
    end
end

if ~isempty(cValue)
    % expand values to field strings
    if ismember(sField,{'Description','Paths','Remapped'})
        cField = cellfun(@(x)['--field ' sField '+="' x '"'],cValue,'UniformOutput',false);
    else
        cField = cellfun(@(x)['--field ' sField '+=' x],cValue,'UniformOutput',false);
    end
    % remove "+" sign from first entry
    cField{1}(9+numel(sField)) = [];
end
return
