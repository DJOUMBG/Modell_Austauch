function [release, version, description, variant] = cpc_info
% Get version info from cpc_vers.log

% Read version file
fid = fopen('cpc_vers.txt');
c = textscan(fid, '%s', 'delimiter', '\n'); % all rows
c = c{1};
fclose(fid);

% Find version information rows
description = findInfo(c, 'Description');
variant = regexp(description, '[a-zA-Z0-9]*', 'match', 'once');
version = sprintf('%s (%s)', ...
    findInfo(c, 'Software Version'), ...
    findInfo(c, 'Software Date'));
release = version(1:5);


function [s] = findInfo(c, def)
idx = find(strncmp(c, def, length(def)), 1, 'last');
idxStart = find(c{idx} == ':') + 1;
s = strtrim(c{idx}(idxStart:end));
