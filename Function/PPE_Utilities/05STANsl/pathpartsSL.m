function cPath = pathpartsSL(sBlockpath)
% PATHPARTSSL decompose a Simulink blockpath into the single model levels.
%
% Syntax:
%   cPath = pathpartsSL(sBlockpath)
%
% Inputs:
%   sBlockpath - string with a block path (slash '/' as model level
%                separator. Slashes as model name components must be
%                doubled '//'
%
% Outputs:
%   cPath - cell (1xn) with string of single model level names
%
% Example: 
%   cPath = pathpartsSL('test1/subsystem1/blockwithunit[kg//h]')
% % returns
% % cPath = 
% %     'test1'    'subsystem1'    'blockwithunit[kg/h]'
%
% Other m-files required: fullfileSL
%
% See also: fullfileSL, fileparts, gcb
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% initialize output
cPath = {}; %#ok

% separator string
sSep = '/'; 

% find separators
vSepPos = strfind(sBlockpath,sSep);

% catch non-path but single system call
if isempty(vSepPos)
    cPath = {sBlockpath};
    return
end

% remove double separators
vPosDouble = find(diff(vSepPos)==1); % get first element of a double position
vPosDouble = [vPosDouble, vPosDouble+1]; % add second element of double position to list
vSepPos = vSepPos(~ismember(vSepPos,vSepPos(vPosDouble)));
vSepPos = sort(vSepPos);

% remove leading and ending separators
if vSepPos(1) == 1
    vSepPos = vSepPos(2:end);
    sBlockpath = sBlockpath(2:end);
end
if vSepPos(end) == length(sBlockpath)
    vSepPos = vSepPos(1:end-1);
    sBlockpath = sBlockpath(1:end-1);
end

% split blockpath according separator positions
vSepPos = [vSepPos length(sBlockpath)+1];
nPosLast = 0;
cPath = cell(1,length(vSepPos));
for nPart = 1:length(vSepPos)
%     cPath{nPart} =strrep(sBlockpath(nPosLast+1:vSepPos(nPart)-1),'//','/'); % get part and remove double slash
    cPath{nPart} = sBlockpath(nPosLast+1:vSepPos(nPart)-1); % get part 
    nPosLast = vSepPos(nPart);
end
return

