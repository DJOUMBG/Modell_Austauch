function xSet = dcsFcnOptionalContentGet(xConfiguration,sSection,sField)
% DCSFCNOPTIONALCONTENTGET get a specified substructure of a specified
% section from the optional content of the current configuration.
% Returns an empty structure if the optional content or the requested field
% is empty.
%
% Syntax:
%   xSet = dcsFcnOptionalContentGet(xConfiguration,sSection)
%
% Inputs:
%   xConfiguration - structure with fields of DIVe configuration
%         sSection - string with section name for optional content
%           sField - string with field name of requested structure within
%                    section
%
% Outputs:
%       xSet - structure with fields of optional content in section
%
% Example: 
%   xSet = dcsFcnOptionalContentGet(xConfiguration,'DIVeModelBased','Mask')

% initialize output
xSet = struct();
xSet = xSet([]);

% check for teh availability of optional content in current configuration
if isfield(xConfiguration,'OptionalContent') && ...
        isfield(xConfiguration.OptionalContent,'Section') && ...
        ~isempty(xConfiguration.OptionalContent.Section) && ...
        isfield(xConfiguration.OptionalContent.Section,'name')
    % determine correct section
    bSection = strcmp(sSection,{xConfiguration.OptionalContent.Section.name});
    % get substructure
    if any(bSection) && ...
            isfield(xConfiguration.OptionalContent.Section(bSection),sField) &&...
            ~isempty(xConfiguration.OptionalContent.Section(bSection).(sField))
        xSet = xConfiguration.OptionalContent.Section(bSection).(sField);
    end
end
return