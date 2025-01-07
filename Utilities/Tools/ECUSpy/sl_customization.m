function sl_customization(cm)
% sl_customization - standard function for customization of Simulink.
% After relevant changes execute 'sl_refresh_customizations'

  %% Register custom menu function.
  cm.addCustomMenuFcn('Simulink:ContextMenu', @getMyMenuItems);
end

% =========================================================================

function schemaFcns = getMyMenuItems(callbackInfo) 
% GETMYMENUITEMS add new right click context menu items in Simulink
%
% Syntax:
%   schemaFcns = getMyMenuItems(callbackInfo)
%
% Inputs:
%   callbackInfo - 
%
% Outputs:
%   schemaFcns - cell (1xn) of function handles
%
% Example: 
%   schemaFcns = getMyMenuItems(callbackInfo)

% getMyMenuItems - define custom menu function.
  schemaFcns = {@SchemaEcuSpyAdd}; 
end

% =========================================================================
% Schema implementations
% =========================================================================

function schema = SchemaEcuSpyAdd(callbackInfo)
schema = sl_action_schema;
schema.label = 'EcuSpyAdd';
schema.statustip = 'Add marked ports & signals to EcuSpy';
schema.callback = @EcuSpyAdd;
end

% =========================================================================
% Function call implementations with arguments
% =========================================================================

function EcuSpyAdd(callbackInfo)
slcEcuSpyAdd(gcbs(1),gcl,1);
end
