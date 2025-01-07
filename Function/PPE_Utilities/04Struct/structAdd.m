function x = structAdd(x,xAdd,nVerbose)
% STRUCTADD add a structure to another structure while preserving any
% content. The resulting structure contains any field of the source
% structure. If a field is present in both structures, the field is
% extended into a structure vector.
%
% Syntax:
%   x = structAdd(x,xAdd) 
%   x = structAdd(x,xAdd,nVerbose) 
%
% Inputs:
%          x - structure with arbitrary MATLAB structure
%       xAdd - structure with arbitrary MATLAB structure
%   nVerbose - integer with verbosity level (0: no warnings, 1:warnings)
%
% Outputs:
%   x - structure containing the elements of both source structures
%
% Example: 
%   x = structAdd(struct('a',{11},'b',{11}),struct('b',{22},'c',{22}))
%   x = structAdd(struct('a',{11},'b',{11},'c',{11},'e',{11}),struct('b',{22},'c',{0},'d',{33}))
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-17

% check input
if nargin < 3
    nVerbose = 1;
end

% loop over fiels to add
cFieldAdd = fieldnames(xAdd);
for nIdxField = 1:numel(cFieldAdd)
    if isfield(x,cFieldAdd{nIdxField})% if fields exists already, add new field as further structure vector element
        % check for similar structure fields
        if isstruct(x.(cFieldAdd{nIdxField})) && ...
                isstruct(xAdd.(cFieldAdd{nIdxField})) && ...
                ~isequal(sort(fieldnames(x.(cFieldAdd{nIdxField}))),...
                         sort(fieldnames(xAdd.(cFieldAdd{nIdxField}))))
            % get fieldnames
            cOld = fieldnames(x.(cFieldAdd{nIdxField}));
            cNew = fieldnames(xAdd.(cFieldAdd{nIdxField}));
            
            % get differences
            [cExclusive,nEmpty,nOmit] = setxor(cOld,cNew); %#ok<ASGLU>
                     
            % user info of structure missmatch
            if nVerbose
                fprintf(2,['Warning: structAdd encountered dissimilar ' ...
                    'structures when adding field "%s" to a structure ' ...
                    'vector of %i elements\n'],...
                    cFieldAdd{nIdxField},numel(x.(cFieldAdd{nIdxField})));
                for nIdxEmpty = nEmpty' % transpose for correct empty vector detection
                    fprintf(2,['  subfield "%s" - is not in the added struct ' ...
                        'and will be empty in new entries\n'],cOld{nIdxEmpty});
                end
                for nIdxOmit = nOmit' % transpose for correct empty vector detection
                    fprintf(2,['  subfield "%s" - is not in the existing struct ' ...
                        'and will empty in existing entries\n'],cNew{nIdxOmit});
                end
            end
                     
            % try to concatenate (automatic field patching)
            for nIdxFieldLength = 1:numel(xAdd.(cFieldAdd{nIdxField})) % for length of structure vector
                x.(cFieldAdd{nIdxField}) = structConcat(x.(cFieldAdd{nIdxField}),...
                                                        xAdd.(cFieldAdd{nIdxField})(nIdxFieldLength));
            end % for length of structure vector
            
        else % if all structs with same fieldnames
            for nIdxFieldLength = 1:numel(xAdd.(cFieldAdd{nIdxField})) % for length of structure vector
                if isstruct(x.(cFieldAdd{nIdxField})) && isstruct(xAdd.(cFieldAdd{nIdxField}))
                    % try to concatenate (resorting)
                    x.(cFieldAdd{nIdxField}) = structConcat(x.(cFieldAdd{nIdxField}),...
                                                        xAdd.(cFieldAdd{nIdxField})(nIdxFieldLength));
                else
                    % do the old stuff - fails with data type mixture
                    x.(cFieldAdd{nIdxField})(end+1) = xAdd.(cFieldAdd{nIdxField})(nIdxFieldLength); % old code - non robust
                end
            end % for length of structure vector
        end % if all structs with same fieldnames
        
    else % add new field as new structure field
        x.(cFieldAdd{nIdxField}) = xAdd.(cFieldAdd{nIdxField});
    end
end
return
