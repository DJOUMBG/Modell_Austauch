function dstModel2Library(sFilePath)
% DSTMODEL2LIBRARY change the specified Simulink model file to a library.
%
% Syntax:
%   dstModel2Library(sFilePath)
%
% Inputs:
%   sFilePath - string 
%
% Outputs:
%
% Example: 
%   dstModel2Library(sFilePath)
%
%
% See also: fullfileSL, ismdl, pathpartsSL
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-11-10

% input check
[sPath,sFile,sExtension] = fileparts(sFilePath);
if ~exist(sFilePath,'file')
    disp(['dstModel2Library - specified model does not exist: ' sFilePath]);
    return
end
if ~ismember(sExtension,{'.mdl','.slx'})
    error('dstModel2Library:UnknownFileType',['The specified file type is not known: ' sFile sExtension]);
end

% prevent shadowed files
if ismdl(sFile)
    close_system(sFile);
end

% open specified model
uiopen(sFilePath,true)
sBlockDiagType = get_param(sFile,'BlockDiagramType');
if strcmpi(sBlockDiagType,'Library')
    disp(['dstModel2Library - the specified model is already a library: ' sFilePath])
    return
end

% determine model block
cBlock = find_system(sFile,'SearchDepth',1,'FollowLinks','on','LookUnderMasks','all','BlockType','SubSystem');

% create new library
new_system([sFile '_libtemp'], 'Library');

% copy block from model to library
cBlockPath = pathpartsSL(cBlock{1});
hBlock = add_block(cBlock{1},fullfileSL([sFile '_libtemp'],cBlockPath{2:end}));
nPosition = get_param(hBlock,'Position');
set_param(hBlock,'Position',nPosition);

% close source model and delete source model
close_system(sFile,0);
delete(sFilePath);

% save library with new name
save_system([sFile '_libtemp'],sFilePath);
close_system(sFile,0);
return
