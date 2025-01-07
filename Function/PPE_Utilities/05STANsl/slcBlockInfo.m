function xBlock = slcBlockInfo(hBlock)
% SLCBLOCKINFO generates a structure with important block properties.
% (for lean code with reduced get_param calls)
% Part of Simulink custom package slc.
%
% Syntax:
%   xBlock = slcBlockInfo(hBlock)
%
% Inputs:
%   hBlock - handle (1xn) or path to block or cell with block paths
%
% Outputs:
%   xBlock - structure (1xn) with fields: 
%   .Name               - string 
%   .Handle             - double/handle
%   .Parent             - string with full path of parent
%   .BlockPath        	- string with full path of block
%   .BlockType          - string with block type
%   .MaskType           - string with mask type
%   .Ports              - vector (1x8) with amount of port types
%                         1: Inport, 2: Outport
%   .PortCon         	- structure (1xNumberOfAllPorts) with
%       .Type           - string with number of port type (1-8)
%       .Position       - vector(1x2) with position
%       .SrcBlock       - handle of source block (only if port is Inport)
%       .SrcPort        - vector with handles of inports
%       .DstBlock       - handle of source block (only if port is Outport)
%       .DstPort        - vector with handles of inports
%   .PortHandles        - structure with
%       .Inport         - vector with handles of inports
%       .Outport        - vector with handles of outports
%       .Enable         - vector with handles 
%       .Trigger        - vector with handles 
%     	.State          - vector with handles 
%     	.LConn          - vector with handles 
%     	.RConn          - vector with handles 
%       .Ifaction       - vector with handles 
%   .LineHandles      	- handle of "upstream" line if branched,  
%       .Inport         - vector with line handles of inports
%       .Outport        - vector with line handles of outports
%       .Enable         - vector with line handles 
%       .Trigger        - vector with line handles 
%     	.State          - vector with line handles 
%     	.LConn          - vector with line handles 
%     	.RConn          - vector with line handles 
%       .Ifaction       - vector with line handles 
%   .Position           - vector (1x4) absolute point extensions of block
%                         (left top right bottom)
%   .Tag                - string with tag of block
%
% Example: 
%   xBlock = slcBlockInfo(hBlock)
%
% See also: slcLineInfo, gcbs 
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2008-09-05

% take current block if not specified
if nargin == 0
    hBlock = gcb;
end

% ensure handle (not path)
if ischar(hBlock)
    hBlock = get_param(hBlock,'Handle');
end

% ensure cell type of hp
if all(ishandle(hBlock)) 
    hBlock = num2cell(hBlock);
end

% reduce to block handles only
bBlock = cell2mat(cellfun(@(x)strcmpi(get_param(x,'Type'),'block'),hBlock,'UniformOutput',false));
hBlock = hBlock(bBlock);

% initialize output structure
xBlock = struct('Name',[],'Handle',[],'Parent',[],'BlockPath',[],... 
            'BlockType',[],'MaskType',[],'Ports',[],...
            'PortCon',[],'PortHandles',[],'LineHandles',[],'Position',[]);
        
% get block information
for nIdxBlock = 1:numel(hBlock)
    xBlock(nIdxBlock).Name = get_param(hBlock{nIdxBlock},'Name');
    xBlock(nIdxBlock).Handle = get_param(hBlock{nIdxBlock},'Handle');
    xBlock(nIdxBlock).Parent = get_param(hBlock{nIdxBlock},'Parent');
    xBlock(nIdxBlock).BlockPath = [xBlock(nIdxBlock).Parent '/' xBlock(nIdxBlock).Name];
    xBlock(nIdxBlock).BlockType = get_param(hBlock{nIdxBlock},'BlockType');
    xBlock(nIdxBlock).MaskType = get_param(hBlock{nIdxBlock},'MaskType');
    xBlock(nIdxBlock).Ports = get_param(hBlock{nIdxBlock},'Ports');
    xBlock(nIdxBlock).PortCon = get_param(hBlock{nIdxBlock},'PortConnectivity');
    xBlock(nIdxBlock).PortHandles = get_param(hBlock{nIdxBlock},'PortHandles');
    xBlock(nIdxBlock).LineHandles = get_param(hBlock{nIdxBlock},'LineHandles');
    xBlock(nIdxBlock).Position = get_param(hBlock{nIdxBlock},'Position');
    xBlock(nIdxBlock).Tag = get_param(hBlock{nIdxBlock},'Tag');
end
return