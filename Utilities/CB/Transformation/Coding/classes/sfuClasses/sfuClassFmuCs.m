classdef sfuClassFmuCs < cbtClassSilverSfu

	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassFmuCs.empty;
        
    end % private properties

    % =====================================================================
    
    properties (Constant, Access = private)
        
        % expected extension of module file
        sThisModuleFileExt = '.fmu';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassFmuCs(oCONST,oMP,xSetup)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'',xSetup);
            obj.oThisSfuParam = parClassFmuCs(oCONST);
            obj.assignSfuParameter(str2double(obj.xSetup.initOrder),...
                obj.oThisSfuParam,obj.sThisModuleFileExt);
            
            % -------------------------------------------------------------
            
            % set path of fmu file
            obj.oSfuParam.FmuFile = obj.getModuleFilePath;
            
            % create parameter dym files
            obj.createDymFiles;
            
            % set renaming path
            obj.oSfuParam.OutRenameFile = obj.createOutRenameFile;
            
        end % sfuClassFmuCs
        
        % =================================================================

        function thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            % filepath of SFU sil file
            sSfuSilFilepath = fullfile(obj.CONST.sSfuFolder,...
                obj.sSfuSilFile);

            % create xml object
            oXml = xmlClassModifier(sSfuSilFilepath);
            
            % get modules
            cModules = oXml.getComplex('module');
            sModule = cModules{1};

            % add remote process line
            sRemoteCluster = '<remote-module-cluster>_</remote-module-cluster>';
            sModule = sprintf('%s  %s\n',sModule,sRemoteCluster);
            cModules{1} = sModule;

            % set modified sil line
            oXml.setComplex('module',cModules);
            
            % rewrite xml file
            oXml.writeFile(sSfuSilFilepath);
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function createDymFiles(obj)
            
            % get only structure with index
            xDataParams = obj.xSetup.getOnlyIndexStruct('Parameter');
            xIoParams = obj.xSetup.getOnlyIndexStruct('ParameterIO');
            
            % sort structure lists by content of field name
            xDataParams = sortStructByField(xDataParams,'smpVariable');
            xIoParams = sortStructByField(xIoParams,'smpVariable');
            
            % create text for Data dym file
            sDataTxt = obj.getDymFileTextFromAuthorTool(xDataParams);
            
            % create text for InitIO dym file
            sDefaultText = '# DO NOT CHANGE: Has to be synchronic with DIVeCB initialization!!!';
            sIoTxt = sprintf('%s\n%s%s',sDefaultText,...
                obj.getDymFileTextFromAuthorTool(xIoParams),...
                sDefaultText);
            
            % create file names
            obj.oSfuParam.DymFile = [obj.sSpecies,'.dym'];
            obj.oSfuParam.IoDymFile = [obj.sSpecies,'InitIO.dym'];
            
            % create filepath of dym file files
            sDymFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.DymFile);
            sIoDymFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.IoDymFile);
            
            % write dym files to run directory
            fleFileWrite(sDymFilepath,sDataTxt);
            fleFileWrite(sIoDymFilepath,sIoTxt);
            
        end % createDymFiles
        
        % =================================================================
        
        function sTxt = getDymFileTextFromAuthorTool(obj,xChannelList)
            
            % create dym file text depending on authoring tool
            if strncmpi(obj.xSetup.authoringTool,'Simulink',numel('Simulink'))
                
                sTxt = obj.getDymTextFromChannelList(xChannelList,true);
                
            elseif strncmpi(obj.xSetup.authoringTool,'SimulationX',numel('SimulationX'))
                
                sTxt = obj.getDymTextFromChannelList(xChannelList,false);
                
            elseif strncmpi(obj.xSetup.authoringTool,'Simpack',numel('Simpack'))
                
                sTxt = obj.getDymTextFromChannelList(xChannelList,false);
                
            else
                error('Unknown authoringTool "%s" for creation of fmu dym file.',...
                    sAuthorTool);
            end
            
        end % getDymFileTextFromAuthorTool
        
        % =================================================================
        
        function sTxt = getDymTextFromChannelList(obj,xChannelList,bRowVecFormat)
            
            % init text
            sTxt = '';
            
            % run through all channels
            for nChNum=1:numel(xChannelList)
                
                % get variable name and value of channel
                sVarName = xChannelList(nChNum).smpVariable;
                value = xChannelList(nChNum).value;
                
                % get channel text
                sChTxt = obj.getStandardChannelText(sVarName,value,...
                    bRowVecFormat,obj.CONST.nValuePrecision);
                
                % append text with channel text
                sTxt = sprintf('%s%s',sTxt,sChTxt);
                
            end
            
        end % getDymTextFromChannelList
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function sChTxt = getStandardChannelText(sVarName,value,bRowVecFormat,nPrecision)
            
            % init channel text
            sChTxt = '';
            
            % size of channel
            nChannelDim = size(value);
            
            % create line for scalar values
            if isa(value,'char') && size(value,1) == 1
                
                % parameter is string
                sChTxt = sprintf('%s = "%s"\n',sVarName,value);
                
            elseif (isnumeric(value) || islogical(value)) && numel(value) == 1
                
                % parameter is numeric scalar
                sChTxt = sprintf('%s = %s\n',sVarName,...
                    num2str(value,nPrecision));
                
            elseif (isnumeric(value) || islogical(value)) && numel(value) > 1
                
                % check for incorrect multi-dimensional parameter
                if length(nChannelDim) ~= 2
                    error('Unknown multi-dimensional format of parameter "%s".',...
                        sVarName);
                end
                
            end
            
            % create line for multi-dimensional values
            if isempty(sChTxt)
                
                % number of rows and column
                nRow = nChannelDim(1);
                nCol = nChannelDim(2);
                
                % check for vector or matrix
                if bRowVecFormat && nRow == 1
                    
                    % run through all vector elements
                    for nElem=1:nCol
                        
                        % write line with row vector format
                        sChTxt = sprintf('%s%s[1,%d] = %s\n',...
                            sChTxt,sVarName,nElem,...
                            num2str(value(nElem),nPrecision));
                        
                    end
                    
                elseif xor(nRow == 1, nCol == 1)
                    
                    % get numeration variable
                    if nRow > 1
                        nElemNum = nRow;
                    elseif nCol > 1
                        nElemNum = nCol;
                    else
                        nElemNum = 0;
                    end
                    
                    % run through all vector elements
                    for nElem=1:nElemNum
                        
                        % write line with element vector format
                        sChTxt = sprintf('%s%s[%d] = %s\n',...
                            sChTxt,sVarName,nElem,...
                            num2str(value(nElem),nPrecision));
                        
                    end
                    
                elseif nRow > 1 && nCol > 1
                    
                    % run through all rows
                    for nCurRow=1:nRow
                        
                        % run through all columns
                        for nCurCol=1:nCol
                            
                            % write line with matrix format
                            sChTxt = sprintf('%s%s[%d,%d] = %s\n',...
                                sChTxt,sVarName,nCurRow,nCurCol,...
                                num2str(value(nCurRow,nCurCol),nPrecision));
                        
                        end
                        
                    end
                    
                else
                    error('Unknown multi-dimensional format of parameter "%s".',...
                        sVarName);
                end
                
            end
            
        end % getStandardChannelText
        
    end % static private methods
    
end