function xConfiguration = dcsFcnOptionalContentSet(xConfiguration,sSection,xSet)
% DCSFCNOPTIONALCONTENTSET assign structure values to specified section in
% optional content of configuration. A two level structure is considered.
%
% Syntax:
%   xConfiguration = dcsFcnOptionalContentSet(xConfiguration,sSection,xSet)
%
% Inputs:
%   xConfiguration - structure with fields of DIVe configuration
%         sSection - string with section name for optional content
%             xSet - structure with fields of optional content in section
%
% Outputs:
%   xConfiguration - structure with fields of DIVe configuration
%
% Example:
%   xSet.Logging.sampleTime = 0.1;
%   xConfiguration = dcsFcnOptionalContentSet(xConfiguration,'DIVeModelBased',xSet)
% 
% See also: structUnify
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2015-07-05

% determine optional content section
if isfield(xConfiguration,'OptionalContent') && ...
        isfield(xConfiguration.OptionalContent,'Section')&& ...
        isfield(xConfiguration.OptionalContent.Section,'name')
    % check for specified section
    bSection = strcmp(sSection,{xConfiguration.OptionalContent.Section.name});
    if ~any(bSection)
        % create section
        nSection = numel(xConfiguration.OptionalContent.Section) + 1;
        xConfiguration.OptionalContent.Section(nSection).name = sSection;
        xConfiguration.OptionalContent.Section(nSection).description = '';
    else
        % assign section ID
        nSection = bSection;
    end
else
    % create section
    nSection = 1;
    xConfiguration.OptionalContent.Section = struct('name',{sSection},'description',{''});
end


if isempty(xSet)
    % remove Section from optional content
    if numel(fieldnames(xConfiguration.OptionalContent.Section(nSection))) > 2
        % remove just field of section
        cRemove = fieldnames(xSet);
        xConfiguration.OptionalContent.Section = ...
            rmfield(xConfiguration.OptionalContent.Section,cRemove);
    else
        % remove section
        bKeep = true(1,numel(xConfiguration.OptionalContent.Section));
        bKeep(nSection) = false;
        xConfiguration.OptionalContent.Section = ...
            xConfiguration.OptionalContent.Section(bKeep);
    end
else
    % assign structure level
    cField = fieldnames(xSet);
    for nIdxField = 1:numel(cField)
        % check if field exists already
        if isfield(xConfiguration.OptionalContent.Section(nSection),cField{nIdxField})
            % unify structures
            xConfiguration.OptionalContent.Section(nSection).(cField{nIdxField}) = ...
                structUnify(xConfiguration.OptionalContent.Section(nSection).(cField{nIdxField}),...
                xSet.(cField{nIdxField}));
        else
            % assign structure
            xConfiguration.OptionalContent.Section(nSection).(cField{nIdxField}) = ...
                xSet.(cField{nIdxField});
        end % if already existing
    end % for all fieldnames
end %if isempty
return
