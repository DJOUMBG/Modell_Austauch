function dofSimulationStateUpdate(xSim,varargin)
% DOFSIMULATIONSTATEUPDATE update one simulation entry in the DIVeONE Simulation overview page with
% state, note and simulation run/result pathes.
%
% Syntax:
%   dofSimulationStateUpdate(xSim,varargin)
%
% Inputs:
%       xSim - structure with fields of DIVeONE Companion ini-file of a simulation and further
%              fields added by dsim to xSim structure
%         .diveOneSimulationId - integer with ID of simulation within DIVeONE
%         .diveOneToken - char (1xn) with token for simulation update
%         .diveOneSimulationEndpoint - char (1xn) with DIVeONE server endpoint triggering the simulation
%         .pathRun - char (1xn) with path of simulation run directory
%         .pathResult - char (1xn) with path of simulation result directory
%         .dqsId - char (1xn) number of Jenkins job ID
%   varargin - name/value pairs of free arguments
%         nState - integer with simulation state
%         sNote - char (1xn) with note to be displayed as tooltip of state symbol
%
% Outputs:
%
% Example: 
%   dofSimulationStateUpdate(xSim,'nState',2,'sNote','someUpdate')
% 
%  %#1 report stopped agent job to DIVeONE Simulation Overview
%   xSim.diveOneSimulationId = '1234';
%   xSim.diveOneToken = 'yourToken';
%   xSim.diveOneSimulationEndpoint = 'https://dive.app.tbintra.net/api/simulation';
%   xSim.dqsId = '1234';
%   xSim.pathRun = '';
%   xSim.pathResult = '';
%   xSim.host = 'c019vcx79700798';
%   xSim.pathLog = '//sharedrive/somewhere/file.log';
%   dofSimulationStateUpdate(xSim,'nState',4,'sNote','Error - stopped due to node reboot')

% check input
if ~isfield(xSim,'diveOneToken') || isempty(xSim.diveOneToken)
    fprintf(1,'dsim:dofSimulationStateUpdate - omit DIVeONE update, no token available\n')
    return
end
xArg = parseArgs({'nState',2,[]
                  'sNote','',[]},varargin{:});

try
    xMsg = createMessage(xSim,xArg);
    if isappdata(0,'dofSimulationStateUpdateError')
        bFail = getappdata(0,'dofSimulationStateUpdateError');
        if bFail
            fprintf(1,'[%s] dofSimulationStateUpdate connection recovery (successful state update).\n',char(datetime('now')));
        end
    end
    setappdata(0,'dofSimulationStateUpdateError',false);
catch ME
    fprintf(2,'[%s] dofSimulationStateUpdate catched error with message: %s\n',char(datetime('now')),ME.message);
    setappdata(0,'dofSimulationStateUpdateError',true);
end

sendMessage(xMsg,xSim.diveOneSimulationEndpoint)
return

% ==================================================================================================

function xMsg = createMessage(xSim,xArg)
% CREATEMESSAGE create the base message structure for DIVeONE PUT html request. Fields defined in
% DIVeONE under https://git.t3.daimlertruck.com/DIVeONE/DIVeONE/wiki/Simulations
%
% Syntax:
%   xMsg = createMessage(xSim,xArg)
%
% Inputs:
%   xSim - structure with fields of DIVeONE Companion ini-file of a simulation and further
%              fields added by dsim to xSim structure
%         .diveOneSimulationId - integer with ID of simulation within DIVeONE
%         .diveOneToken - char (1xn) with token for simulation update
%         .diveOneSimulationEndpoint - char (1xn) with DIVeONE server endpoint triggering the simulation
%         .dqsId - char (1xn) number of Jenkins job ID
%         .pathRun - char (1xn) with path of simulation run directory
%         .pathResult - char (1xn) with path of simulation result directory
%   xArg - structure with fields of output parsing
%
% Outputs:
%   xMsg - structure with fields of non-empty message parts 
%
% Example: 
%   xMsg = createMessage(xSim,xArg)

cStruct = {'id',{str2double(xSim.diveOneSimulationId)},...
           'stateId',xArg.nState,...
           'stateNote',xArg.sNote,...
           'token',xSim.diveOneToken};

if isfield(xSim,'dqsId') && ~isempty(xSim.dqsId)
    cStruct = [cStruct {'dqsId',xSim.dqsId}];
end
if isfield(xSim,'pathRun') && ~isempty(xSim.pathRun)
    cStruct = [cStruct {'simulationDirectory',xSim.pathRun}];
end
if isfield(xSim,'pathResult') && ~isempty(xSim.pathResult)
    cStruct = [cStruct {'resultDirectory',xSim.pathResult}];
end
if isfield(xSim,'host') && ~isempty(xSim.host)
    cStruct = [cStruct {'machineName',upper(xSim.host)}];
end
if isfield(xSim,'pathLog') && ~isempty(xSim.pathLog)
    cStruct = [cStruct {'companionLogFilePath',xSim.pathLog}];
end

xMsg = struct(cStruct{:});
return

% ==================================================================================================

function sendMessage(xMsg,sUrl)

if verLessThanMATLAB('9.7')
    sendPutMessageCurl(xMsg,sUrl);
else
    sendPutMessageMatlab(xMsg,sUrl);
end
return

% ==================================================================================================

function sendPutMessageCurl(xMsg,sUrl)
% SENDPUTMESSAGECURL send html PUT request with curl (should be available on all newer
% Windows 10 versions).
% 
% CAUTION - a solution via urlread2 from Matlab File Exchange has protocol version issues via the
% internally used sun Java package. Better use curl as already integrated with newer Windows 10
% versions
%
% Syntax:
%   sendPutMessageCurl(xMsg,sUrl)
%
% Inputs:
%   xMsg - structure with fields of JSON data fields
%   sUrl - string with target URL
%
% Outputs:
%
% Example: 
%   sendPutMessageCurl(xMsg,sUrl)

sData = strrep(struct2json(xMsg),'"','""'); % special " escape
sCommand = sprintf('curl -H "Content-Type: application/json"  -X PUT  -d "%s"  %s',sData,sUrl);
[nStatus,sMsg] = system(sCommand);
if nStatus
    fprintf(2,['[%s] dofSimulationStateUpdate:sendPutMessageBeforeR2017a:curlFailure - curl system ' ...
              'command "%s" \nfailed non-fatal with message: \n%s\n'],char(datetime('now')),sCommand,sMsg);
end
return

% ==================================================================================================

function sendPutMessageMatlab(xMsg,sUrl)
% SENDPUTMESSAGEMATLAB send html PUT request with Matlab internal toolboxes (PUT request implemented
% since R2017a according Matlab Support, however certificate issues at least with R2017b).
%
% Syntax:
%   sendPutMessageMatlab(xMsg,sUrl)
%
% Inputs:
%   xMsg - structure with fields: 
%   sUrl - string with server URL
%
% Outputs:
%
% Example: 
%   sendPutMessageMatlab(xMsg,sUrl)

% create basic request
oRequest = matlab.net.http.RequestMessage;
oRequest.Header = matlab.net.http.field.ContentTypeField('application/json');
oRequest.Method = 'PUT';

% add body
oBody = matlab.net.http.MessageBody();
oBody.Payload = jsonencode(xMsg);
oRequest.Body = oBody;

% send request
uri = matlab.net.URI(sUrl);
oAnswer = oRequest.send(uri);

% verify success
if ~oAnswer.Completed 
    if isempty(oAnswer.Body.Data)
        sError = 'request failed with empty Body, detail analysis needed.';
    elseif isa(oAnswer.Body.Data,'string') || isa(oAnswer.Body.Data,'char')
        sError = sprintf('request failed with Body.Data: %s',...
            oAnswer.Body.Data);
    else
        sError = sprintf('request failed with Body.Data.message (%s : %s): %s',...
            oAnswer.Body.Data.serviceName,oAnswer.Body.Data.serverTime,oAnswer.Body.Data.message);
    end
    fprintf(2,['[%s] dofSimulationStateUpdate:sendPutMessageFromR2017a:httpRequestFailure (non-fatal)'...
        '- %s\n'],char(datetime('now')),sError) ;
end
return
