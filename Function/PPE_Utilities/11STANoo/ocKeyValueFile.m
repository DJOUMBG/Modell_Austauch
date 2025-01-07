classdef ocKeyValueFile < ocFile & ocKeyValue
    
    %OCKEYVALUEFILE key value pair file object based on simple text files,
    % where key and value are separated by "=" signs.
    % 
    % Properties:
    %     cKeyValue @ocKeyValue - cell (mx2) with key value pairs
    %     xKeyValue @ocKeyValue - struct (1x1) with keys as fields
    %     sFile @ocFile, private - char (1xn) with filepath
    %     cLine @ocFile, private - cell (ox1) with strings of file lines
    % 
    % Methods:
    %     file @ocFile - get char of filepath
    %     lines @ocFile - get cell array of line content
    %     makeWritable @ocFile - remove readOnly
    %     setFile @ocFile - set char of filepath
    %     strtrim @ocFile - apply strtrim on line
    %     read
    %     scan
    %     write
    % 
    % Example:
    %   % create file object and write key value pairs
    %   oFileKV = ocKeyValueFile('C:\temp\testOutKeyValue.txt',{'key1','value1';'key2','value2'}).write
    %   % read file
    %   oFileKV = ocKeyValueFile('C:\temp\testOutKeyValue.txt').read
    %   % use key value pairs
    %   oFileKV.xKeyValue.key2 = 'newvalue'; oFileKV.write
    %   myValue = oFileKV.xKeyValue.key2;
    %
    % Private methods: parseLines
    %
    % Author: Rainer Frey, TT/XCF, Daimler Truck AG
    %  Phone: +49-711-8485-3325
    % MailTo: rainer.r.frey@daimlertruck.com
    %   Date: 2022-05-19
    %
    % See also: ocKeyValue, ocFile
    
    methods (Access = private)
        
        function oThis = parseLines(oThis)
            % parseLines splits the line content along "=" into key value pairs, cleans invisible
            % characters from the first cell and joins them as key/value cell of object.
            %
            % Syntax:
            %   oThis = parseLines(oThis)
            %
            % Inputs:
            %   oThis - object (1x1) of class ocKeyValue with properties:
            %     cLine (access method: lines) with cell (nx1) of strings with definition lines
            %
            % Outputs:
            %   oThis - object (1x1) with updated property
            %     .cKeyValue - cell (mx2) with key value pairs
            %
            % Example:
            %   oThis = parseLines(oThis)
            
            ccPair = regexp(oThis.lines,'\=','split','once'); % split lines
            bPair = cellfun(@(x)numel(x)==2,ccPair); % limit to key/value pairs
            cPair = vertcat(ccPair{bPair}); % flatten cell of cells
            cPair{1} = regexprep(cPair{1},'\W',''); % clean invisible characters (e.g. BOM)
            oThis.cKeyValue = cPair;
        end
    end
    
    % *********************************************************************
    
    methods (Access = public)
        
        function oThis = ocKeyValueFile(varargin) % Constructor
            %OCKEYVALUEFILE is a file object for read/write of scalar key value pairs to textfiles
            %
            % Syntax:
            %   oThis = ocKeyValueFile()
            %   oThis = ocKeyValueFile(sFile)
            %   oThis = ocKeyValueFile(sFile,cKeyValue)
            %   oThis = ocKeyValueFile(cKeyValue,sFile)
            %   oThis = ocKeyValueFile(sFile,cKey,cValue)
            %   oThis = ocKeyValueFile(sFile,xKeyValue)
            %   oThis = ocKeyValueFile(sFile,xKeyValue,cLimit)
            %
            % Inputs:
            %       sFile - char (1xn) with filepath of file
            %   cKeyValue - [optional] cell (mx2) with keys and their values (both text)
            %        cKey - [optional] cell (mx1) with keys
            %      cValue - [optional] cell (mx1) with values
            %   xKeyValue - [optional] with keys fields and their values (both text)
            %      cLimit - [optional] cell (nx1) with strings of fieldnames for keyvalue creation
            %
            % Outputs:
            %   oThis - object (1x1) of class ocKeyValue
            %
            % Tests:
            %   oThis = ocKeyValueFile()
            %   oThis = ocKeyValueFile('C:\temp\testOutKeyValue.txt')
            %   oThis = ocKeyValueFile('C:\temp\testOutKeyValue.txt',{'key1','value1';'key2','value2';'key3','value3';'key4','value4'})
            %   oThis = ocKeyValueFile('C:\temp\testOutKeyValue.txt',{'key1';'key2';'key3';'key4'},{'value1';'value2';'value3';'value4'})
            %   oThis = ocKeyValueFile('C:\temp\testOutKeyValue.txt',struct('key1',{'value1'},'key2',{'value2'},'key3',{'value3'}))
            %   oThis = ocKeyValueFile('C:\temp\testOutKeyValue.txt',struct('key1',{'value1'},'key2',{'value2'},'key3',{'value3'}),{'key2','key3'})
            
            % check input
            bChar = cellfun(@ischar,varargin);
            
            % call superclass constructors
            oThis@ocFile(varargin{bChar}); % char -> filepath 
            oThis@ocKeyValue(varargin{~bChar}); % cell or struct arguments for keyvalue
        end
        
        % ==========================================================================================
        
        function oThis = scan(oThis,varargin)
            % read reads and converts line content into keyvalues
            %
            % Syntax:
            %   oThis = scan(oThis)
            %   oThis = scan(oThis,varargin)
            %
            % Outputs:
            %   oThis - object (1x1) of class ocKeyValue
            %
            % Tests:
            %   oFile = ocKeyValueFile('C:\temp\testScanKeyValue.txt',{'key1','value1';'key2','value2'}).write; oRead = oFile.scan 
            oThis = scan@ocFile(oThis,varargin{:});
            oThis = parseLines(oThis);
        end
        
        % ==========================================================================================
        
        function oThis = read(oThis,varargin)
            % read reads and converts line content into keyvalues
            %
            % Syntax:
            %   oThis = read(oThis)
            %   oThis = read(oThis,varargin)
            %
            % Outputs:
            %   oThis - object (1x1) of class ocKeyValue
            %
            % Tests:
            %   oFile = ocKeyValueFile('C:\temp\testScanKeyValue.txt',{'key1','value1';'key2','value2'}).write; oRead = oFile.read
            oThis = read@ocFile(oThis,varargin{:});
            oThis = parseLines(oThis);
        end

        % ==========================================================================================
        
        function oThis = write(oThis,varargin)
            % write converts key value pairs into lines and writes them to file
            %
            % Syntax:
            %   oThis = write(oThis)
            %   oThis = write(oThis,varargin)
            %
            % Outputs:
            %   oThis - object (1x1) of class ocKeyValue
            %
            % Tests:
            %   oFile = ocKeyValueFile('C:\temp\testScanKeyValue.txt',{'key1','value1';'key2','value2'}).write
            oThis.cLine = cellfun(@(x,y)sprintf('%s=%s',x,y),oThis.cKeyValue(:,1),oThis.cKeyValue(:,2),'UniformOutput',false);
            oThis = write@ocFile(oThis,varargin{:});
        end
        
    end
end