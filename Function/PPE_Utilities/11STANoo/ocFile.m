classdef ocFile
    
    %OCFILE file object for read/write access
    % For character vector keys distributed of multiple cell columns, but
    % belonging together. Implements comprehended functions and Matlab
    % syntax extensions.
    % 
    % Properties:
    %     sFile - char (1xn) with filepath
    %     cLine - cell (ox1) with strings of file lines
    % 
    % Methods:
    %     checkExistence - ensure file existence 
    %     file - get char of filepath
    %     lines - get cell array of line content
    %     makeWritable - remove readOnly
    %     setFile - set char of filepath
    %     strtrim - apply strtrim on line
    % 
    % Examples:
    %   oFile = ocFile('newfile.m').write('Just a char array');
    %   oFile = ocFile('newfile.m').write({'multiple lines','   are written','here  '});
   	%   cLine = ocFile('newfile.m').scan.lines %#@ (without leading whitespaces -> textscan '%s')
   	%   cLine = ocFile('newfile.m').read.lines %#@ (with invisible characters)
    %
    % Private methods: create
    %
    % Author: Rainer Frey, TT/XCF, Daimler Truck AG
    %  Phone: +49-711-8485-3325
    % MailTo: rainer.r.frey@daimlertruck.com
    %   Date: 2022-05-18
    %
    % See also: fileread, textscan, cell, strtrim, fopen, fclose, fprintf
    
    properties (Access = protected)
        sFile char = ''% string with filepath of read file
        cLine % cell array (mx1) of strings with lines of file
    end
    
    properties (Access = public)
    end
    
    % *********************************************************************
    
    methods (Access = protected)

        function checkExistence(oThis)
            % checkExistence checks existence of file in file system
            if exist(oThis.sFile,'file')~=2
                error('ocFile:fileNotFound','The specified file was not found on the file system: %s',oThis.sFile);
            end
        end
        
        % =================================================================
        
        function oThis = readFile(oThis)
            % readFile read file and split into lines
            sContent = fileread(oThis.sFile);
            oThis.cLine = strsplit(sContent,{char(13),char(10)})';
        end
        
        % =================================================================
        
        function oThis = scanFile(oThis,varargin)
            % scanFile open file and split into lines via textscan. 
            % This approach omits blanks alike strtrim.
            %
            % Syntax:
            %   oThis = readFile(oThis,varargin)
            %
            % Inputs:
            %      oThis - object (1x1)
            %   varargin - cell (1xn) of string with options to fopen
            
            nFid = fopen(oThis.sFile,'r',varargin{:});
            ccLine = textscan(nFid,'%s','Delimiter',char(10));
            fclose(nFid);
            oThis.cLine = ccLine{1};
        end
        
        % =================================================================
        
        function sFile = writeFile(oThis,varargin)
            % writeFile write cLine to file (overwriting file)
            %
            % Syntax:
            %   oThis = writeFile(oThis,cLine,varargin)
            %
            % Inputs:
            %      oThis - object (1x1) of class
            %      cLine - cell (mx1) of string with options lines to write
            %   varargin - cell (1xn) of strings with options to fopen
            
            % ensure directory
            cPath = pathparts(oThis.sFile);
            for nIdxPath = 2:numel(cPath)-1
                if exist(fullfile(cPath{1:nIdxPath}),'dir') ~= 7
                    mkdir(fullfile(cPath{1:nIdxPath}));
                end
            end
            
            % write file
            [nFid,sMsg] = fopen(oThis.sFile,'w',varargin{:});
            if nFid < 0
                error('ocFile:failureFileOpen',...
                    'The fopen operation failed on the specified file: %s\n Error message: %s',oThis.sFile,sMsg);
            end
            for nIdxLine = 1:numel(oThis.cLine)
                fprintf(nFid,'%s\n',oThis.cLine{nIdxLine});
            end
            fclose(nFid);
            
            sFile = oThis.sFile;
        end
        
    end % methods (Access = protected)
        
    % *********************************************************************
    
    methods (Access = public)
        
        function oThis = ocFile(varargin) % Constructor
            %ocFile create ocFile object for text file read/write operation
            %
            % Tests:
            %   oFile = ocFile(which('ocFile'))
            
            % check input
            if nargin == 0 % enable zero argument calling for superclass capability
                varargin = {''}; 
            else
                if ~ischar(varargin{1})
                    error('ocFile:constructor:noChar',...
                        'The filepath must be passed as char vector.');
                end
            end
            oThis.sFile = varargin{1};
        end
        
        % =================================================================
        
        function cLine = lines(oThis)
            %lines getter method for lines as cell array of strings
            %
            % Outputs:
            %      cLine - cell (nx1) with char arrays of each lines
            %              content
            %
            % Tests:
            %   cLine = ocFile(which('ocFile')).read.lines
            cLine = oThis.cLine;
        end
        
        % =================================================================
        
        function sFile = file(oThis)
            %file getter method for filepath as string
            %
            % Outputs:
            %      sFile - char (1xn) with filepath
            %
            % Tests:
            %   assert(ocFile(which('ocFile')).file,which('ocFile')),'file output failed')
            sFile = oThis.sFile;
        end
        
        % =================================================================
        
        function oThis = setFile(oThis,sFile)
            %setFile set method for filepath as string (e.g. in case of subclass object creation
            %does not initialize file yet).
            %
            % Outputs:
            %      oThis - object (1x1) of class ocFile with updated sFile property
            %
            % Tests:
            %   oFile = ocFile().setFile(which('ocFile')); assert(strcmp(oFile.file,which('ocFile')),'sFile set failed')
            oThis.sFile = sFile;
            oThis.checkExistence;
        end
        
        % =================================================================
        
        function oThis = strtrim(oThis)
            %strtrim aplpies strtrim on internal cell array of lines
            oThis.cLine = strtrim(oThis.cLine);
        end
        
        % =================================================================
        
        function oThis = makeWritable(oThis)
            %makeWritable ensure file is writable on file system
            attrib('-R',oThis.sFile);
        end
        
        % =================================================================
        
        function oThis = read(oThis)
            % READ read file into lines while preserving whitespaces
            %
            % Tests:
            %   cLine = ocFile(which('ocFile')).read.lines
            oThis.checkExistence;
            oThis = oThis.readFile;
        end
        
        % =================================================================
        
        function oThis = scan(oThis,varargin)
            % SCAN read file into lines with options for fopen and textscan,
            % applies an implicit strtrim command.
            %
            % Tests:
            %   cLine = ocFile(which('ocFile')).scan.lines
            oThis.checkExistence;
            oThis = oThis.scanFile(varargin{:});
        end
        
        % =================================================================
        
        function oThis = write(oThis,varargin)
            % write writes file with lines specified as cell array of strings
            %
            % Syntax:
            %   oThis = writeFile(oThis,cLine,varargin)
            %
            % Inputs:
            %      oThis - object (1x1) of class
            %      cLine - cell (mx1) of string with options lines to write
            %   varargin - cell (1xn) of strings with options to fopen
            %              except for open type (constant: 'w')
            %
            % Tests:
            %   oFile = ocFile('newfile.m').write('Just a char array')
            %   oFile = ocFile('newfile.m').write({'multiple lines','are written','here'})
            
            % check input
            if nargin < 2 && isempty(oThis.cLine)
                error('ocFile:writeFirstArgNoCell',...
                    'Please pass text to write as a cell or char array.');
            elseif nargin > 1 % set cLine directly
                if ischar(varargin{1})
                    varargin{1} = varargin(1); % convert char to cell of char
                end
                if ~iscell(varargin{1})
                    error('ocFile:writeFirstArgNoCell',...
                        'The first argument of the write method needs to be a cell array or char array.');
                end
                oThis.cLine = varargin{1};
            end
            oThis.writeFile(varargin{2:end});
        end
    end % methods (Access = public)

end