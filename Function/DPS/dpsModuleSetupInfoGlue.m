function sInfo = dpsModuleSetupInfoGlue(xModuleSetup,sGlue)
% DPSMODULESETUPINFOGLUE create complete class info of module from structure. 
% Creates an info string with the complete classification information of a
% module from the DIVe configuration XML ModuleSetup structure as code
% shortcut.
% Part of the DIVe platform standard package (dps).
% 
% Syntax:
%   sInfo = dpsModuleSetupInfoGlue(xModuleSetup)
%
% Inputs:
%     xModuleSetup - structure (1xn) with fields according DIVe 
%                    configuration XML: 
%       .Module    - structure with module information and fields:
%         .context - string with module context
%         .species - string with module species
%         .family  - string with module family
%         .type    - string with module type
%         .type    - string with module type
%         .variant - string with module variant
%         .modelSet - string with module modelSet
%         ...
%          sGlue - string to add between elements of info
%
% Outputs:
%   sInfo - string with module's classification info
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-09-02

sInfo = strGlue({xModuleSetup.Module.context,...
                 xModuleSetup.Module.species,...
                 xModuleSetup.Module.family,....
                 xModuleSetup.Module.type,...
                 'Module',...
                 xModuleSetup.Module.variant,...
                 xModuleSetup.Module.modelSet},sGlue);
return
