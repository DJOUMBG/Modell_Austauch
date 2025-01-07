function cHit = structFind(xVar,sMode,svValue)
% structFind - find fieldnames or values within deep structured vaiables,
% limitations of dimensions are: structure(1), cell(2), matrix(2)
% 
% Input variables:
%        xVar - structure with fields and cells with further structures
%       sMode - string with execution mode
%               'field': searches a specified fieldname
%               'fieldvar': searches a specified fieldname and return
%                           values as well
%               'variable': searches a specified value
%     svValue - string with fieldname or string/number of value to be found
% 
% Output variables:
%      cHit - cell vector with strings to describe found position within
%             structure
% 
% Example calls:
% structFind(data,'variable','cmap_EGRCooler_OM934DTCEU6.mat')
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-03-19

cHit = {};
if isstruct(xVar)
    cField = fieldnames(xVar);
    for nIdxStruct = 1:length(xVar) % for struct length
        for nIdxField = 1:length(cField) % for all fields of struct
            cHitSub = structFind(xVar(nIdxStruct).(cField{nIdxField}),sMode,svValue);
            for nIdxSub = 1:size(cHitSub,1)
                if length(xVar)>1
                    cHit{end+1,1} = sprintf('(%i).%s%s',nIdxStruct,cField{nIdxField},cHitSub{nIdxSub,1}); %#ok<AGROW>
                else
                    cHit{end+1,1} = ['.' cField{nIdxField} cHitSub{nIdxSub,1}]; %#ok<AGROW>
                end
                if size(cHitSub,2) > 1
                    cHit(end,2) = cHitSub(nIdxSub,2);
                end
            end
        end % for all fields of struct
    end % for struct length
    
    if strcmpi(sMode(1:5),'field') % 
        for nIdxStruct = 1:length(xVar) % for struct length
            for nIdxField = 1:length(cField)
                if strcmpi(cField{nIdxField},svValue)
                    if length(xVar)>1
                        cHit{end+1,1} = sprintf('(%i).%s',nIdxStruct,cField{nIdxField}); %#ok
                    else
                        cHit{end+1,1} = sprintf('.%s',cField{nIdxField}); %#ok
                    end
                    if strcmpi(sMode,'fieldvar')
                        cHit{end,2} = xVar(nIdxStruct).(cField{nIdxField});
                    end
                end
            end
        end
    end
elseif iscell(xVar) % current searched variable structure is a cell
    cellsize = size(xVar);
    if length(cellsize)>2
        disp('WARNING: cell with more than 2 dimensions found!');
    else 
        for nIdxStruct = 1:cellsize(1)
            for nIdxField = 1:cellsize(2)
                cHitSub = structFind(xVar{nIdxStruct,nIdxField},sMode,svValue);
                for nIdxSub = 1:size(cHitSub,1)
                    cHit{end+1,1} = ['{' num2str(nIdxStruct) ',' num2str(nIdxField) '}' cHitSub{nIdxSub,1}]; %#ok
                    if size(cHitSub,2) > 1
                        cHit(end,2) = cHitSub(nIdxSub,2);
                    end
                end
            end
        end
    end
elseif isnumeric(xVar) % current searched variable structure is numeric
    matsize = size(xVar);
    if length(matsize)>2
        disp('WARNING: matrix with more than 2 dimensions found!');
    end
    for nIdxStruct = 1:matsize(1)
        for nIdxField = 1:matsize(2)
            if strcmpi(sMode,'variable') && isnumeric(svValue) && ~isempty(xVar(nIdxStruct,nIdxField)) && xVar(nIdxStruct,nIdxField) == svValue
                cHit{1,1} = [' = ' num2str(xVar(nIdxStruct,nIdxField))];
            end
        end
    end
elseif ischar(xVar) % current searched variable structure is string
    if strcmpi(sMode,'variable') && ...
            ischar(svValue) && ...
            ~isempty(xVar)
        if strcmpi(xVar,svValue)
            cHit{1,1} = [' = ' svValue];
        elseif ~isempty(regexpi(xVar,svValue,'match','once'))
            cHit{1,1} = [' = ' svValue '; % regexp hit'];
        end
    else
        
    end
end
return