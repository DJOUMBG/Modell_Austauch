close all
clear
clc

%% preferences

% folder with configs
sConfigFolder = 'D:\DIVe\dac_main\Configuration\Vehicle_Truck3D\D4A';


%% program

% get config files
cConfigFiles = fleFilesGet(sConfigFolder,{'.xml'});

% read files
for nFile=1:numel(cConfigFiles)
    
    sFile = cConfigFiles{nFile};
    sFilepath = fullfile(sConfigFolder,sFile);
    
    xConfig = dsxRead(sFilepath,0,0);
    
    xSetups = xConfig.Configuration.ModuleSetup;
    
    fprintf(1,'CONFIG\t%s:\n',sFile);
    
    % setups
    xMec3dSet = struct([]);
    for nSet=1:numel(xSetups)
        
        sModuleName = xSetups(nSet).name;
        
        if strcontain(sModuleName,'mec3d')
            xMec3dSet = xSetups(nSet);
            break;
        end
        
    end
    
    % check 
    if ~isempty(xMec3dSet)
        
        % module
        if isfield(xMec3dSet,'Module')
            xModule = xMec3dSet.Module;
            if isfield(xModule,'type') && isfield(xModule,'variant')
                fprintf(1,'\t\t%s: %s\n',xModule.type,...
                            xModule.variant);
            else
                fprintf(2,'\t\tNo fields type or variant in mec3d\n');
            end
        else
            fprintf(2,'\t\tNo field Module in mec3d\n');
        end
        
        % data set
        if isfield(xMec3dSet,'DataSet')
            xDataSetList = xMec3dSet.DataSet;
            if isfield(xDataSetList,'classType') && isfield(xDataSetList,'variant')
                
                % DataSets
                bHasSteer = false;
                for nDat=1:numel(xDataSetList)
                    xDataSet = xDataSetList(nDat);
                    if strcontain(xDataSet.classType,'steer')
                        fprintf(1,'\t\t%s = %s\n',xDataSet.classType,...
                            xDataSet.variant);
                        bHasSteer = true;
                        break;
                    end
                end
                
                % check steer DataSet
                if ~bHasSteer
                    fprintf(2,'\t\tNo steer DataSet in mec3d\n');
                end
                
            else
                fprintf(2,'\t\tNo fields classType or variant in mec3d DataSet\n');
            end
            
        else
            fprintf(2,'\t\tNo DataSets in mec3d\n');
        end
        
    else
        fprintf(2,'\t\tNo mec3d module\n');
    end
    
end
