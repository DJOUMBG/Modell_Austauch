classdef ocKeyValue
    % OCKEYVALUE key pair object based for single/scalar values on a key alike JSON data. Can be
    % constructed from cell arrays or structs.
    % 
    % cKeyValue = {'key1','value1'
    %              'key2','value2'
    %              'key3','value3'};
    %
    % Tests:
    % oKey = ocKeyValue({'key1','value1';'key2','value2';'key3','value3';'key4','value4'});
    % oKey = ocKeyValue({'key1';'key2';'key3';'key4'},{'value1';'value2';'value3';'value4'});
    % oKey = ocKeyValue(struct('key1',{'value1'},'key2',{'value2},'key3',{'value3'}));
    % oKey = ocKeyValue(struct('key1',{'value1'},'key2',{'value2},'key3',{'value3'}),{'key2','key3'});
    %
    % Private methods: createFromStruct
    %
    % Author: Rainer Frey, TT/XCF, Daimler Truck AG
    %  Phone: +49-711-8485-3325
    % MailTo: rainer.r.frey@daimlertruck.com
    %   Date: 2022-05-17
    %
    % See also: ocKeyValueFile
    
    properties (Dependent)
        xKeyValue struct % structure representation of key value sets with keys as fields
    end
    
    properties (Access = public)
        cKeyValue cell % {mustBeText} only allowed since R2020b % cell array (mxn) of char array key pairs in each row
    end
    
    % *********************************************************************
    
    methods
        function xKeyValue = get.xKeyValue(oThis)
            % get.xKeyValue creates the xKeyValue property as struct from the key value pairs with
            % the keys as fieldnames
            %
            % Syntax:
            %   xKeyValue = ocKeyValue.xKeyValue
            %
            % Outputs:
            %   xKeyValue - struct (1x1) with keys as fields and values as field assignments
            %
            % Tests:
            %   xKeyValue = ocKeyValue({'a1','b1';'a2','b2';'a4','b4';'a3','b3'}).xKeyValue
            
            % create unique string from key elements
            cStruct = reshape([oThis.cKeyValue(:,1),cellfun(@(x){x},oThis.cKeyValue(:,2),'UniformOutput',false)]',1,[]);
            xKeyValue = struct(cStruct{:});
        end
        
        % =================================================================
        
        function oThis = set.xKeyValue(oThis,xKeyValue)
            % set.cKeyValue ensures that the file lines are created/updated, when the xKeyValue
            % property is set.
            %
            % Syntax:
            %   ocKeyValue.xKeyValue.(sKey1) = 'value1'
            %
            % Outputs:
            %   oKeyValue - object (1x1) of class ocKeyValue
            %
            % Tests:
            %   oKV = ocKeyValue({'a1','b1';'a2','b2'}); oKV.xKeyValue.a2 = 'b2set'; strcmp(oKV.cKeyValue{2,2},'b2set')
            
            % create unique string from key elements
            cField = fieldnames(xKeyValue);
            cValue = cellfun(@(x)xKeyValue.(x),cField,'UniformOutput',false);
            oThis.cKeyValue = [cField,cValue];
        end
    end % methods <general>
    
    % *********************************************************************
    
    methods (Access = public)
        
        function oThis = ocKeyValue(varargin) % Constructor
            % ocKeyValue creates key object from single cell array, multiplecell arrays, structure vector
            % fields or structure vector Creates the ocKey object from single cell array, multiple
            % cell arrays, scalar structure fields or  scalar structure fields with field limitations
            %
            % Syntax:
            %   oKeyValue = ocKeyValue(cell(mxn)) 
            %   oKeyValue = ocKeyValue(cell(mx1),cell(mx1),cell(mx1),...) 
            %   oKeyValue = ocKeyValue(struct(mx1)) oKey = ocKey(struct(mx1),cellOfFields)
            %
            % Inputs:
            %   varargin{1} - cell array (mxn) of strings or
            %               - struct(mx1) with fields of string value
            %   varargin{2} - cell array (1xn) of strings with field names
            %                 to be used as keys
            %   varargin{1..n} - cell array (mx1) of strings, cell arrays
            %                    will be horizontal concatenated to create an overall key cell
            %
            % Outputs:
            %   oKey - object of class ocKey
            %
            % Tests:
            %   oKeyValue = ocKeyValue({'key1','value1';'key2','value2';'key3','value3';'key4','value4'});
            %   oKeyValue = ocKeyValue({'key1';'key2';'key3';'key4'},{'value1';'value2';'value3';'value4'}); 
            %   oKeyValue = ocKeyValue(struct('key1',{'value1'},'key2',{'value2'},'key3',{'value3'}));
            %   oKeyValue = ocKeyValue(struct('key1',{'value1'},'key2',{'value2'},'key3',{'value3'}),{'key2','key3'});
            
            % create
            if nargin == 0 % enable zero argument calling for superclass capability
                oThis.cKeyValue = cell(0,2); 
                
            elseif iscell(varargin{1}) && ...
                    size(varargin{1},2)==2 && ...
                    nargin == 1
                % single cell array with multiple columns
                oThis.cKeyValue = varargin{1};
                
            elseif isstruct(varargin{1})
                % create keyvalue from scalar structure with its fields and the values
                % (Remark: do not extract this in a private method - Matlab does not support
                %          constructor splitting) 

                % determine structure field span
                xKeyValue = varargin{1};
                cField = fieldnames(xKeyValue);
                if nargin > 1 && iscell(varargin{2})
                    cFieldLimit = varargin{2};
                    bUse = ismember(cField,cFieldLimit);
                    if sum(bUse) < numel(cFieldLimit)
                        [cMiss,~,nMissLimit] = setxor(cField,cFieldLimit);
                        fprintf(2,['ocKey:create - following struct fields ' ...
                            'requested for key generation are no valid ' ...
                            'fields of the provided struct:\n']);
                        fprintf(2,'    %s\n',cMiss(nMissLimit));
                    end
                    cField = cField(bUse);
                end

                % create cell from structure values
                cKeyValue = repmat({''},numel(cField),numel(xKeyValue)+1);
                cKeyValue(:,1) = cField;
                for nIdxField = 1:numel(cField)
                    cKeyValue(nIdxField,2:end) = {xKeyValue.(cField{nIdxField})};
                end
                oThis.cKeyValue = cKeyValue;

            elseif isa(varargin{1},'ocKeyValue')
                % self reference / recreate object
                oThis.cKeyValue = varargin{1}.cKeyValue;
                
            elseif all(cellfun(@iscell,varargin))
                % multiple cells to be combined to matrix
                oThis.cKeyValue = [varargin{:}];
            end
        end % function oThis = ocKeyValue
        
        % =================================================================
    end % methods (Access = public)
end