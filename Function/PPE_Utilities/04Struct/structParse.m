function xElement = structParse(value,level)
% structParse - creates list of structure subelements including type and
% size information
% 
% Input variables:
% value     - structure with fields and cells with further structures
% [level]   - level of currently passed value, optional intended as 1 if
%             omitted
% 
% Output variables:
% element    - structure with all subelements:
%   .sType   - string, type of subelement (structure,cellarray,matrice,string)
%   .vSize   - vector with size information
%   .nLevel  - value with subsequent level of element
%   .sName   - string with name of element (only filled for structure
%             fields)
%   .nContent - vector with position of element entries directly below
%              element (only with structures and cell arrays)
%   .cValue  - cell (1x2) with min and max value (matrices) or first and
%             last entry (cell array of characters only)
% 
% Example calls:
% element = structParse(structure)
% element = structParse(guidata(gcf))
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-01-26

% catch first level call
if nargin == 1
    level = 1;
end

% define variable types
cType = {'struct','cell','numeric','logical','char','function_handle','CoSimServer','timetable','datetime','duration'};

% fill own element information and do initialization
xElement.sType = cType{cellfun(@(x)isa(value,x),cType)};

xElement.vSize = size(value);
xElement.nLevel = level;
xElement.sName = '';
xElement.nContent = [];
xElement.cValue = {};

switch(xElement(1).sType)
    case 'struct'
        cField = fieldnames(value);
        for nIdxField = 1:length(cField) % for all fields of struct
            if isempty(value) % catch structures of size 0
                xSubElement.sType = 'struct';
                xSubElement.vSize = [0 0];
                xSubElement.nLevel = level+1;
                xSubElement.sName = cField{nIdxField};
                xSubElement.nContent = [];
                xSubElement.cValue = {};
            else
                xSubElement = structParse(value(1).(cField{nIdxField}),level+1);
            end
            
            % postprocessing of subelements
            % name of structure fields
            xSubElement(1).sName = cField{nIdxField};
            
            % position of elements
            for nIdxSubElement = 1:length(xSubElement)
                if ~isempty(xSubElement(nIdxSubElement).nContent)
                    xSubElement(nIdxSubElement).nContent = xSubElement(nIdxSubElement).nContent + length(xElement); %#ok<AGROW>
                end
            end
            
            % add element in content list
            xElement(1).nContent = [xElement(1).nContent length(xElement)+1];
            
            % store subelements
            xElement(end+1:end+length(xSubElement)) = xSubElement(:);
        end % for struct length
    case 'cell'
        if ~isempty(value)
            nSize = size(value);
            nTypeAll = 0;
            for nIdxType = 1:length(cType) % for all variable types
                nTypeTest = 0;
                for nIdxSubElement = 1:length(nSize) % for all dimensions of cell array
                    nTypeTest = nTypeTest + all(cellfun(@(x)isa(x,cType{nIdxType}),value));
                end
                nTypeTest = nTypeTest/length(nSize);
                if nTypeTest == 1
                    nTypeAll = nIdxType;
                    break
                end
            end
            
            switch nTypeAll
                case {1,2} % struct and cell
                    DimMat = ones(1,length(nSize));
                    DimCell = num2cell(DimMat);
                    xSubElement = structParse(value{DimCell{:}},level+1);
                    
                    % postprocessing of subelements
                    % position of elements
                    for nIdxSubElement = 1:length(xSubElement)
                        if ~isempty(xSubElement(nIdxSubElement).nContent)
                            xSubElement(nIdxSubElement).nContent = xSubElement(nIdxSubElement).nContent + length(xElement);
                        end
                    end
                    
                    % add element in content list
                    xElement(1).nContent = [xElement(1).nContent length(xElement)+1];
                    
                    % store subelements
                    xElement(end+1:end+length(xSubElement)) = xSubElement(:);
                    
                case {3,4} % numeric or boolean - return only information on values
                    mat = cell2mat(value);
                    min1 = min(mat);
                    max1 = max(mat);
                    xElement(1).cValue = {min(min1) max(max1)};
                case 5 % strings
                    xElement(1).cValue = {value{1} value{end}};
                case 6 % function handles
                    
                otherwise % cell contains mixed data types
                    DimMat = ones(1,length(nSize));
                    while ~isempty(DimMat)
                        DimCell = num2cell(DimMat);
                        xSubElement = structParse(value{DimCell{:}},level+1);
                        
                        % postprocessing of subelements
                        % position of elements
                        for nIdxSubElement = 1:length(xSubElement)
                            if ~isempty(xSubElement(nIdxSubElement).nContent)
                                xSubElement(nIdxSubElement).nContent = xSubElement(nIdxSubElement).nContent + length(xElement);
                            end
                        end
                        
                        % add element in content list
                        xElement(1).nContent = [xElement(1).nContent length(xElement)+1];
                        
                        % store subelements
                        xElement(end+1:end+length(xSubElement)) = xSubElement(:);
                        
                        % next element
                        DimMat = nextDimElem(DimMat,nSize);
                    end
            end
        end
    case {'numeric','logical'}
        min1 = min(value);
        max1 = max(value);
        xElement(1).cValue = {min(min1) max(max1)};
    case 'char'
        xElement.cValue = {value value};
    case 'timetable'
        xElement(1).cValue = 'timetable';
        xElement(2).sName = 'Time';
        xElement(2).sType = 'duration';
        xElement(2).nLevel = level+1;
        xElement(2).vSize = size(value.Time);
        xElement(2).cValue = {seconds(min(value.Time)) seconds(max(value.Time))};
        cVar = value.Properties.VariableNames;
        for nIdxDat = 1:numel(cVar)
            xElement(2+nIdxDat).sName = cVar{nIdxDat};
            xElement(2+nIdxDat).sType = cType{cellfun(@(x)isa(value.(cVar{nIdxDat})(1),x),cType)};
            xElement(2+nIdxDat).nLevel = level+1;
            xElement(2+nIdxDat).vSize = size(value.(cVar{nIdxDat}));
            if strcmp(xElement(2+nIdxDat).sType,'numeric')
                xElement(2+nIdxDat).cValue = {min(value.(cVar{nIdxDat}))  max(value.(cVar{nIdxDat}))};
            else
                xElement(2+nIdxDat).cValue = '';
            end
        end
        
%   .sType   - string, type of subelement (structure,cellarray,matrice,string)
%   .vSize   - vector with size information
%   .nLevel  - value with subsequent level of element
%   .sName   - string with name of element (only filled for structure
%             fields)
%   .nContent - vector with position of element entries directly below
%              element (only with structures and cell arrays)
%   .cValue  - cell (1x2) with min and max value (matrices) or first and
%             last entry (cell array of characters only)
    case {'datetime','duration'}
        
    otherwise
        fprintf(1,'type not covered: %s\n',xElement(1).sType);
end
return
