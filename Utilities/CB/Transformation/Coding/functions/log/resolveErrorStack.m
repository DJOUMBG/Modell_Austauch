function [sErrorStack,sErrorStackLink] = resolveErrorStack(ME)
% RESOLVEERRORSTACK returns the error stack for a specific exception
% object.
%
% Syntax:
%   sErrorStack = resolveErrorStack(ME)
%
% Inputs:
%   ME - MException object, that was captured
%
% Outputs:
%   sErrorStack - string, whole error message with error stack informations
%
% Example: 
%   sErrorStack = resolveErrorStack(ME)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-03-02

%% resolve error stack

% init stack
sErrorStack = '';
sErrorStackLink = '';

% collect al stack informations
if isprop(ME,'stack')
    
    % collect stack 
    for i=1:length(ME.stack)
        
        % check for fields
        if isfield(ME.stack(i),'file') && isfield(ME.stack(i),'name') && isfield(ME.stack(i),'line')
            
            % create message
            sErrorStack = sprintf('%s\tIn %s, line %d\n',...
                sErrorStack,ME.stack(i).name,ME.stack(i).line);
            
            % create hyper link message
            sMatCmd = sprintf('matlab.desktop.editor.openAndGoToLine(%s%s%s,%d);',...
                qtm,ME.stack(i).file,qtm,ME.stack(i).line);
            sHypLink = sprintf('<a href="matlab: %s">%s</a>',...
                sMatCmd,ME.stack(i).name);
            
            sErrorStackLink = sprintf('%s\tIn %s, line %d\n',...
                sErrorStackLink,sHypLink,ME.stack(i).line);
            
        end
        
    end
    
end

return
