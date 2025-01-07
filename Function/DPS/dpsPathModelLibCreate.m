function sPathModelLib = dpsPathModelLibCreate(xModuleSetup,xModule,sPathContent)
% DPSPATHMODELLIBCREATE determine the module's main file for the model
% library
%
% Syntax:
%   sPathModelLib = dpsPathModelLibCreate(xModuleSetup,xModule)
%
% Inputs:
%   xModuleSetup - structure with fields according DIVe configuration 
%        xModule - structure with fields according DIVe module XML
%   sPathContent - string with path of DIVe content (contains folder 
%                  trees of bdry, phys, ctrl, human)
%
% Outputs:
%   sPathModelLib - string with filesystem path to main file of selected
%                   ModelSet in module
%
% Example: 
%   sPathModelLib = dpsPathModelLibCreate(xModuleSetup,xModule)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-06-22

% get main/library file of modelset
bModelSet = strcmp(xModuleSetup.Module.modelSet,...
    {xModule.Implementation.ModelSet.type}); % get used ModelSet
bFileMain = cell2mat(cellfun(@str2double,...
    {xModule.Implementation.ModelSet(bModelSet).ModelFile.isMain},...
    'UniformOutput',false)); % get main file of ModelSet
if ~any(bFileMain) % get Simulink file as fallback
    bFileMain = ~cellfun(@isempty,...
        regexp({xModule.Implementation.ModelSet(bModelSet).ModelFile.isMain},...
        '(\.mdl$)|(\.slx$)','once')); 
end
nFileMain = find(bFileMain); % get file index in structure
sFileMain = xModule.Implementation.ModelSet(bModelSet).ModelFile(nFileMain(1)).name;

% generate path to main/library file of modelset
sPathModelLib = fullfile(sPathContent,...
    dpsModuleSetupInfoGlue(xModuleSetup,filesep),... % path context until modelset
    sFileMain);
return
