function varargout = versionAliasMatlab(varargin)
% VERSIONALIASMATLAB get a complete alias cell between MATLAB major version
% (e.g. 7.8) and release (e.g. R2009a) or get the opposite, when specifying
% a version or release. Available release bit versions are passed as well.
%
% Syntax:
%   varargout = versionAliasMatlab
%   varargout = versionAliasMatlab(sVersionOrRelease)
%   varargout = versionAliasMatlab(sVersionOrRelease,'all')
%
% Inputs:
%   varargin - 1: [optional] string with version or release info
%              2: [optional] string 'all'
%
% Outputs:
%   varargout
%      case 1 (no input): cell(nx3) with MATLAB version aliases 7.1 to now
%                           cell{n,1} - Matlab release string, e.g. R2016a
%                           cell{n,2} - Matlab version string, e.g. 9.0
%                           cell{n,3} - cell(1xm) with available bit
%                                       versions, e.g. 'w32' and/or 'w64'
%      case 2 (e.g. 'R2009b'): 2 output arguments 
%                           1: sVersion - Matlab version string, e.g. 7.9
%                           2: cBit     - cell(1xm) with available bit
%                                         versions, e.g. {'w32','w64'}
%      case 3 (e.g. '7.10'): 2 output arguments 
%                           1: sRelease - Matlab release string, e.g. R2010a
%                           2: cBit     - cell(1xm) with available bit
%                                         versions, e.g. {'w32','w64'}
%      case 4 (e.g. '7.10','all'): 3 output arguments  with MATLAB version and
%                                  release info
%                           1: sRelease - Matlab release string, e.g. R2010a
%                           2: sVersion - Matlab version string, e.g. 7.10
%                           3: cBit     - cell(1xm) with available bit
%                                         versions, e.g. {'w32','w64'}
%
% Example: 
%   cVersion = versionAliasMatlab
%   [sVersion,cBit] = versionAliasMatlab('R2010a')
%   [sRelease,cBit] = versionAliasMatlab('7.9')
%   [sRelease,sVersion,cBit] = versionAliasMatlab('7.9','all')
%   sEmpty = versionAliasMatlab([])
%   sEmpty = versionAliasMatlab('anythingNoneMatlabVersion')
%
% See also: version, ver, computer('arch')
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-08-19

% check input
if isnumeric(varargin{1}) && unique(size(varargin{1})) == 1
    varargin{1} = num2str(varargin{1});
end

% version alias definition
cVersion = {...
    'R2005b'    '7.1'   {'w32'};...
    'R2006a'    '7.2'   {'w32'};...
    'R2006b'    '7.3'   {'w32'};...
    'R2007a'    '7.4'   {'w32'};...
    'R2007b'    '7.5'   {'w32','w64'};...
    'R2008a'    '7.6'   {'w32','w64'};...
    'R2008b'    '7.7'   {'w32','w64'};...
    'R2009a'    '7.8'   {'w32','w64'};...
    'R2009b'    '7.9'   {'w32','w64'};...
    'R2010a'    '7.10'  {'w32','w64'};...
    'R2010b'    '7.11'  {'w32','w64'};... 'R2010bSP1' '7.11.1' {'w32','w64'};...
    'R2011a'    '7.12'  {'w32','w64'};...
    'R2011b'    '7.13'  {'w32','w64'};...
    'R2012a'    '7.14'  {'w32','w64'};...
    'R2012b'    '8.0'   {'w32','w64'};...
    'R2013a'    '8.1'   {'w32','w64'};...
    'R2013b'    '8.2'   {'w32','w64'};...
    'R2014a'    '8.3'   {'w32','w64'};...
    'R2014b'    '8.4'   {'w32','w64'};...
    'R2015a'    '8.5'   {'w32','w64'};...
    'R2015b'    '8.6'   {'w32','w64'};...
    'R2016a'    '9.0'   {'w64'};...
    'R2016b'    '9.1'   {'w64'};...
    'R2017a'    '9.2'   {'w64'};...
    'R2017b'    '9.3'   {'w64'};...
    'R2018a'    '9.4'   {'w64'};...
    'R2018b'    '9.5'   {'w64'};...
    'R2019a'    '9.6'   {'w64'};...
    'R2019b'    '9.7'   {'w64'};...
    'R2020a'    '9.8'   {'w64'};...
    'R2020b'    '9.9'   {'w64'};...
    'R2021a'    '9.10'  {'w64'};...
    'R2021b'    '9.11'  {'w64'};...
    'R2022a'    '9.12'  {'w64'};...
    'R2022b'    '9.13'  {'w64'};...
    'R2023a'    '9.14'  {'w64'};...
    'R2023b'    '23.2'  {'w64'}};
    
% create output
if nargin == 0 
    % pass complete cell
    varargout = {cVersion};
elseif nargin==1 && isempty(varargin{1})
    % empty call
    varargout = cell(1,nargout);
elseif nargin > 0
    sPattern = regexpi(varargin{1},'R\d{4}\w','match','once');
    if ~isempty(sPattern)
        % request is a release string
        cVersionSearch = regexpi(cVersion(:,1),['^' sPattern],'once');
        bVersion = ~cellfun(@isempty,cVersionSearch);
        if any(bVersion)
            if nargin > 1 && strcmp(varargin{2},'all')
                varargout = cVersion(bVersion,:);
            else
                varargout = cVersion(bVersion,[2,3]);
            end
        else
            varargout = cell(1,nargout);
        end
    else
        % request is a MATLAB version string
        sPattern = regexpi(varargin{1},'^\d+\.\d+','match','once');
        if ~isempty(sPattern)
            bVersion = strcmp(sPattern,cVersion(:,2));
            if any(bVersion)
                if nargin > 1 && strcmp(varargin{2},'all')
                    varargout = cVersion(bVersion,:);
                else
                    varargout = cVersion(bVersion,[1,3]);
                end
            else % no match
                varargout = cell(1,nargout);
            end
        else % empty search string
            varargout = cell(1,nargout);
        end
    end
end
return
