function bMdl = ismdl(cSystemPath)
% ISMDL checks cSystemPath for being a loaded Simulink model or submodel.
% Alternative implemetation would be with a direct try/catch find_system
% call.
%
% Syntax:
%   bMdl = ismdl(cSystemPath)
%
% Inputs:
%   cSystemPath - string or cell of strings with Simulink model paths
%
% Outputs:
%   bMdl - boolean scalar or vector true/false
%
% Example: 
%  load_system('simulink')
%  bMdl = ismdl('simulink/Sinks/Terminator')
%  bMdl = ismdl({'simulink/Sinks/Terminator','simulink/Sources/Clock'})
%  bMdl = ismdl({'simulink/NoValidSubsystem/Terminator','simulink/Sources/NoValidBlock'})
%
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: find_system 
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% path input
if ~iscell(cSystemPath)
    cSystemPath = {cSystemPath};
end

% intialize output
bMdl = false(size(cSystemPath));

% check all model paths
for nIdx = 1:numel(bMdl)
    try
        bMdl(nIdx) = ~isempty(find_system(cSystemPath{nIdx},'SearchDepth',0));
    catch %#ok
        bMdl(nIdx) = false;
    end
end
return
