function bValid = fleCheckFileExtension(sFilepath,sExtStart)

% get extension of given file
[~,~,sCurExt] = fileparts(sFilepath);

% check if file starts with given extension string or not
if strncmpi(sCurExt,sExtStart,numel(sExtStart))
    bValid = true;
else
    bValid = false;
end

return