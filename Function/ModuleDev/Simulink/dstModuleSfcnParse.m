function [cInport,cOutport,xParam] = dstModuleSfcnParse(sFile,hBlock)
% DSTMODULESFCNPARSE parse Interface information from Simulink Model. If
% s-function ModelSet is used, parameter index information is derived from
% matching DIVe ModelMask to s-function mask parameters.
%
% Syntax:
%   [cInport,cOutport,xParam] = dstModuleSfcnParse(sFile,hBlock)
%
% Inputs:
%    sFile - string with filepath of Simulink model (*.mdl|*.slx)
%   hBlock - handle (1x1) or string with Simulink block path to DIVe Model
%            block (wrapped subsystem level)
%
% Outputs:
%    cInport - cell (mx1) of strings with names of inports
%   cOutport - cell (nx1) of strings with names of outports
%     xParam - structure with fields: 
%       .name - string with parameter name
%       .index - integer (1x1) with parameter index on s-function
%                interface
%       .subspecies - string (or empty) with subspecies name in sMP
%                     structure
% Example: 
%   [cInport,cOutport,xParam] = dstModuleSfcnParse(sFile,hBlock)
%
% Subfunctions: dstParamSfcnDetermination
%
% See also: dstXmlModule, ismdl, slcLoadEnsure, strsplitOwn, structInit
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-07-06

% check input
if nargin < 2
    hBlock = '';
end

% ensure Simulink Block availability
if isempty(hBlock) || ~ismdl(hBlock)
    % ensure simulink availability
    if isempty(find_system('SearchDepth',0))
        load_system('simulink');
    end
    
    % load simulink model
    slcLoadEnsure(sFile,false)
    
    % split filename
    [sPath,sName] = fileparts(sFile); %#ok<ASGLU>
    
    % detect block
    cBlock = find_system(sName,'SearchDepth',1,'BlockType','SubSystem');
    if numel(cBlock) == 1
        hBlock = cBlock{1};
    elseif numel(cBlock) > 1
        nSelection = listdlg('ListString',cBlock,...
            'SelectionMode','single',...
            'ListSize',[300 400],...
            'Name','Select Block',...
            'PromptString','Select Subsystem for DIVe module creation:');
        if ~isempty(nSelection)
            hBlock = cBlock{nSelection};
        else
            disp('Simulink Subsystem block missing! Stopped...')
            return
        end
    else % Simulink model does not contain a subsystem
        error('dstModuleSfcn:noModuleSubsystem',...
            'Simulink Subsystem block missing or not clear - please specify!')
    end
end

% determine ports of Simulink model
cInportPath = find_system(hBlock,'LookUnderMasks','all','SearchDepth',1,'BlockType','Inport');
cInport = get_param(cInportPath,'name');
cOutportPath = find_system(hBlock,'LookUnderMasks','all','SearchDepth',1,'BlockType','Outport');
cOutport = get_param(cOutportPath,'name');

% check for s-function ModelSet
cPath = pathparts(sFile);
if strncmp(cPath{end-1},'sfcn',4)
    % determine parameter indices for s-functions from base model
    xParam = dstParamSfcnDetermination(hBlock);
else
    xParam = structInit({'name','index','subspecies'});
end

% close Simulink model
close_system(bdroot(hBlock),0);
return

% =========================================================================

function xParameter = dstParamSfcnDetermination(hBlock)
% DSTPARAMSFCNDETERMINATION determine parameter order of s-function and
% used subspecies in Simulink mask values. 
%
% Syntax:
%   xParameter = dstParamSfcnDetermination(cPath)
%
% Inputs:
%     cPath - cell (1xn) with strings containing each one level of the 
%                module directory path
%
% Outputs:
%   xParameter - structure with fields of parameter names
%       .(parname)  - structure of parameter
%         .index      - integer with parameter index in s-function
%         .subspecies - string with 4th level of MATLAB structure
%
% Example: 
%   xParameter = dstParamSfcnDetermination(cPath)

% ensure masked subsystem
if ~strcmp('on',get_param(hBlock,'Mask'))
    error('dstParamSfcnDetermination:noMask',...
        'No subsystem "%s" has no mask for parameter index determination!',hBlock);
end

% get the wrapper mask info and transfer the parameter sort order
cMaskName = get_param(hBlock,'MaskNames'); % get internal parameter names
cMaskValue = get_param(hBlock,'MaskValues'); % get external/WS parameter names

% determine s-function parameters
cBlockSfcn = find_system(hBlock,'LookUnderMasks','all','SearchDepth',2,'BlockType','S-Function'); % s-function block
if isempty(cBlockSfcn) % s-function not found
    disp('S-function block could not be found checking mask only!')
    cParSort = cMaskName;
    cSfcnParameter = {};
else % s-function block found
    % get s-function block info
    sSfcnParameter = get_param(cBlockSfcn{1},'Parameters'); % sfcnParam1, sfcnParam2,...
    cSfcnParameter = strsplitOwn(sSfcnParameter,{',',' '}); % split
    cSfcnParameter = strtrim(cSfcnParameter); % remove blanks
    cParSort = cSfcnParameter;
    
    % get the low level mask info and transfer parameter sort order
    hBlockSfcn = cBlockSfcn{1};
    if strcmp(get_param(hBlockSfcn,'Mask'),'on')
        cMaskLowName = get_param(hBlockSfcn,'MaskNames'); % parameter names of lower mask on internal side
        cMaskLowValue = get_param(hBlockSfcn,'MaskValues'); % parameter names of lower mask on external side
        
        % Remove automatic generated parameter of the Simulink S-Function wrapper
        cIgnore = lower({'rtw_sf_name','showVar','prm_to_disp'});
        bIgnore = ismember(lower(cMaskLowName),cIgnore);
        cMaskLowName = cMaskLowName(~bIgnore);
        cMaskLowValue = cMaskLowValue(~bIgnore);
        
        % check amount of parameters
        if numel(cMaskLowValue) ~= numel(cSfcnParameter)
            % no matching MATLAB version available - give up
            xParameter = struct();
            fprintf(2,['Warning: dstXmlModule - the number of parameters ' ...
                       'on the wrapper Simulink mask is not matching the ' ...
                       'parameters of the s-function.\n']);
        end
        [bInMask,nIdPos] = ismember(cSfcnParameter,cMaskLowName); %#ok<ASGLU>
        cParSort = cMaskLowValue(nIdPos); % transfer of sfcn parameter sort order to lower mask external value namespace
    end
end
    
% match lower level with upper mask
[bInMask,nIdPos] = ismember(cParSort,cMaskName); %#ok<ASGLU>
cParSort = cMaskValue(nIdPos); % transfer of sfcn parameter sort order to upper mask external value namespace
if numel(cParSort) < numel(cSfcnParameter)
    disp(['CAUTION: s-function parameters (' num2str(numel(cSfcnParameter)) ...
        ') exceeds number of matched masked parameters (' num2str(numel(cParSort)) ')!']);
end

%% build output 
% remove sMP, context and species from structure strings
cParSortRed = regexprep(cParSort,'sMP\.\w+\.\w+\.',''); 
% determine parameter name
cParName = regexp(cParSortRed,'\w+$','match','once');
% determine subspecies name, if available
cParSubspecies = regexp(cParSortRed,'^\w+(?=\.)','match','once');
% determine excessive structure levels
cParExtraLevel = regexp(cParSortRed,'(?<=^\w+\.)\w+\.','match','once');
% create parameter structure
if isempty(cParName)
    xParameter = structInit({'name','index','subspecies'});
else
    xParameter = struct('name',cParName,...
        'index',num2cell((1:numel(cParName))'),...
        'subspecies',cParSubspecies);
end
% report excessive sMP structure levels
bStructLevelExtra = ~cellfun(@isempty,cParExtraLevel);
if any(bStructLevelExtra)
    disp(['CAUTION: Simulink block mask parameters value contains ' ...
        'parameters of more than 5 structure levels before the parameter name:']);
    nExtra = find(bStructLevelExtra);
    for nIdxPar = 1:numel(nExtra)
        fprintf('   %s (index: %i)\n',cParSort{nExtra(nIdxPar)},nExtra(nIdxPar));
    end
end
return
