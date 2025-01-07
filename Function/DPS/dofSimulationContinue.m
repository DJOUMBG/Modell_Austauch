function bContinue = dofSimulationContinue(xSim,varargin)
% DOFSIMULATIONCONTINUE check the simulation continuation state or if the simulation should be
% cancelled.
%
% Syntax:
%   dofSimulationContinue(xSim,varargin)
%
% Inputs:
%       xSim - structure with fields of DIVeONE Companion ini-file of a simulation and further
%              fields added by dsim to xSim structure
%         .diveOneSimulationId - integer with ID of simulation within DIVeONE
%         .diveOneToken - char (1xn) with token for simulation update
%         .diveOneSimulationEndpoint - char (1xn) with DIVeONE server endpoint triggering the simulation
%
% Outputs:
%
% Example: 
%   dofSimulationContinue(xSim,'nState',2,'sNote','someUpdate')
% 
%  %#1 report stopped agent job to DIVeONE Simulation Overview
%   xSim.diveOneSimulationId = '1234';
%   xSim.diveOneToken = 'yourToken';
%   xSim.diveOneSimulationEndpoint = 'https://dive.app.tbintra.net/api/simulation';
%   dofSimulationContinue(xSim)

% check input
if ~isfield(xSim,'diveOneToken') || isempty(xSim.diveOneToken)
    fprintf(1,'dsim:dofSimulationContinue - omit DIVeONE update, no token available\n')
    return
end
              
xMsg = createMessage(xSim);
sEndpoint = fullfileSL(xSim.diveOneSimulationEndpoint,'GetPartial'); % adapt simulation endpoint
bContinue = sendMessage(xMsg,sEndpoint);
return

% ==================================================================================================

function xMsg = createMessage(xSim)
% CREATEMESSAGE create the base message structure for DIVeONE POST html request. Fields defined in
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
%   xArg - structure with fields of output parsing
%
% Outputs:
%   xMsg - structure with fields of message parts 
%
% Example: 
%   xMsg = createMessage(xSim,xArg)

xMsg = struct('id',{str2double(xSim.diveOneSimulationId)},...
              'token',xSim.diveOneToken);
return

% ==================================================================================================

function bContinue = sendMessage(xMsg,sUrl)
if verLessThanMATLAB('9.7')
    bContinue = sendPostMessageCurl(xMsg,sUrl);
else
    bContinue = sendPostMessageMatlab(xMsg,sUrl);
end
return

% ==================================================================================================

function bContinue = sendPostMessageCurl(xMsg,sUrl)
% SENDPOSTMESSAGECURL send html POST request with curl (should be available on all newer
% Windows 10 versions).
% 
% CAUTION - a solution via urlread2 from Matlab File Exchange has protocol version issues via the
% internally used sun Java package. Better use curl as already integrated with newer Windows 10
% versions
%
% Syntax:
%   sendPostMessageCurl(xMsg,sUrl)
%
% Inputs:
%   xMsg - structure with fields of JSON data fields
%   sUrl - string with target URL
%
% Outputs:
%  bContinue - boolean (1x1) if simulation should be continued
% 
% Example: 
%   sendPostMessageCurl(xMsg,sUrl)

% init output (continue simulation in case of error or connectivity issue)
bContinue = true;

sData = strrep(struct2json(xMsg),'"','""'); % special " escape
sCommand = sprintf('curl -H "Content-Type: application/json"  -X POST  -d "%s"  %s',sData,sUrl);
[nStatus,sMsg] = system(sCommand);
if nStatus
    fprintf(2,['[%s] dofSimulationContinue:sendPostMessageBeforeR2017a:curlFailure - curl system ' ...
              'command "%s" \nfailed with message: \n%s\n'],char(datetime('now')),sCommand,sMsg);
    return
end
% decompose message
cLine = strtrim(strsplitOwn(sMsg,char(10)));  %#ok<CHARTEN>
sCancel = regexp(cLine{end},'(?<="isCancellationRequested":)\w+','match','once');
if ~isempty(sCancel) && strcmpi(sCancel,'true')
    bContinue = false;
end
return

% ==================================================================================================

function bContinue = sendPostMessageMatlab(xMsg,sUrl)
% SENDPOSTMESSAGEMATLAB send html POST request with Matlab internal toolboxes (POST request
% implemented since R2017a according Matlab Support, however certificate issues at least with
% R2017b).
%
% Syntax:
%   bContinue = sendPostMessageMatlab(xMsg,sUrl)
%
% Inputs:
%   xMsg - structure with fields of JSON request body
%   sUrl - string with server URL
%
% Outputs:
%  bContinue - boolean (1x1) if simulation should be continued
% 
% Example: 
%   bContinue = sendPostMessageMatlab(xMsg,sUrl)

% create basic request
oRequest = matlab.net.http.RequestMessage;
oRequest.Header = matlab.net.http.field.ContentTypeField('application/json');
oRequest.Method = 'POST';

% add body
oBody = matlab.net.http.MessageBody();
oBody.Payload = jsonencode(xMsg);
oRequest.Body = oBody;

% send request
uri = matlab.net.URI(sUrl);
oAnswer = oRequest.send(uri);

% verify success
bContinue = true; % init feedback - continue simulation in case of error or connection loss
if strcmpi(oAnswer.StatusCode,'OK') 
    if isfield(oAnswer.Body.Data,'isCancellationRequested')
        bContinue = ~oAnswer.Body.Data.isCancellationRequested;
    else
        if isempty(oAnswer.Body.Data)
            sError = 'request failed with empty Body, detail analysis needed.';
        elseif isa(oAnswer.Body.Data,'string') || isa(oAnswer.Body.Data,'char')
            sError = sprintf('request failed with Body.Data: %s',...
                oAnswer.Body.Data);
        else
            sError = sprintf('request failed with Body.Data.message (%s : %s): %s',...
                oAnswer.Body.Data.serviceName,oAnswer.Body.Data.serverTime,oAnswer.Body.Data.message);
        end
        fprintf(2,'[%s] dofSimulationContinue:sendPostMessageFromR2017a:httpRequestFailure - %s\n',char(datetime('now')),sError);
    end
end
return
