classdef sfuClassStdSupport < cbtClassSilverSfu
      
	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassStdSupport.empty;
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default file name of io signal list
        sStdIoSignalListFileName = 'initIO.txt';
        
        % default file name of modify signal list
        sStdModListFileName = 'rbu.txt';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassStdSupport(oCONST,oMP,xConfig,xSetupList,oDiveOneCom,sSimEndTime)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'SFU_Support');
            obj.oThisSfuParam = parClassStdSupport(oCONST);
            obj.assignSfuParameter(obj.CONST.nCreateOrderSupport,...
                obj.oThisSfuParam);
            
            % -------------------------------------------------------------
            
            % assign matlab path
            obj.oSfuParam.Matlab64Exe = silGetConfigParamResolve(...
                obj.CONST.sStdConfigParamMatlabPath);
            
            % create rbu file
            obj.createRbuFile(xConfig);
            
            % create initIo file
            obj.createInitIoFile(xSetupList);
            
            % create DIVe ONE com data file
            obj.createDiveOneComFile(oDiveOneCom,sSimEndTime);
            
        end % sfuClassStdSupport
        
        % =================================================================

        function thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function createRbuFile(obj,xConfig)
            
            % get interface part from config xml
            checkFieldname(xConfig,'Interface');
            xInterface = xConfig.('Interface');

            % get signals part from interface
            checkFieldname(xInterface,'Signal');
            xSignalList = xInterface.('Signal');

            % check fieldnames
            checkFieldname(xSignalList,'source');
            checkFieldname(xSignalList,'destination');
            
            % -------------------------------------------------------------
            
            % create header
            sTxt = sprintf('modify_outputs:\n\n');
            
            % append lines with signals
            sTxt = sprintf('%s%s',sTxt,obj.getSignalModLines(xSignalList));
            
            % create full file path to rbu file
            sModListFilepath = fullfile(obj.CONST.sRbuFolder,...
                obj.sStdModListFileName);
            
            % create relative path of rbu file and assign to sfu param
            obj.oSfuParam.ModSignalListFile = ...
                fleRelativePathGet(obj.CONST.sMasterFolder,sModListFilepath);
            
            % write file
            fleFileWrite(sModListFilepath,sTxt,'w');
            
        end % createRbuFile
        
        % =================================================================
        
        function createInitIoFile(obj,xSetupList)
            
            % create header
            sTxt = sprintf('init:\n\n');
            
            % append text with init io signals of all inports and outports
            %  of all modules in setup
            sTxt = sprintf('%s%s',sTxt,obj.getSignalIoLines(xSetupList,...
                obj.CONST.nValuePrecision));
            
            % create name of initIo file
            obj.oSfuParam.IoSignalListFile = obj.sStdIoSignalListFileName;
            
            % create file path of initIo file
            sIoSignalListFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.IoSignalListFile);
            
            % write file
            fleFileWrite(sIoSignalListFilepath,sTxt,'w');
            
        end % createInitIoFile
        
        % =================================================================
        
        function createDiveOneComFile(obj,oDiveOneCom,sSimEndTime)
            
            % write file if is started from DIVe ONE
            if oDiveOneCom.bIsDiveOne
                
                % write file lines
                sTxt = sprintf('%s\n%s\n%s\n%s\n%s',...
                    oDiveOneCom.sDiveOneComIdent,...
                    oDiveOneCom.sDiveOneComLocations,...
                    oDiveOneCom.sPutUrl,oDiveOneCom.sPostUrl,sSimEndTime);
                
                % write file
                fleFileWrite(obj.CONST.sDiveOneComDataFile,sTxt,'w');
                
            end
            
        end % createDiveOneComFile
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function sTxt = getSignalModLines(xSignalList)
           
            % init text
            sTxt = '';
            
            % run through all signals in list
            for nSig=1:numel(xSignalList)
    
                % current signal
                xSignal = xSignalList(nSig);

                % get source and destination list structures
                xSource = xSignal.('source');
                xDestList = xSignal.('destination');

                % check fields
                checkFieldname(xSource,'name');
                checkFieldname(xDestList,'name');

                % get source name
                sSourceName = xSource(1).('name');

                % assign source name to every different destination name
                for nDest=1:numel(xDestList)

                    % current destination
                    xDest = xDestList(nDest);

                    % get destination name
                    sDestName = xDest.('name');

                    % write line if different names
                    if ~strcmp(sDestName,sSourceName)

                        % write assignment
                        sTxt = sprintf('%s%s = %s;\n',sTxt,sDestName,sSourceName);

                        % message to user if more than one destination
%                         if nDest > 1
%                             fprintf(1,'\tAdded to rbu due to CEEAce signaling: %s\n',...
%                                 sDestName);
%                         end

                    end

                end % destinatnion list

            end % signal list
            
        end % getSignalModLines
        
        % =================================================================
        
        function sTxt = getSignalIoLines(xSetupList,nPrecision)
            
            % init text
            sTxt = '';
            
            % run through setups
            for nSet=1:numel(xSetupList)
                
                % current setup
                xSetup = xSetupList(nSet);
                
                % get inports and outports
                xPortList = [xSetup.Inport,xSetup.Outport];
                
                % run through port list
                for nPort=1:numel(xPortList)
                    
                    % current port
                    xPort = xPortList(nPort);
                    sName = xPort.name;
                    value = xPort.value;
                    
                    % check value of port
                    if isempty(value)
                        fprintf(2,'\tEmpty value of port "%s" in species "%s".\n',...
                            sName,xSetup.species);
                    elseif (~isnumeric(value) && ~islogical(value)) || numel(value) ~= 1
                        fprintf(2,'\tIncorrect value format of port "%s" in species "%s".\n',...
                            sName,xSetup.species);
                    else
                        sTxt = sprintf('%s%s = %s;\n',sTxt,xPort.name,...
                            num2str(value,nPrecision));
                    end
                    
                end % ports
                
            end % setups
            
        end % getSignalIoLines
        
    end % private methods
    
end