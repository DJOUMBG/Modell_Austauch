function [cPathDataVariant,cDataClassName] = dpsDataSetVariantCollect(xModuleSetup,sPathContent)
% DPSDATASETVARIANTCOLLECT generates list of selected dataset variant file
% pathes and a matching list of dataset classNames for use with
% dpsModuleInit.
%
% Syntax:
%   [cPathDataVariant,cDataClassName] = dpsDataSetVariantCollect(xModuleSetup,sPathContent)
%
% Inputs:
%   xModuleSetup - structure (1x1) with fields: 
%     .Module    - structure (1x1) with fields:
%       .context - string with module's DIVe context
%       .species - string with module's DIVs species
%       .family  - string with module's DIVs family
%       .type    - string with module's DIVs type
%       .variant - string with module's DIVs variant
%        ... and more
%     .DataSet   - structure (1xn) with fields:
%       .level   - string with aharing level of DataClass (species, family
%                  or type)
%       .classType - string with dataset classType
%       .className - string with dataset className
%       .variant   - string with dataset variant selection for dataset class 
%        ... and more
%   sPathContent - string 
%
% Outputs:
%   cPathDataVariant - cell (1xn) with strings of filesystem paths of
%                      selected dataset variants
%     cDataClassName - cell (1xn) with strings of the matching dataset
%                      classNames
%
% Example: 
%   [cPathDataVariant,cDataClassName] = dpsDataSetVariantCollect(xModuleSetup,sPathContent)
%
% See also: dpsModuleSetupInfoGlue, pathparts
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-06-22

% generate path to modelset directory as intermediate string
sPathModelSet = fullfile(sPathContent,dpsModuleSetupInfoGlue(xModuleSetup,filesep));
cPathModelSet = pathparts(sPathModelSet);

% generate pathes to dataset variant selections
cLevel = {'species','family','type'};
cPathDataVariant = {};
cDataClassName = {};
if isfield(xModuleSetup,'DataSet')
    for nIdxDataSet = 1:numel(xModuleSetup.DataSet)
        [bTF,nLevel] = ismember(lower(xModuleSetup.DataSet(nIdxDataSet).level),cLevel); %#ok<ASGLU>
        % path of selected dataset
        cPathDataVariant = [cPathDataVariant ...
            {fullfile(cPathModelSet{1:end-6+nLevel},... % cPathModelSet{1:end-6} = path up to context level
            'Data',...
            xModuleSetup.DataSet(nIdxDataSet).classType,...
            xModuleSetup.DataSet(nIdxDataSet).variant)}]; %#ok<AGROW>
        cDataClassName = [cDataClassName {xModuleSetup.DataSet(nIdxDataSet).className}]; %#ok<AGROW>
    end
end
return
