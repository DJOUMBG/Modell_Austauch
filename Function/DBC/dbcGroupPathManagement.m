function cPath = dbcGroupPathManagement(cPath,cPathFile)
% DBCGROUPPATHMANAGEMENT holds the detailed path assignments of user groups
% with more complex needs. Mandatory for the extended use (cells) of
% content pathes is the combination of content, configurations and masks
% within the specified folders.
%
% Syntax:
%   cPath = dbcGroupPathManagement(cPath,cPathFile)
%
% Inputs:
%   cPath     - cell (1xn) with strings of Content/Configuration base paths
%   cPathFile - cell (1xm) with strings local mfile path
%
% Outputs:
%   cPath - cell (1xn) with strings of Content/Configuration base paths
%
% Example: 
%   cPath = dbcGroupPathManagement(cPath,cPathFile)
% 
% See also: dbc, dbcPreferences
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-04-28

% try to recover pathes from platform
bPathExternal = false;
if evalin('base','exist(''sMP'',''var'')')
    sMP = evalin('base','sMP');
    if isfield(sMP,'platform') && ...
            isfield(sMP.platform,'content') && ...
            isfield(sMP.platform,'configuration')
        bPathExternal = true;
    end
end

if ~bPathExternal
    % check for certain user group (net)work paths
    switch lower(getenv('username'))
        case {'hillenb'} % Developer & Support
            cPathAdd = {fullfile(cPathFile{1:end-3})
                fullfile(cPathFile{1:end-4},'com')
                'C:\dirsync\01_DIVe\00_d_main'};
            
        case {'gerhajo'} % Developer & Support
            cPathAdd = {fullfile(cPathFile{1:end-3})
                fullfile(cPathFile{1:end-4},'com')
                'D:\dirsync\11_DIVeMB\d_main'};
            
        case {'rafrey5'} % Developer & Support
            cPathAdd = {
                fullfile(cPathFile{1:end-4},'com')
                fullfile(cPathFile{1:end-3})
                'C:\dirsync\08Helix\11d_main\com\DIVe'
                };
            
        otherwise
            % stay with local connection
            cPathAdd = {fullfile(cPathFile{1:end-3})};
    end
    
    % add defined pathes to content sources
    for nIdxPath = 1:numel(cPathAdd)
        % check availability of share
        if exist(cPathAdd{nIdxPath},'dir')
            cPath = [cPath cPathAdd(nIdxPath)]; %#ok<AGROW>
        else
            fprintf(2,'Warning: Defined share drive is not available: %s\n',cPathAdd{nIdxPath});
        end
    end
else
    % keep platform path
    cPath = {fileparts(sMP.platform.content)};
    if isfield(sMP.platform,'cPath')
        cPath = sMP.platform.cPath;
    end
end

% apply first path and create links for optional pathes
% cPath = cPath(4); % hard override for debugging purpose
fprintf(1,'Connected to Content & Configuration of: <a href="matlab:winopen(''%s'')">%s</a>\n',...
    cPath{1},cPath{1});
if ~bPathExternal
    % Display
    for nIdxPath = 2:numel(cPath)
        % display switch link on command window
        fprintf(1,['Switch to use Content & Configuration path from ' ...
            '<a href="matlab:dbcFcnBasePathSwitch(''%s'');">%s</a>\n'],...
            cPath{nIdxPath},cPath{nIdxPath});
    end
end
return