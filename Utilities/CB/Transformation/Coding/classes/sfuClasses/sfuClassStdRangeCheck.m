classdef sfuClassStdRangeCheck < cbtClassSilverSfu
    
	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassStdRangeCheck.empty;
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default file name of post script list
        sStdRangeCheckFile = 'signalRangeCheck.py';
        
        % default start time of range check in simulation
        sStdCheckStartTime = '1.0';
        
        % default suffix for signal flag
        sStdFlagVariableSuffix = '__rangeFlag';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassStdRangeCheck(oCONST,oMP,xSetupList)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'SFU_RangeCheck');
            obj.oThisSfuParam = parClassStdRangeCheck(oCONST);
            obj.assignSfuParameter(obj.CONST.nCreateOrderRangeCheck,...
                obj.oThisSfuParam);
            
            % -------------------------------------------------------------
            
            % assign default check start time
            obj.oSfuParam.CheckStartTime = obj.sStdCheckStartTime;
            
            % create signal range check Python script
            obj.createSignalRangeCheckScript(xSetupList);
            
        end % sfuClassStdRangeCheck
        
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
        
        function createSignalRangeCheckScript(obj,xSetupList)
            
            % get unique signal structure list
            xSignalList = obj.getSignalListFromSetups(xSetupList);
            
            % create text strings
            [sInitTxt,sFlagTxt,sRangeTxt] = obj.getTextPartsForScript(xSignalList);
            
            % init script parts
            sPart = {};
            
            % create Silver Python script text
            sPart{end+1} = sprintf('from synopsys.silver import *\n');
            sPart{end+1} = sprintf('import sys\n');
            sPart{end+1} = sprintf('import math\n\n');
            sPart{end+1} = sprintf('START_TIME = float(sys.argv[1])\n\n');
            sPart{end+1} = sprintf('%s\n',sInitTxt);
            sPart{end+1} = sprintf('def MainGenerator(*args):\n\n');
            sPart{end+1} = sprintf('%s\n',sFlagTxt);
            sPart{end+1} = sprintf('\twhile t.Value < START_TIME:\n');
            sPart{end+1} = sprintf('\t\tyield\n\n');
            sPart{end+1} = sprintf('\twhile True:\n\n');
            sPart{end+1} = sprintf('%s\n',sRangeTxt);
            sPart{end+1} = sprintf('\t\tyield\n');
            
            % concatenate text string
            sScriptTxt = strjoin(sPart,'');
            
            % set name of script
            obj.oSfuParam.RangeCheckFile = obj.sStdRangeCheckFile;
            
            % create filepath of parameter file
            sRangeCheckFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.RangeCheckFile);
            
            % write port alias file
            fleFileWrite(sRangeCheckFilepath,sScriptTxt);
            
        end
        
        % =================================================================
        
        function [sInitTxt,sFlagTxt,sRangeTxt] = getTextPartsForScript(obj,xSignalList)
            
            % init text
            sInitTxt = sprintf('t = Variable(%stime%s)\n',qtm,qtm);
            sFlagTxt = '';
            sRangeTxt = '';
            
            % run throuh signale
            for nSig=1:numel(xSignalList)
                
                % current signal
                xSignal = xSignalList(nSig);
                
                % get signal parameters
                sSigName = xSignal.name;
                sSnaValue = xSignal.sna;
                sMaxValue = xSignal.maxPhysicalRange;
                sMinValue = xSignal.minPhysicalRange;
                sFlagName = sprintf('%s%s',sSigName,obj.sStdFlagVariableSuffix);
                
                % create line for signal init text
                sIniLine = sprintf('%s = Variable(%s%s%s)\n',...
                    sSigName,qtm,sSigName,qtm);
                
                % create line for flag init text
                sFlagLine = sprintf('\t%s = False\n',sFlagName);
                
                % get value check lines
                s1 = obj.getLineForNan(sSigName,sFlagName);
                s2 = obj.getLineForInf(sSigName,sFlagName);
                s3 = obj.getLineForSna(sSigName,sFlagName,sSnaValue);
                s4 = obj.getLineForMax(sSigName,sFlagName,sMaxValue);
                s5 = obj.getLineForMin(sSigName,sFlagName,sMinValue);
                sRangeLine = [s1,s2,s3,s4,s5];
                
                % create lines if any check exsits for signal
                if ~isempty(sRangeLine)
                    s1 = sprintf('\t\tif not(%s):\n',sFlagName);
                    sRangeLine = [s1,sRangeLine]; %#ok<AGROW>
                end
                
                % append lines in text
                sInitTxt = sprintf('%s%s',sInitTxt,sIniLine);
                sFlagTxt = sprintf('%s%s',sFlagTxt,sFlagLine);
                sRangeTxt = sprintf('%s%s',sRangeTxt,sRangeLine);
                
            end % signals
            
        end % getTextPartsForScript
  
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function xSignalList = getSignalListFromSetups(xSetupList)
            
            % init port structure list
            xPortList = struct([]);
            
            % run through setups
            for nSet=1:numel(xSetupList)
                
                % append inports and outports to signal list
                xPortList = [xPortList,xSetupList(nSet).Inport,...
                    xSetupList(nSet).Outport]; %#ok<AGROW>
                
            end % setups
            
            % unique port list to signal list
            [~,nIdxList] = unique({xPortList.name});
            xSignalList = xPortList(nIdxList);
            
        end % getSignalListFromSetups
        
        % =================================================================
        
        function sLine = getLineForNan(sSigName,sFlagName)
            
            % create lines
            s1 = sprintf('\t\t\tif math.isnan(%s.Value):\n',sSigName);
            s2 = sprintf('\t\t\t\t%s = True\n',sFlagName);
            s3 = sprintf('\t\t\t\tmessage = %sSignal "%s" is NaN at %s + str(t.Value) + %s s%s\n',...
                qtm,sSigName,qtm,qtm,qtm);
            s4 = sprintf('\t\t\t\tlogThis(ERROR_ERROR, message)\n');
            sLine = [s1,s2,s3,s4];
            
        end % getLineForNan
        
        % =================================================================
        
        function sLine = getLineForInf(sSigName,sFlagName)
            
            % create lines
            s1 = sprintf('\t\t\tif math.isinf(%s.Value):\n',sSigName);
            s2 = sprintf('\t\t\t\t%s = True\n',sFlagName);
            s3 = sprintf('\t\t\t\tmessage = %sSignal "%s" is Inf at %s + str(t.Value) + %s s%s\n',...
                qtm,sSigName,qtm,qtm,qtm);
            s4 = sprintf('\t\t\t\tlogThis(ERROR_ERROR, message)\n');
            sLine = [s1,s2,s3,s4];
            
        end % getLineForInf
        
        % =================================================================
        
        function sLine = getLineForSna(sSigName,sFlagName,sSnaValue)
            
            % check value
            if chkNanInfOfString(sSnaValue)
                sLine = '';
                return;
            end
            
            % create lines
            s1 = sprintf('\t\t\tif %s.Value == %s:\n',sSigName,sSnaValue);
            s2 = sprintf('\t\t\t\t%s = True\n',sFlagName);
            s3 = sprintf('\t\t\t\tmessage = %sSignal "%s" is sna at %s + str(t.Value) + %s s%s\n',...
                qtm,sSigName,qtm,qtm,qtm);
            s4 = sprintf('\t\t\t\tlogThis(ERROR_WARNING, message)\n');
            sLine = [s1,s2,s3,s4];
            
        end % getLineForSna
        
        % =================================================================
        
        function sLine = getLineForMax(sSigName,sFlagName,sMaxValue)
            
            % check value
            if chkNanInfOfString(sMaxValue)
                sLine = '';
                return;
            end
            
            % create lines
            s1 = sprintf('\t\t\tif %s.Value > %s:\n',sSigName,sMaxValue);
            s2 = sprintf('\t\t\t\t%s = True\n',sFlagName);
            s3 = sprintf('\t\t\t\tmessage = %sSignal "%s" is greater than defined maximum %s at %s + str(t.Value) + %s s%s\n',...
                qtm,sSigName,sMaxValue,qtm,qtm,qtm);
            s4 = sprintf('\t\t\t\tlogThis(ERROR_ERROR, message)\n');
            sLine = [s1,s2,s3,s4];
            
        end % getLineForMax
        
        % =================================================================
        
        function sLine = getLineForMin(sSigName,sFlagName,sMinValue)
            
            % check value
            if chkNanInfOfString(sMinValue)
                sLine = '';
                return;
            end
            
            % create lines
            s1 = sprintf('\t\t\tif %s.Value < %s:\n',sSigName,sMinValue);
            s2 = sprintf('\t\t\t\t%s = True\n',sFlagName);
            s3 = sprintf('\t\t\t\tmessage = %sSignal "%s" is less than defined minimum %s at %s + str(t.Value) + %s s%s\n',...
                qtm,sSigName,sMinValue,qtm,qtm,qtm);
            s4 = sprintf('\t\t\t\tlogThis(ERROR_ERROR, message)\n');
            sLine = [s1,s2,s3,s4];
            
        end % getLineForMin
        
        % =================================================================
        
        function bValid = checkForInfOrNan(sValue)
            
            % convert string to double
            vValue = str2double(sValue);
            
            % check for nan or inf
            if isnan(vValue) || isinf(vValue)
                bValid = true;
            else
                bValid = false;
            end
            
        end % checkForInfOrNan
      
    end % static private methods
    
end