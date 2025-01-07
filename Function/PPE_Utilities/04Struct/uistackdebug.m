function cNameArray = uistackdebug(xHandle,hArray)
% UISTACKDEBUG convert a vector or matrix of GUI handles into a more
% readable cell array with strings derived from a respective handle
% structure.
%
% Syntax:
%   hNameArray = uistackdebug(hStruc,hArray)
%
% Inputs:
%   xHandle - multilevel structure with Matlab GUI handles
%   hArray - handle (1x1) matrix or vector with GUI handles
%
% Outputs:
%   cNameArray - cell array with names derived from structure fieldname 
%                and position  
%
% Example: 
%   hNameArray = uistackdebug(hStruc,hArray)
%
% Subfunctions: hstruc2name
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2007-06-01

% get names from handle structure
hstruclist = hstruc2name(xHandle);

cNameArray = cell(size(hArray));
for k = 1:size(hArray,1)
    for l = 1:size(hArray,2)
        for m = 1:length(hstruclist)
            if hstruclist{m,1} == hArray(k,l)
                cNameArray(k,l) = hstruclist(m,2);
            end
        end
    end
end
return

% =======================================================================

function cStruct = hstruc2name(xHandle)
% HSTRUC2NAME create a name list for handles by parsing a GUI handle
% structure 
%
% Syntax:
%   cStruct = hstruc2name(xHandle)
%
% Inputs:
%   xHandle - structure with handles
%
% Outputs:
%   cStruct - cell array with structure information
%
% Example: 
%   cStruct = hstruc2name(xHandle)
% struc2name - 

cLevel = {xHandle,'hstruct'};
cStruct = cell(0,2);
while ~isempty(cLevel)
    % get subsequent structure parts
    if isstruct(cLevel{1,1})
        cApp = fieldnames(cLevel{1,1});
        for k = 1:length(cApp)
            cLevel{end+1,1} = cLevel{1,1}.(cApp{k}); %#ok<AGROW>
            cLevel{end,2} = cApp{k};
        end
    end
    
    if isnumeric(cLevel{1,1}) 
        if min(size(cLevel{1,1})) == 1 % vector or scalar
            for k = 1:length(cLevel{1,1})
                cStruct{end+1,1} = cLevel{1,1}(k); %#ok<AGROW>
                cStruct{end,2} = [cLevel{1,2} num2str(k)];
            end
        else
            for k = 1:size(cLevel{1,1},1)
                for l = 1:size(cLevel{1,1},2)
                    cStruct{end+1,1} = cLevel{1,1}(k,l); %#ok<AGROW>
                    cStruct{end,2} = [cLevel{1,2} num2str(k) '_' num2str(l)];
                end
            end
        end
    end
    
    if iscell(cLevel{1,1}) && isnumeric(cLevel{1,1}{1,1})
%     if iscell(levellist{1,1}) && ishandle(levellist{1,1}{1,1})
        if min(size(cLevel{1,1})) == 1 % vector or scalar
            for k = 1:length(cLevel{1,1})
                cStruct{end+1,1} = cLevel{1,1}{k}; %#ok<AGROW>
                cStruct{end,2} = [cLevel{1,2} num2str(k)];
            end
        else
            for k = 1:size(cLevel{1,1},1)
                for l = 1:size(cLevel{1,1},2)
                    cStruct{end+1,1} = cLevel{1,1}{k,l}; %#ok<AGROW>
                    cStruct{end,2} = [cLevel{1,2} num2str(k) '_' num2str(l)];
                end
            end
        end
    end
    
    if size(cLevel,1)==1
        cLevel = {};
    else
        cLevel = cLevel(2:end,:);
    end
end
return