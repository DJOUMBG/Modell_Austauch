function msfcn_deadend(block)
% Level-2 M file S-Function for VITOS GUI connection
% This s-function single purpose is to create a RunTimeObject, which can be
% queried by a GUI timer for its actual value during a simulink simulation.
% A VITOS GUI will display the value in the specified GUI element.
%
% See also: slcVITOS.mdl
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

  setup(block);
return

% =========================================================================

function setup(block)
  
  %% Register number of input and output ports
  block.NumInputPorts  = 1;
  block.NumOutputPorts = 0;

  %% Setup functional port properties to dynamically
  %% inherited.
  block.SetPreCompInpPortInfoToDynamic;
  block.SetPreCompOutPortInfoToDynamic;
 
  block.InputPort(1).DirectFeedthrough = true;
  
  %% Set block sample time to inherited
  block.SampleTimes = [-1 0];
  
  %% Run accelerator on TLC
  block.SetAccelRunOnTLC(true);
  
  %% Register methods
  block.RegBlockMethod('Outputs',                 @Output);  
return

% =========================================================================

function Output(block)
% no outputs intended
return
