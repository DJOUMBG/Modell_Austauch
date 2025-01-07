function xLogSetup = dcsCfgLogSetupGet(xConfig,sDefSampleType,sDefSampleTime)
% DCSCFGLOGSETUPGET get logging setup from configuration (new tag or old
% from DIVeMB OptionalContent). Default values can be passed, if
% Configuration contains no logging setup.
%
% Syntax:
%   xLogSetup = dcsCfgLogSetupGet(xConfig,sDefSampleType,sDefSampleTime)
%
% Inputs:
%          xConfig - structure with fields of a DIVe configuration
%   sDefSampleType - string with default SampleType for logging
%   sDefSampleTime - string with default SampleTime for logging
%
% Outputs:
%   xLogSetup - structure with fields:
%     .sampleType - string with sample type ('ToWorkspace','ToASCII',
%                   'Simulink','LDYN')
%     .sampleTime - string with sampleTime value in [seconds]
%
% Example: 
%   xLogSetup = dcsCfgLogSetupGet(xConfig,sDefSampleType,sDefSampleTime)
%
% See also: dcsFcnOptionalContentGet
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-08-20

% check input
if nargin < 2
    sDefSampleType = 'ToWorkspace';
end
if nargin < 3
    sDefSampleTime = '0.1';
end

% init output
xLogSetup = struct('sampleType',{sDefSampleType},...
                   'sampleTime',{sDefSampleTime});

if isfield(xConfig,'Interface') && ...
        isfield(xConfig.Interface,'LogSetup') && ...
        ~isempty(xConfig.Interface.LogSetup)
    % standard LogSetup (new common tag)
    xLogSetup = xConfig.Interface.LogSetup;
elseif isfield(xConfig,'OptionalContent')
    % old logsetup in optionalContent of DIVeMB
    xLogOption = dcsFcnOptionalContentGet(xConfig,'DIVeModelBased','Logging');
    if ~isempty(xLogOption)
        if isfield(xLogOption,'sampleType')
            xLogSetup.sampleType = xLogOption.sampleType;
        end
        if isfield(xLogOption,'sampleTime')
            xLogSetup.sampleTime = xLogOption.sampleTime;
        end
    end
end
return