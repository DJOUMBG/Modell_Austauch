function [hChild] = allchilds(hHandle)
% ALLCHILDS return all children and subsequent children of ui-object with
% specified handle in a single vector.
%
% Syntax:
%   hChild = allchilds(xHandle)
%
% Inputs:
%   hHandle - handle (mx1) to get ui-element children from
%
% Outputs:
%   hChild - handle (mx1) of all children
%
% Example: 
%   hChild = allchilds(gco)
%   set(hChild,'Visible','off')

% initialize handle according MATLAB GUI engine
if verLessThanMATLAB('8.4.0')
    hChild = [];
else
    hChild = gobjects(0);
end

% get Children of handle(s) with exclusion of uiclassictab handles (they
% will be switched through the retouch function, so it would double
% handling
nHandle = length(hHandle);
if nHandle == 1 % single handle input
    if isappdata(hHandle,'uiclassictab') ~= 1
        hChild = get(hHandle,'Children'); % output: vector if single handle, cell if handle vector
    end
else % handle vector input
    bUiclassictab = zeros(1,nHandle); % init flag vector 
    for nIdxHandle = 1:nHandle
        bUiclassictab(1,nIdxHandle) = isappdata(hHandle(nIdxHandle),'uiclassictab'); % identify uiclassictab handles
    end
    xHandlesAdd = get(hHandle(~bUiclassictab),'Children'); % output: vector if single handle, cell if handle vector
    
    % re-arrange cell to vector
    for nIdxHandle = 1:length(xHandlesAdd)
        if ~isempty(xHandlesAdd{nIdxHandle})
            if isempty(hChild)
                hChild = xHandlesAdd{nIdxHandle};
            else
                hChild = [hChild;xHandlesAdd{nIdxHandle}]; %#ok<AGROW>
            end
        end
    end
end
    
% check for further children of handles
if ~isempty(hChild)
    hChildAdd = allchilds(hChild);
    hChild = [hChild ; hChildAdd];
end
return