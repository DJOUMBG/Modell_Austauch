function dexUniplotCollect(sPath)

% read sources
xSource = uniread(fullfile(sPath,'MVA_collectAll.mat'));
xMM = uniread(fullfile(sPath,'MARC_MultimediaFileMerge.asc'));

% combine sources
xSource(1).subset(1).data.name = [xSource(1).subset(1).data.name xMM(1).subset(1).data.name];
xSource(1).subset(1).data.value = [xSource(1).subset(1).data.value xMM(1).subset(1).data.value];

% write tdl/uxx file
[sTrash,sFolder] = fileparts(sPath);
sName = regexp(sFolder,'(?<=^\d+_\d+_)\w+(?=_\w+$)','match','once');
spsUxxWrite(xSource,fullfile(sPath,[sName '.asc']));

end

