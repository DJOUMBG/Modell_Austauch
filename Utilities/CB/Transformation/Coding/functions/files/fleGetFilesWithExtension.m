function cFileExtList = fleGetFilesWithExtension(cFileList,cExtList)

% init file list
cFileExtList = {};

% format extenions list
cExtList = upper(cExtList);

% run through all files
for nFile=1:numel(cFileList)
    
    % extension of file
    [~,~,sExt] = fileparts(cFileList{nFile});
    
    % check for valid extension
    if ismember(upper(sExt),cExtList)
       
        % append file with valid extension 
        cFileExtList = [cFileExtList;cFileList(nFile)]; %#ok<AGROW>
        
    end
    
end

end