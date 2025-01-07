classdef ocKey 
    %OCKEY key pair object based on multi-column cells
    %   For character vector keys distributed in multiple cell columns, but belonging together. One
    %   row of the cell represents the elements of one key. Implements comprehended functions and
    %   Matlab syntax extensions.
    % 
    % Tests:
    % oKey = ocKey({'a1','b1';'a2','b2';'a4','b4';'a3','b3';'a2','b2'});
    % oKey = ocKey({'a1';'a2';'a3';'a4'},{'b1';'b2';'b3';'b4'});
    % oKey = ocKey(struct('a',{'a1';'a2';'a2';'a4'},'b',{'b1';'b2';'b2';'b4'},'c',{'c1';'c3';'c2';'c4'}),{'a','b'});
    %
    % Private methods: create
    %
    % Author: Rainer Frey, TT/XCF, Daimler Truck AG
    %  Phone: +49-711-8485-3325
    % MailTo: rainer.r.frey@daimlertruck.com
    %   Date: 2021-11-29
    %
    % See also: unique, setxor, cell, struct
    
    properties (Dependent)
        cKeyJoin cell %  {mustBeText} only allowed since R2020b % cell array (mx1) of char with key pairs of rows joined with "__"
    end
    
    properties (Access = public)
        cKey cell %  {mustBeText} only allowed since R2020b % cell array (mxn) of char array key pairs in each row
    end
    
    % *********************************************************************
    
    methods
        function cKeyJoin = get.cKeyJoin(oThis)
            % get.cKeyJoin creates the cKeyJoin property as joined string from all elements 
            % of each key row
            %
            % Syntax:
            %   cKeyJoin = ocKey.cKeyJoin
            %
            % Outputs:
            %   cKeyJoin - cell (mx1) with joined strings of cKey rows joined with "__" as unique key
            %
            % Tests:
            %   cKeyJoin = ocKey({'a1','b1';'a2','b2';'a4','b4';'a3','b3';'a2','b2'}).cKeyJoin
            
            % create unique string from key elements
            cKeyJoin = cell(size(oThis.cKey,1),1);
            for nIdxRow = 1:size(oThis.cKey,1)
                cKeyJoin{nIdxRow,1} = strjoin(oThis.cKey(nIdxRow,:),'__');
            end
        end
    end % methods <general>
    
    % *********************************************************************
    
    methods (Access = public)
        
        function oThis = ocKey(varargin) % Constructor
            % OCKEY creates key object from single cell array, multiplecell arrays, structure vector fields or structure vector
            % Creates the ocKey object from single cell array, multiple cell arrays, structure 
            % vector fields or structure vector with field limitations 
            %
            % Syntax:
            %   oKey = ocKey(cell(mxn))
            %   oKey = ocKey(cell(mx1),cell(mx1),cell(mx1),...)
            %   oKey = ocKey(struct(mx1))
            %   oKey = ocKey(struct(mx1),cellOfFields)
            %
            % Inputs:
            %   varargin{1} - cell array (mxn) of strings or
            %               - struct(mx1) with fields of string value
            %   varargin{2} - cell array (1xn) of strings with field names 
            %                 to be used as keys
            %   varargin{1..n} - cell array (mx1) of strings, cell arrays
            %                    will be horizontal concatenated to create 
            %                    an overall key cell
            %
            % Outputs:
            %   ocKey - object
            %
            % Tests:
            %   oKey = ocKey({'a1','b1';'a2','b2';'a3','b3';;'a4','b4'});
            %   oKey = ocKey({'a1','b1';'a2','b2';'a4','b4';'a3','b3';'a2','b2'});
            %   oKey = ocKey({'a1';'a2';'a3';'a4'},{'b1';'b2';'b3';'b4'});
            %   oKey = ocKey(struct('a',{'a1';'a2';'a2';'a4'},'b',{'b1';'b2';'b2';'b4'},'c',{'c1';'c3';'c2';'c4'}));
            %   oKey = ocKey(struct('a',{'a1';'a2';'a2';'a4'},'b',{'b1';'b2';'b2';'b4'},'c',{'c1';'c3';'c2';'c4'}),{'a','b'});
            
            if nargin==0 % enable zero argument calling for superclass capability
                oThis.cKey = cell(0,2);
                
            elseif iscell(varargin{1}) && ...
                    size(varargin{1},2)>1 && ...
                    nargin == 1
                % single cell array with multiple columns
                oThis.cKey = varargin{1};
                
            elseif isstruct(varargin{1})
                % combine structure vector as rows with fields as columns
                
                % determine structure field span
                cField = fieldnames(varargin{1});
                if iscell(varargin{2})
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
                oThis.cKey = repmat({''},numel(varargin{1}),numel(cField));
                if ~isempty(varargin{1})
                    for nIdxField = 1:numel(cField)
                        oThis.cKey(:,nIdxField) = {varargin{1}.(cField{nIdxField})};
                    end
                end
                
            elseif isa(varargin{1},'ocKey')
                % self reference / recreate object
                oThis.cKey = varargin{1}.cKey;
                
            elseif all(cellfun(@iscell,varargin))
                % multiple cells to be combined to matrix
                oThis.cKey = [varargin{:}];
            end
        end
        
        % =================================================================
        
        function [cKey,nIdOld2New,nIdNew2Old] = unique(oThis,varargin)
            %UNIQUE reduce to unique set while respect all columns of key
            % Before applying unique function the key cell columns are
            % combined to respect all key elements.
            %
            % Syntax:
            %   [cKey,nIdOld2New,nIdNew2Old] = unique(oThis,varargin)
            %
            % Inputs:
            %      oThis - object (1x1) of class ocKey
            %   varargin - [optional] arguments of builtin uni
            %
            % Outputs:
            %         cKey - cell (mxn) with unique and sorted keys per row
            %   nIdOld2New - integer (1xm) with indices so cKey = ocKey.cKey(:,nIdOld2New)
            %   nIdNew2Old - integer (1xn) with indices so ocKey.cKey = cKey(:,nIdNew2Old)
            %
            % Example:
            %   [cKey,nIdOld2New,nIdNew2Old] = unique(ocKey({'a1','b1';'a2','b2';'a4','b4';'a3','b3';'a2','b2'}));
            %   [cKey,nIdOld2New,nIdNew2Old] = ocKey({'a1','b1';'a2','b2';'a4','b4';'a3','b3';'a2','b2'}).unique;
            
            % apply unique function on unique string
            [~,nIdOld2New,nIdNew2Old] = unique(oThis.cKeyJoin,varargin{:});
            cKey = oThis.cKey(nIdOld2New,:);
        end
        
        % =================================================================
        
        function [cKey,nIdA,nIdB] = setxor(oKeyA,oKeyB,varargin)
            % setxor determines exlcusive "or" sets of two key objects.
            %
            % Syntax:
            %   [cKey,nIdA,nIdB] = setxor(oKeyA,oKeyB,varargin)
            %
            % Inputs:
            %      oKeyA - object (1x1) of class ocKey
            %      oKeyB - object (1x1) of class ocKey
            %   varargin - [optional] arguments of builtin setxor function
            %
            % Outputs:
            %   cKey - cell (mxn) of joined key exclusive in oKeyA or oKeyB
            %   nIdA - integer (1x1) with exclusive keys in oKeyA.cKey(:,nIdA)
            %   nIdB - integer (1x1) with exclusive keys in oKeyB.cKey(:,nIdB)
            %
            % Example:
            %   [cKey,nIdA,nIdB] = setxor(ocKey({'a1','b1';'a2','b2';'ex_a3','b3'}),ocKey({'a1','b1';'a2','b2';'a3','ex_b3'}))
            %   [cKey,nIdA,nIdB] = setxor(ocKey({'a1','b1';'ex_a2','b2';'a3','b3'}),ocKey({'a1','b1';'a2','b2';'a3','ex_b3'}))
            
            % apply unique function on unique string
            [~,nIdA,nIdB] = setxor(oKeyA.cKeyJoin,oKeyB.cKeyJoin,varargin{:});
            cKey = [oKeyA.cKey(nIdA,:);oKeyB.cKey(nIdB,:)];
        end
        
        % =================================================================
        
        function [bMember,nIdB] = ismember(oKeyA,oKeyB,varargin)
            % ismember checks if the oKeyA elements are in oKeyB. It also determines the index of
            % oKeyA element in oKeyB so that oKeyA.cKeyUnique = oKeyB.cKeyUnique(nIdB) if all
            % elements of oKeyA are within oKeyB. If elements of oKeyA miss in oKeyB, the index
            % vector contains a 0 at this position
            %
            % Syntax:
            %   [bMember,nIdB] = ismember(oKeyA,oKeyB,varargin)
            %
            % Inputs:
            %      oKeyA - object (1x1) of class ocKey
            %      oKeyB - object (1x1) of class ocKey
            %   varargin - [optional] arguments of builtin ismember function
            %
            % Outputs:
            %   bMember - boolean (mx1) if key in oKeyA exists also in oKeyB
            %   nIdB - integer (1x1) which keys of oKeyB.cKey(:,nIdB) generate oKeyA
            %
            % Example:
            %   [bMember,nIdB] = ismember(ocKey({'a1','b1';'a2','b2';'ex_a3','b3'}),ocKey({'a1','b1';'a2','b2';'a3','ex_b3'}))
            %   [bMember,nIdB] = ismember(ocKey({'a1','b1';'ex_a2','b2';'a3','b3'}),ocKey({'a1','b1';'a2','b2';'a3','ex_b3'}))
            
            % apply unique function on unique string
            [bMember,nIdB] = ismember(oKeyA.cKeyJoin,oKeyB.cKeyJoin,varargin{:});
        end
        
    end % methods (Access = public)
end