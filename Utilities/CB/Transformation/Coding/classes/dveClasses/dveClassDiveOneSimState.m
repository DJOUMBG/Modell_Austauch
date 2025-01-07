classdef dveClassDiveOneSimState < handle
    
    properties (SetAccess = private, GetAccess = public)
        
        % structure with neccessary data for Function > DPS > dofSimulationStateUpdate
        %	.diveOneSimulationEndpoint - string: 
        %       endpoint of simulation instance(e.g. DIVe ONE URL)
        %	.diveOneSimulationId  - string: 
        %       simulation ID from DIVe ONE
        %	.diveOneToken  - string: 
        %       DIVe ONE simulation token
        %	.host  - string: 
        %       computer name on which simulation is beeing executed
        %	.dqsId - string [optional] ??
        %  	.pathRun - string [optional]: 
        %       simulation main folder
        %	.pathResult - string [optional]: 
        %       result folder
        xSimInfo = struct([]);
        
        % connection state to identify if connection to DIVe ONE
        bIsDiveOne = false;
        
        % cancel request quitted
        bCancelReqQuit = false;
        
        % DIVe ONE identity json string
        sDiveOneComIdent = '';
        
        % DIVe ONE locations json string
        sDiveOneComLocations = '';
        
        % DIVe ONE curl put URL
        sPutUrl = '';
        
        % DIVe ONE curl post URL
        sPostUrl = '';
        
    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % structure with DIVe ONE infos parsed in dsv.m
        %   .Endpoint - string:
        %       endpoint of simulation instance(e.g. DIVe ONE URL)
        %   .Token - string:
        %       DIVe ONE simulation token
        %   .SimId - string
        %       simulation ID from DIVe ONE
        %   .Stream - string (not used):
        %       used Perforce stream in DIVe ONE
        %   .User - string (not used):
        %       user who started simulation
        xOneInfo = struct([]);
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default curl put command
        sStdCurlPut  =  'curl -H "Content-Type: application/json"  -X PUT  -d'
        
        % default curl post command
        sStdCurlPost =  'curl -H "Content-Type: application/json"  -X POST  -d'
        
        % default curl cancel string
        sStdCurlCancelString = '"isCancellationRequested":true';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = dveClassDiveOneSimState(xOneInfo,sSimMainFolder,sSimResultFolder)
            
            % check input
            if isstruct(xOneInfo)
                obj.xOneInfo = xOneInfo;
            end
            
            % -------------------------------------------------------------
            
            % create structure
            obj.getSimStructure(sSimMainFolder,sSimResultFolder);
            
            % get curl attributes
            obj.getCurlAttribs;
            
        end % (constructor)
        
        % =================================================================
        
        function bIsCanceled = pushUpdate2DiveOne(obj,nState,sNote)
            
            % init output
            bIsCanceled = false;
            
            % check DIVe ONE start point
            if obj.bIsDiveOne
                
                % create message data string
                sMsgData = obj.createMessageString(nState,sNote);
                
                % push message to DIVe ONE
                obj.putCurlMessage(sMsgData);
                
                % check cancelation of simulation in DIVe ONE
                bIsCanceled = obj.checkSimCancel4DiveOne;
                
                % interrupt simulation
                if bIsCanceled && not(obj.bCancelReqQuit)
                    obj.bCancelReqQuit = true;
                    error('Simulation was canceled by DIVe ONE user.');
                end
                
            end % obj.bIsDiveOne
            
        end % pushUpdate2DiveOne
        
        % =================================================================
        
        function bIsCanceled = checkSimCancel4DiveOne(obj)
            
            % init output
            bIsCanceled = false;
            
            % check DIVe ONE start point
            if obj.bIsDiveOne
            
                % check cancelation of simulation with DIVe ONE
                bIsCanceled = obj.checkSimCancel;

                % push cancel message if canceled
                if bIsCanceled

                    % create message data string
                    sMsgData = obj.createMessageString(4,...
                        'Simulation canceled by DIVe ONE user.');

                    % push message to DIVe ONE
                    obj.putCurlMessage(sMsgData);

                end % bIsCanceled
                
            end % obj.bIsDiveOne
            
        end % checkSimCancel4DiveOne
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function getSimStructure(obj,sSimMainFolder,sSimResultFolder)
            
            if isfield(obj.xOneInfo,'Endpoint')
                xThisSimInfo.diveOneSimulationEndpoint = obj.xOneInfo.('Endpoint');
            else
                xThisSimInfo.diveOneSimulationEndpoint = '';
            end
            
            if isfield(obj.xOneInfo,'SimId')
                xThisSimInfo.diveOneSimulationId = obj.xOneInfo.('SimId');
            else
                xThisSimInfo.diveOneSimulationId = '';
            end
            
            if isfield(obj.xOneInfo,'Token')
                xThisSimInfo.diveOneToken = obj.xOneInfo.('Token');
            else
                xThisSimInfo.diveOneToken = '';
            end
            
            xThisSimInfo.host = getenvOwn({'computername'});
            
            xThisSimInfo.pathRun = sSimMainFolder;
            
            xThisSimInfo.pathResult = sSimResultFolder;
            
            % assign structure
            obj.xSimInfo = xThisSimInfo;
            
            % check connection state to DIVe ONE
            if not(isempty(obj.xSimInfo.diveOneSimulationEndpoint)) && ...
                    not(isempty(obj.xSimInfo.diveOneSimulationId)) && ...
                    not(isempty(obj.xSimInfo.diveOneToken))
                obj.bIsDiveOne = true;
            end
            
        end % getSimStructure
        
        % =================================================================
        
        function getCurlAttribs(obj)
            
            % create strings if DIVe ONE
            if obj.bIsDiveOne
            
                % create DIVe ONE id string
                sDiveOneComIdent = sprintf('"id":%d,"token":"%s"',...
                    str2double(obj.xSimInfo.diveOneSimulationId),...
                    obj.xSimInfo.diveOneToken);
                obj.sDiveOneComIdent = strrep(sDiveOneComIdent,'"','""');
                
                % create setup data string
                sDiveOneComLocations = sprintf('"simulationDirectory":"%s","resultDirectory":"%s","machineName":"%s"',...
                    strrep(fullfile(obj.xSimInfo.pathRun),'\','\\'),...
                    strrep(fullfile(obj.xSimInfo.pathResult),'\','\\'),...
                    upper(obj.xSimInfo.host));
                obj.sDiveOneComLocations = strrep(sDiveOneComLocations,'"','""');

                % get DIVe ONE URL
                obj.sPutUrl = obj.xSimInfo.diveOneSimulationEndpoint;
                obj.sPostUrl = fullfileSL(obj.xSimInfo.diveOneSimulationEndpoint,...
                    'GetPartial');
                
            end % obj.bIsDiveOne
            
        end % getCurlAttribs
        
        % =================================================================
        
        function putCurlMessage(obj,sMsgData)
            
            % create curl command
            sCommand = sprintf('%s  "{%s,%s,%s}"  %s',...
                obj.sStdCurlPut,sMsgData,obj.sDiveOneComIdent,...
                obj.sDiveOneComLocations,obj.sPutUrl);
            
            % run curl command
            [nStatus,~] = system(sCommand);
            
            % check curl command
            if nStatus
                fprintf(2,'Error: Can not push message "%s" to DIVe ONE with Curl.\n',...
                    sMsgData);
            end
            
        end % putCurlMessage
        
        % =================================================================
        
        function sOutMsg = getCurlAnswer(obj)
            
            % create curl command
            sCommand = sprintf('%s  "{%s}"  %s',...
                obj.sStdCurlPost,obj.sDiveOneComIdent,obj.sPostUrl);
            
            % run curl command
            [nStatus,sOutMsg] = system(sCommand);
            
            % check curl command
            if nStatus
                fprintf(2,'Error: Can not get message from DIVe ONE with Curl.\n');
            end
            
        end % getCurlReturn
        
        % =================================================================
        
        function bIsCanceled = checkSimCancel(obj)
            
            % init output
            bIsCanceled = false;
            
            % get message from DIVe ONE
            sOutMsg = obj.getCurlAnswer;
            
            % get lines from message string
            cLines = strStringListClean(strStringToLines(sOutMsg));
            
            % get last line
            if not(isempty(cLines))
                
                if strcontain(lower(cLines{end}),lower(obj.sStdCurlCancelString))
                    bIsCanceled = true;
                end
                
            end
            
        end % checkSimCancel
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function sMsgData = createMessageString(nState,sNote)
            
            % convert to lines
            cNoteLines = strStringListClean(strStringToLines(sNote));
            
            % replace newline characters with space
            if not(isempty(cNoteLines))
                sNote = strjoin(cNoteLines,'  ');
            else
                sNote = 'No message available';
            end
            
            % create curl message json format
            sMsgData = sprintf('"stateId":%d,"stateNote":"%s"',...
                nState,sNote);
            sMsgData = strrep(sMsgData,'"','""');
            
        end % createMessageString
        
    end % private static methods
    
end % classTemplate
