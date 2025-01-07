function vValue = structValueDefault(xData,sValue,vDefault)
% STRUCTVALUEDEFAULT return a specifed value from a structure or the
% default value.
%
% Syntax:
%   vValue = structValueDefault(xData,sValue,vDefault)
%
% Inputs:
%      xData - structure 
%     sValue - string a structure value defintion
%   vDefault - default value
%
% Outputs:
%   vValue - value 
%
% Example: 
%   vValue = structValueDefault(xData,sValue,vDefault)
%
% Subfunctions: structValueExist
%
% See also: strGlue, strsplitOwn
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-04-14

% check for existence of structure part
[bExist,vValue] = structValueExist(xData,sValue);

% give default value as backup
if ~bExist
    vValue = vDefault;
end
return

% =========================================================================

function [bExist,vValue] = structValueExist(xData,sValue)
% STRUCTVALUEEXIST check existence of a structure value and return the
% value.
%
% Syntax:
%   [bExist,vValue] = structValueExist(xData,sValue)
%
% Inputs:
%    xData - structure
%   sValue - string with structure value definition
%
% Outputs:
%   bExist - boolean if structure value definition exists
%   vValue - value of specified structure definition
%
% Example:
% xData.cellbla{1,2}.vecblub(3,1) = 2;
%   [bExist,vValue] = structValueExist(xData,'xData.cellbla{1,2}.vecblub(3,1)')

% init output
bExist = false;
vValue = [];

% check input
if nargin < 2 || isempty(sValue)
    return
end

% determine index string parts
cSplit = strsplitOwn(sValue,'.');
sIndexBase = regexp(cSplit{1},'(?<=\w+)\W.*','match','once');

if numel(cSplit) == 1
    % determine value
    if isempty(sIndexBase)
        bExist = true;
        vValue = xData;
    else
        % prevent out of bound
        if strcmp(sIndexBase(2:end-1),'end')
            bExist = true;
            vValue = eval(['xData' sIndexBase]);
        elseif all(str2num(sIndexBase(2:end-1)) <= size(xData)) %#ok<ST2NM>
            bExist = true;
            vValue = eval(['xData' sIndexBase]);
        else
            return
        end
    end
else
    % determine pure fieldname of next level
    sFieldNext = regexp(cSplit{2},'^\w+','match','once');
    
    % get indexed part of this level
    if ~isempty(sIndexBase) && ~isempty(xData)
        % prevent out of bound
        if strcmp(sIndexBase(2:end-1),'end')
            xData = eval(['xData' sIndexBase]);
        else
            nIndexBase = str2num(sIndexBase(2:end-1)); %#ok<ST2NM>
            if numel(nIndexBase < 2) && nIndexBase < numel(xData)
                xData = eval(['xData' sIndexBase]);
            elseif all(nIndexBase <= size(xData)) 
                xData = eval(['xData' sIndexBase]);
            else
                return
            end
        end
    end
    
    % determine next structure level
    if isfield(xData,sFieldNext)
        [bExist,vValue] = structValueExist(xData.(sFieldNext),strGlue(cSplit(2:end),'.'));
    else
        return
    end
end
return



