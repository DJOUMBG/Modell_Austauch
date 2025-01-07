function [xSet,cMsg,xSetProperty] = MARCstruct2set(xMs,hWaitbar,vWaitbar)
% MARCSTRUCT2SET parse MARC export MATLAB structure into a structure with
% variable names as fieldnames. Table axes become variables as well.
% 
% Annotation for MARC export:
% Datensatz laden (VORSICHT: gk Name muss ohne Punkte und Minuszeichen
% sein, da gk Name zum Variablennamen wird) upper menu bar: 
% Verstellen >> ApDataExport
% Tab: Matlab
% choose options + OK
%
% Syntax:
%   [xSet,cMsg,xProperty] = MARCstruct2set(xMs)
%   [xSet,cMsg,xProperty] = MARCstruct2set(xMs,hWaitbar,vWaitbar)
%
% Inputs:
%        xMs - structure from direct MATLAB export of MARC including the
%              substructure .CalParam
%   hWaitbar - [optional] handle of a MATLAB waitbar
%   vWaitbar - [optional] value (1x2) with offset and factor for waitbar 
%              progress calculation
%
% Outputs:
%   xSet - structure with parsed variables as fieldnames
%   cMsg - cell with failure ID, variable ID in struct, variable name
%             and failure messages 
%   xSetProperty - structure additional parameter information in fields:
%   .Param       - structure with parameter properties in fields:
%    .Name           - string with parameter name (without struct string)
%    .IDMARC         - integer with MARC parameter set ID
%    .PhysUnit       - string with physical unit (if PhysUnit was empty at
%                      the dataset, the field EquationText is used)
%    .Factor         - value with scaling factor
%    .Offset         - value with scaling offset
%    .Min            - value with minimum value
%    .Max            - value with maximum value
%    .DecimalDigits  - integer with valid digits for rounding
%    .DataType       - string with data type identifier
%    .CalStep        - value with default calibration step
%    .nLookup        - 1: scalar, 2: lookup, 3: 2D map data, 4: x axis, 5: y axis 
%    .cLookupName    - cell with string with name of map data (in case of 
%                      axis parameter) or name of axes (in case of map main
%                      data) 
%    .bStateflow     - boolean with 
%                       0: no stateflow usage (parameter can be in struct)
%                       1: stateflow usage (parameter must be also in base
%                          workspace) 
%    .xUsage         - structure (1xn) with information about usage of
%                      parameter in fields:
%     .sBlockType      - string with Simulink block type
%     .sBlockPath      - string with block path of parameter usage
%     .sBlockParameter - string with parameter name/object property
%   .Index      - structure with parameter names as fieldnames and the
%                 index number of xSetProperty as value
%
% Example: 
%   [xSet,cMsg,xProperty] = MARCstruct2set(xMs)
%   [xSet,cMsg,xProperty] = MARCstruct2set(xMs,hWaitbar,vWaitbar)
%
%
% Subfunctions: createAxisData, createVariable
%
% See also: roundbase
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-10-24

% check input
if nargin < 2 && usejava('desktop')
    hWaitbar = waitbar(0,'Converting MARC data into Simulation dataset...',...
        'Name','Convert MARC data'); % generate an own waitbar
    vWaitbar = [0 1]; % offset and factor on waitbar progress
else
    waitbar(vWaitbar(1),hWaitbar,'Converting MARC data into Simulation dataset...');
end

% initialize variables
xSet = struct;
cMsg = cell(0,4);
xParam = struct('Name',{},'IDMARC',{},'PhysUnit',{},'Factor',{},...
                  'Offset',{},'Min',{},'Max',{},'DecimalDigits',{},...
                  'DataType',{},'CalStep',{},'nLookup',{},'cLookupName',{},...
                  'bStateflow',{},'xUsage',...
                  struct('sBlockType',{},'sBlockPath',{},...
                         'sBlockParameter',{},'sFrame',{}));
xIndex = struct;
nCalParam = numel(xMs.CalParam);

for nIdxParam = 1:nCalParam
    % update waitbar
    if mod(nIdxParam,100) == 0 && usejava('desktop')
        waitbar(vWaitbar(1)+vWaitbar(2)*nIdxParam/nCalParam,hWaitbar);
    end
    
    % if struct entry contains data
    if ~isempty(xMs.CalParam(nIdxParam).Data) && ~isempty(xMs.CalParam(nIdxParam).Name)
        if regexp(xMs.CalParam(nIdxParam).Name,'.+_1m_[\d]+_') % parameter is constant vector with subdivided elements
            nIndex = regexp(xMs.CalParam(nIdxParam).Name,'_[\d]+_$','match','once');
            % convert zero base index to one base index
            nIndex = str2double(nIndex(2:end-1)) + 1;
            sName = regexp(xMs.CalParam(nIdxParam).Name,'.+(?=_[\d]+_$)','match','once');
            if isfield(xSet,sName)
                % variable is already created, set the vector value according to
                % its index.
                var = roundbase(xMs.CalParam(nIdxParam).Data,xMs.CalParam(nIdxParam).DataInfo.DecimalDigits,xMs.CalParam(nIdxParam).DataInfo.Factor);
                var = min(var,xMs.CalParam(nIdxParam).DataInfo.Max);
                var = max(var,xMs.CalParam(nIdxParam).DataInfo.Min);
                xSet.(sName)(nIndex) = var; % set variable with correct scaling
            else
                % create variable
                [xSet,cMsg,xProperty] = createVariable(xSet,sName,xMs.CalParam(nIdxParam).Data,nIdxParam,cMsg,xMs.CalParam(nIdxParam).DataInfo);
                if ~isempty(xProperty.Name)
                    xParam(end+1) = xProperty; %#ok<AGROW>
                    xIndex.(xProperty.Name) = numel(xParam);
                end
            end
        else % standard parammeter
            % create variable
            [xSet,cMsg,xProperty] = createVariable(xSet,xMs.CalParam(nIdxParam).DisplayIdentifier,xMs.CalParam(nIdxParam).Data,nIdxParam,cMsg,xMs.CalParam(nIdxParam).DataInfo);
            
            % check for axes information
            if regexp(xMs.CalParam(nIdxParam).DisplayIdentifier,'_1m') % constant
                % do nothing - backup for table identifier in variable name
            elseif regexp(xMs.CalParam(nIdxParam).DisplayIdentifier,'_2m') % table lookup
                
                % create x-axis
                [xSet,cMsg,xPropertyX] = createAxisData(xSet,xMs.CalParam(nIdxParam).DisplayIdentifier,xMs.CalParam(nIdxParam).x,xMs.CalParam(nIdxParam).xInfo,nIdxParam,cMsg);
                if ~isempty(xPropertyX)
                    xPropertyX.nLookup = 4;
                    xPropertyX.cLookupName = {xProperty.Name};
                    xProperty.nLookup = 2;
                    xProperty.cLookupName = {xPropertyX.Name};
                    xParam(end+1) = xPropertyX; %#ok<AGROW>
                    xIndex.(xPropertyX.Name) = numel(xParam);
                end
                
            elseif regexp(xMs.CalParam(nIdxParam).DisplayIdentifier,'_3m') % 2D table lookup
                
                % create x-axis
                [xSet,cMsg,xPropertyX] = createAxisData(xSet,xMs.CalParam(nIdxParam).DisplayIdentifier,xMs.CalParam(nIdxParam).x,xMs.CalParam(nIdxParam).xInfo,nIdxParam,cMsg);
                if ~isempty(xPropertyX)
                    xPropertyX.nLookup = 4;
                    xPropertyX.cLookupName = {xProperty.Name};
                    xProperty.nLookup = 3;
                    xProperty.cLookupName = {xPropertyX.Name};
                    xParam(end+1) = xPropertyX; %#ok<AGROW>
                    xIndex.(xPropertyX.Name) = numel(xParam);
                end
                
                % create y-axis
                [xSet,cMsg,xPropertyY] = createAxisData(xSet,xMs.CalParam(nIdxParam).DisplayIdentifier,xMs.CalParam(nIdxParam).y,xMs.CalParam(nIdxParam).yInfo,nIdxParam,cMsg);
                if ~isempty(xPropertyY)
                    xPropertyY.nLookup = 5;
                    xPropertyY.cLookupName = {xProperty.Name};
                    xProperty.nLookup = 3;
                    xProperty.cLookupName = [xProperty.cLookupName {xPropertyY.Name}];
                    xParam(end+1) = xPropertyY; %#ok<AGROW>
                    xIndex.(xPropertyY.Name) = numel(xParam);
                end
            end
            if ~isempty(xProperty)
                xParam(end+1) = xProperty; %#ok<AGROW>
                xIndex.(xProperty.Name) = numel(xParam);
            end
        end % if non-standard parameter
    end % if struct contains data
end % for 
xSetProperty.Param = xParam;
xSetProperty.Index = xIndex;

% close waitbar, if own was created
if nargin < 2 && usejava('desktop')
    close(hWaitbar);
end
return

% =========================================================================

function [xSet,cMsg,xProperty] = createVariable(xSet,sName,vValue,nID,cMsg,xInfo)
% CREATEVARIABLE create variable in structure within MATLAB limits.
%
% Syntax:
%   [xSet,cMsg,xProperty] = createVariable(xSet,sName,vValue,nID,cMsg,xInfo)
%
% Inputs:
%     xSet - structure with parameter names as fieldnames and resp. data
%    sName - string with name of parameter
%   vValue - double (mxn) with parameter value
%      nID - integer (1x1) ID of current variable for failure messages
%     cMsg - cell (mx4) with messages
%    xInfo - structure with fields: 
%     .DecimalDigits     - valid decimals
%     .Factor            - scaling factor
%     .Offset            - scaling offset
%     .Max               - maximum value
%     .Min               - minimum value
%
% Outputs:
%   xSet - structure with parameter names as fieldnames and resp. data
%   cMsg - cell (mx4) with messages
%   xProperty - structure with parameter info in fields:
%   .Name           - string with parameter name (without struct string)
%   .IDMARC         - integer with MARC parameter set ID
%   .PhysUnit       - string with physical unit (if PhysUnit was empty at
%                     the dataset, the field EquationText is used)
%   .Factor         - value with scaling factor
%   .Offset         - value with scaling offset
%   .Min            - value with minimum value
%   .Max            - value with maximum value
%   .DecimalDigits  - integer with valid digits for rounding
%   .DataType       - string with data type identifier
%   .CalStep        - value with default calibration step
%   .nLookup        - 0: scalar, 1: map data, 2: x axis, 3: y axis 
%   .cLookupName    - string with name of map data (in case of axis
%                     parameter) or name of axes (in case of map main data)
%   .bStateflow     - boolean with 
%                      0: no stateflow usage (parameter can be in struct)
%                      1: stateflow usage (parameter must be also in base
%                         workspace) 
%   .xUsage         - structure (1xn) with information about usage of
%                     parameter in fields:
%    .sBlockType      - string with Simulink block type
%    .sBlockPath      - string with block path of parameter usage
%    .sBlockParameter - string with parameter name/object property
%    .sFrame          - string with xCU frame of occurence
%
% Example: 
%   [xSet,cMsg,xProperty] = createVariable(xSet,sName,vValue,nID,cMsg,xInfo)

% init output
xProperty = struct('Name',{},'IDMARC',{},'PhysUnit',{},'Factor',{},...
                  'Offset',{},'Min',{},'Max',{},'DecimalDigits',{},...
                  'DataType',{},'CalStep',{},'nLookup',{},'cLookupName',{},...
                  'bStateflow',{},'xUsage',...
                  struct('sBlockType',{},'sBlockPath',{},...
                         'sBlockParameter',{},'sFrame',{}));

% catch missing data
if isempty(vValue)
    cMsg(end+1,1:4) = {5, nID, sName,['Variable ' num2str(nID) ' ' sName ' has no data.']}; 
    return
end

% catch variable structure
PointLocation = strfind(sName,'.');
if ~isempty(PointLocation)
    newname = sName(PointLocation(end)+1:end);
    if strcmp(newname(1),'_')
        cMsg(end+1,1:4) = {8, nID, sName,['Variable ' num2str(nID) ' ' sName ' is skipped, due to no valid MATLAB variable name']}; 
        return
    end
    cMsg(end+1,1:4) = {8, nID, sName,['Variable ' num2str(nID) ' ' sName ' is a structure, which will be clipped to ' newname]}; 
    sName = newname;
end

% catch parameter overlength 
if length(sName)>63    
    cMsg(end+1,1:4) = {6, nID, sName,['Variable ' num2str(nID) ' ' sName ' is skipped, due as name is longer than MATLAB variable name limit (63chars).']}; 
    return
end

% catch parameter with [] brackets
if strcmp(sName(end),']')   
    sNameNew = [strrep(sName(1:end-1),'[','_'),'_'];
    sNameNew = strrep(sNameNew,']','');
    cMsg(end+1,1:4) = {9, nID, sName,['Variable ' num2str(nID) ' ' sName ' is changed in to ' sNameNew ' due to illegal MATLAB variable name (brackets "[]").']}; 
    sName = sNameNew;
end

% catch missing information
if ~isfield(xInfo,'DecimalDigits') || isempty(xInfo.DecimalDigits)
    cMsg(end+1,1:4) = {7, nID, sName,['Variable ' num2str(nID) ' ' sName ' has no decimation info - default of 16 digits is used.']}; 
    xInfo.DecimalDigits = 16;
end
if ~isfield(xInfo,'Min') || isempty(xInfo.Min)
    xInfo.Min = -inf;
end
if ~isfield(xInfo,'Max') || isempty(xInfo.Max)
    xInfo.Max = inf;
end

% create property structure
if isempty(xInfo.PhysUnit) && isfield(xInfo,'EquationText') && ~isempty(xInfo.EquationText)
    sPhysUnit = xInfo.EquationText; % use equation text if physical unit is empty
else
    sPhysUnit = xInfo.PhysUnit;
end
xProperty = struct('Name',{sName},'IDMARC',{nID},'PhysUnit',{sPhysUnit},...
                  'Factor',{roundv(xInfo.Factor,6)},'Offset',{roundd(xInfo.Offset,8)},...
                  'Min',{xInfo.Min},'Max',{xInfo.Max},'DecimalDigits',...
                  {xInfo.DecimalDigits},'DataType',{xInfo.DataType},...
                  'CalStep',{xInfo.CalStep},'nLookup',{1},'cLookupName',{''},...
                  'bStateflow',{false},'xUsage',...
                  struct('sBlockType',{},'sBlockPath',{},...
                         'sBlockParameter',{},'sFrame',{}));

% round and limit value
vValue = roundbase(vValue,xInfo.DecimalDigits,roundv(xInfo.Factor,6)); % correct scaling
vValue = min(vValue,xInfo.Max); % max limit
vValue = max(vValue,xInfo.Min); % min limit
xSet.(sName) = vValue; % set variable 
return

% =========================================================================

function [xSet,cMsg,xProperty] = createAxisData(xSet,sName,vValue,xAxis,nID,cMsg)
% CREATEAXISDATA create variable with axis structure data for Simulink
% table lookups.
%
% Syntax:
%   [xSet,cMsg,xProperty] = createAxisData(xSet,sName,vValue,xAxis,nID,cMsg)
%
% Inputs:
%     xSet - structure with parameter names as fieldnames and resp. data
%    sName - string with name of parameter
%   vValue - double (mxn) with parameter value
%    xAxis - structure with properties of axis data
%      nID - integer (1x1) ID of current base variable for failure messages
%     cMsg - cell (mx4) with messages
%
% Outputs:
%   xSet - structure with parameter names as fieldnames and resp. data
%   cMsg - cell (mx4) with messages
%   xProperty - structure with parameter info in fields:
%   .Name           - string with parameter name (without struct string)
%   .IDMARC         - integer with MARC parameter set ID
%   .PhysUnit       - string with physical unit (if PhysUnit was empty at
%                     the dataset, the field EquationText is used)
%   .Factor         - value with scaling factor
%   .Offset         - value with scaling offset
%   .Min            - value with minimum value
%   .Max            - value with maximum value
%   .DecimalDigits  - integer with valid digits for rounding
%   .DataType       - string with data type identifier
%   .CalStep        - value with default calibration step
%   .nLookup        - 0: scalar, 1: map data, 2: x axis, 3: y axis 
%   .cLookupName    - string with name of map data (in case of axis
%                     parameter) or name of axes (in case of map main data)
%   .bStateflow     - boolean with 
%                      0: no stateflow usage (parameter can be in struct)
%                      1: stateflow usage (parameter must be also in base
%                         workspace) 
%   .xUsage         - structure (1xn) with information about usage of
%                     parameter in fields:
%    .sBlockType      - string with Simulink block type
%    .sBlockPath      - string with block path of parameter usage
%    .sBlockParameter - string with parameter name/object property
% 
% Example: 
%   [xSet,cMsg,xProperty] = createAxisData(xSet,sName,vValue,xAxis,nID,cMsg)

% init output
xProperty = struct('Name',{},'IDMARC',{},'PhysUnit',{},'Factor',{},...
                  'Offset',{},'Min',{},'Max',{},'DecimalDigits',{},...
                  'DataType',{},'CalStep',{},'nLookup',{},'cLookupName',{},...
                  'bStateflow',{},'xUsage',...
                  struct('sBlockType',{},'sBlockPath',{},...
                         'sBlockParameter',{},'sFrame',{}));

if isempty(xAxis)
    cMsg(end+1,1:4) = {1, nID, sName,['Variable ' num2str(nID) ' ' sName ' has empty info structure.']}; 
    return
end

% create axis variable
if isempty(xAxis.ShortName)
    cMsg(end+1,1:4) = {2, nID, sName,['Variable ' num2str(nID) ' ' sName ' has empty axis name.']}; 
else

    % check axis values
    if numel(vValue)<2
        cMsg(end+1,1:4) = {3, nID, sName,['Variable ' num2str(nID) ' ' sName ' has axis with one or less elements.']}; 
    end
    
    % limit data on decimation
    vValue = roundbase(vValue,xAxis.DecimalDigits,xAxis.Factor);
    
    % ensure monotonic axis
    moncheck = diff(vValue)<=0;
    if all(moncheck)
        if isempty(xAxis.Min)
            xAxis.Min = 0;
        end
        if isempty(xAxis.Max)
            xAxis.Max = xAxis.Min+1;
        end
        vValue = ...
            (xAxis.Min:(xAxis.Max-xAxis.Min)/(length(vValue)-1):xAxis.Max)';
        cMsg(end+1,1:4) = {4, nID, sName,['Variable ' num2str(nID) ' ' sName ...
            ' has a non-monotonic axis. Dummy values created for axis']}; 
    elseif any(moncheck)
        % check all element of the vector, even if it is strictly
        % monotonically increasing since it could be that the value is
        % required to be changed in order to keep the vector inside its
        % min/max value. Example: if the vector [0 1 1] and the max value is
        % 1 then the second element must be changed since the third element
        % cannot be changed to greater than 1.
        for nIdxValue = 1:length(vValue)
            vNew = vValue(nIdxValue);
            %% vMax = aStr.Max-(length(vValue)-nIdxValue)*2*10^(-1*aStr.DecimalDigits);
            %% changed by Overfeld:
            vMax = xAxis.Max-(length(vValue)-nIdxValue)*xAxis.Factor;
            if nIdxValue > 1
                % current value must be larger than the previous value
                %% vMin = var(nIdxValue-1) + 2*10^(-1*aStr.DecimalDigits);
                %% changed by Overfeld:
                vMin = vValue(nIdxValue-1) + xAxis.Factor;
            else
                % current value must be larger or equal to the minimal
                % value
                vMin = xAxis.Min;
            end
            vNew = min(vNew,vMax);
            vNew = max(vNew,vMin);
            vValue(nIdxValue) = vNew;
        end % for nIdxValue = 1:length(var)
    end % if all(moncheck)

    [xSet,cMsg,xProperty] = createVariable(xSet,xAxis.ShortName,vValue,nID,cMsg,xAxis);
end
return
