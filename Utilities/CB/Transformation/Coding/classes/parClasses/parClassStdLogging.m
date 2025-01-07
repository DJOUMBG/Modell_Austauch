classdef parClassStdLogging < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        ConfigurationName = 'ConfigurationName';
        LogSignalListFile = 'LogSignalListFile';
        LogParamListFile = 'LogParamListFile';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuNameMdf = 'template_SFU_stdLoggingMdf';
        sThisSfuNameMat = 'template_SFU_stdLoggingMat';
        sThisSfuNameCsv = 'template_SFU_stdLoggingCsv';
        
        % -----------------------------------------------------------------
        % DEFINE PYTHON SUPPORT SCRIPTS:
        %   => !!! Must be present in folder obj.CONST.sSilverSupportFromMaster
        
        % read parameter list script
        sReadParamListScript = 'DIVeReadParamList.py';
        
        % rename log file script
        sRenameLogFileScript = 'DIVeRenameLog.py';
        
        % -----------------------------------------------------------------
        
        % standard name of writers log file
        sStdWriterLogName = 'signalLog';
        
        % standard file extension of mdf writer
        sStdMdfWriterFileExt = '.mf4';
        
        % standard file extension of mat writer
        sStdMatWriterFileExt = '.mat';
        
        % standard file extension of csv writer
        sStdCsvWriterFileExt = '.csv';
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassStdLogging(oCONST,sLogType)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            
            if strcmpi(sLogType,'mdf')
                sLogType = 'mdf';
                obj.setSfuName(obj.sThisSfuNameMdf);
            elseif strcmpi(sLogType,'mat')
                sLogType = 'mat';
                obj.setSfuName(obj.sThisSfuNameMat);
            elseif strcmpi(sLogType,'csv')
                sLogType = 'csv';
                obj.setSfuName(obj.sThisSfuNameCsv);
            else
                error('Unknown writer type "%s".',sLogType);
            end
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            % !!! WRITER MUST BE FIRST MODULE TO SET MULTIPLIER IN
            % "sfuClassStdLogging"
            
            % create sil line depended on log type
            switch sLogType
                case 'mdf'
                    sNewLogFilepath = fullfile(obj.CONST.sResultFromMaster,...
                        [obj.sStdWriterLogName,obj.sStdMdfWriterFileExt]);
                    sWriterLine = sprintf('mdfwriter.dll -l ${%s} %s',...
                        obj.LogSignalListFile,...
                        sNewLogFilepath);
                case 'mat'
                    sNewLogFilepath = fullfile(obj.CONST.sResultFromMaster,...
                        [obj.sStdWriterLogName,obj.sStdMatWriterFileExt]);
                    sWriterLine = sprintf('matwriter.dll -a ${%s} -f %s',...
                        obj.LogSignalListFile,...
                        sNewLogFilepath);
                case 'csv'
                    sNewLogFilepath = fullfile(obj.CONST.sResultFromMaster,...
                        [obj.sStdWriterLogName,obj.sStdCsvWriterFileExt]);
                    sWriterLine = sprintf('csvwriter.dll -l ${%s} -m t %s',...
                        obj.LogSignalListFile,...
                        sNewLogFilepath);
            end
            
            % Python script 1 sil line
            sPyScript1Line = sprintf('Python.dll %s -a %s${%s}%s -V 3',...
                fullfile(obj.CONST.sSilverSupportFromMaster,obj.sReadParamListScript),...
                obj.CONST.sQuotReplaceString,...
                obj.LogParamListFile,...
                obj.CONST.sQuotReplaceString);
            
            % Python script 2 sil line
            sPyScript2Line = sprintf('Python.dll %s -a %s%s ${%s} ${%s}%s -V 3',...
                fullfile(obj.CONST.sSilverSupportFromMaster,obj.sRenameLogFileScript),...
                obj.CONST.sQuotReplaceString,...
                sNewLogFilepath,...
                obj.ConfigurationName,...
                obj.LogSignalListFile,...
                obj.CONST.sQuotReplaceString);
            
            % collect all module sil lines
            cSilLines = {sWriterLine;sPyScript1Line;sPyScript2Line};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassStdLogging
        
        % =================================================================
        
        function [sWriterSilLineVar,sPyScript1SilLineVar,sPyScript2SilLineVar] = getSilLineReplaceStrings(obj)
            
            sWriterSilLineVar = obj.sWriterSilLineVar;
            sPyScript1SilLineVar = obj.sPyScript1SilLineVar;
            sPyScript2SilLineVar = obj.sPyScript2SilLineVar;
            
        end % getSilLineReplaceStrings
        
    end % methods
    
end