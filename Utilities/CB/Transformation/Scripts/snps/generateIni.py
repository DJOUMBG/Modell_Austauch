# -*- coding: utf-8 -*-
import logging
import os
import xml.etree.ElementTree as ET
import zipfile, re
import supportFcn.checkFileLength as checkFileLength
import sys
import pdb
import traceback
from snps import (patchFmuUserConfig,islandTransformation)
from utilsFunctions.utils import checkPathLength

oDispFileLogLogger = logging.getLogger("disp_file_log")
oPrintToLogLogger = logging.getLogger("print_to_log")

def generate_ini(dSfcnModelandStatus,configRootElem,sPathDiveDbContent,SilFileLoc,sRbuFolder,sConfigName,sGtSuiteVer,nCheckForSignals, bIslandFlag, sMatlabRoot):
    """
        This function creates following file
        1. INI file for final SIL generation which contains parameters and values which will be replaced in
            final SIL file
        2. CFG file which is used for SFU file generation

        author: Nagaraj Ramachandra, EE, MBRDI
        mail: nagaraj.ramachandra@damler.com
    """
    

    oDispFileLogLogger.debug("\tExecuting generateIni.py")
    oDispFileLogLogger.debug("\t\tMethod generate_ini_from_silver_4_0() executed")
    try:
        pathSep="\\"
        #current working directory
        sCurDir = os.getcwd()
        #DIVe-Root-Directory:
        sDIVeRootDir = pathSep.join([sCurDir,"..\..\..\.."])
        #change to DIVe-Root
        os.chdir(sDIVeRootDir)
        sDiveContentPathRelToSilToolkit = os.path.relpath(sPathDiveDbContent)
        os.chdir(sCurDir)

        silverIniFilePath =pathSep.join([sCurDir,"..\..\..\..\SiLs",sConfigName])
        checkPathLength(os.path.realpath(silverIniFilePath))
        if not os.path.isdir(silverIniFilePath):
            os.makedirs(silverIniFilePath)
        
        #if path to store Ini file does not exist.
        if not os.path.isdir(silverIniFilePath):
            os.mkdir(silverIniFilePath)
        
        #final sil file destination
        sFinalSilLoc = SilFileLoc+"\\Master"
        sFinalSilIniLoc = SilFileLoc + "\\SFUs\\initParams\\"
        sContentIsland = sFinalSilLoc + "\\" + islandTransformation.get_island_content_name()
        checkPathLength(sFinalSilLoc)
        checkPathLength(sFinalSilIniLoc)
        checkPathLength(sContentIsland)
        #if path to store Ini file does not exist.
        if not os.path.isdir(sFinalSilLoc):
            os.mkdir(sFinalSilLoc)
        if not os.path.isdir(sFinalSilIniLoc):
            os.mkdir(sFinalSilIniLoc)
        # content path relative to Master
        contentPathRelToMaster = "${DIVe_ContentPath}"
        
        if (nCheckForSignals == 0):
            sSFUIniFilePath = sFinalSilIniLoc + "SFU_LOGGING.ini"
            checkPathLength(sSFUIniFilePath)
            hSFUIniFile = open(sSFUIniFilePath, "a")
            hSFUIniFile.writelines("# LOGGING")
            hSFUIniFile.writelines("\nRBU_DIVe_configuration="+sConfigName)
            hSFUIniFile.close()
        
        sSFUIniFilePath = sFinalSilIniLoc + "SFU_POST.ini"
        checkPathLength(sSFUIniFilePath)
        hSFUIniFile = open(sSFUIniFilePath, "a")
        hSFUIniFile.writelines("# POSTPROCESSING")
        hSFUIniFile.writelines("\nSFU_Matlab64Exe=${DIVe_Matlab64Exe}")
        hSFUIniFile.close()
            
        sSFUIniFilePath = sFinalSilIniLoc + "SFU_SUPPORT.ini"
        checkPathLength(sSFUIniFilePath)
        hSFUIniFile = open(sSFUIniFilePath, "a")
        hSFUIniFile.writelines("# SUPPORT")
        hSFUIniFile.writelines("\nDIVeInitIOPaths=")
        hSFUIniFile.writelines("\nSFU_Matlab64Exe=${DIVe_Matlab64Exe}")
        hSFUIniFile.close()
        
        # First parse the configuration files for the modules specified
        root_config = configRootElem #ET.parse(configuration_xml).getroot()
        # Get Master Solver step size from the config XML
        nMasterSolver = root_config.findall(".//{*}MasterSolver")[0].get("maxCosimStepsize")
        
        #change to Sil file destination
        os.chdir(sFinalSilLoc)
        
        # for every module setup generate sil lines in SIL file
        for module_setup in root_config.findall(
                ".//{*}ModuleSetup"):
            context_name = ''
            species_name = ''
            family_name = ''
            type_name = ''
            model_var = ''
            bSfcnAsOpen = False
            sModelname = module_setup.get('name')
            oDispFileLogLogger.debug("Processing {}".format(sModelname))
            for module in module_setup.findall(
                    ".//{*}Module"):
                context_name = module.get('context')
                species_name = module.get('species')
                family_name = module.get('family')
                type_name = module.get('type')
                model_var = module.get('variant')
                model_set = module.get("modelSet")
                sSFUIniFilePath = sFinalSilIniLoc + "SFU_"+context_name.upper()+"_"+species_name.upper()+"_"+family_name.upper()+"_"+type_name.upper()+"_"+model_var.upper()+"_"+model_set.upper() + ".ini"
                checkPathLength(sSFUIniFilePath)
                hSFUIniFile = open(sSFUIniFilePath, "a")
                hSFUIniFile.write("# Comment: for %s\n\
    %s_PathContent=%s\n\
    %s_DIVeContext=%s\n\
    %s_DIVeSpecies=%s\n\
    %s_DIVeFamily=%s\n\
    %s_DIVeType=%s\n\
    %s_DIVeVariant=%s\n\
    %s_DIVeModelSet=%s\n" %(species_name.upper(),
        species_name.upper(),contentPathRelToMaster,
        species_name.upper(),context_name,
        species_name.upper(),species_name,
        species_name.upper(),family_name,
        species_name.upper(),type_name,
        species_name.upper(),model_var,
        species_name.upper(),model_set))
        
                bOpenSilver = False
                if ((model_set == "silver_dll_w32") or (model_set == "silver_dll_w64")):
                    bOpenSilver = True
                    # resolve the path to module XML
                    moduleXML = pathSep.join([sPathDiveDbContent,context_name,species_name,family_name,type_name,"Module",model_var, model_var + ".xml"]) 
                    checkPathLength(moduleXML)
                    try:
                        root_module = ET.parse(moduleXML).getroot()
                    except:
                        oPrintToLogLogger.error("\nCould not locate module XML "+moduleXML)
                        continue
                    # 13.02.2020, DP: take name of dll from xml-file, use traditional naming (species_family_type.dll) if not found:
                    ################################################################################################################
                    for modelSetEle in root_module.findall(
                        ".//{*}ModelSet"):
                        if ((model_set == "silver_dll_w32") and (modelSetEle.get("type") == "silver_dll_w32")):
                            sFilenameSilverDll = species_name+"_"+family_name+"_"+type_name
                            # check for module name (name of dll):
                            for modelFileEle in modelSetEle.findall(".//{*}ModelFile"):
                                if ((modelFileEle.get("isMain")=="1") and (modelFileEle.get("name").endswith(".dll"))):
                                    sFilenameSilverDll = modelFileEle.get("name")[0:-4]
                            # write to ini file
                            hSFUIniFile.write("%s_file_dll_w32=%s\n"%(species_name.upper(),(sFilenameSilverDll)))
                        elif ((model_set == "silver_dll_w64") and (modelSetEle.get("type") == "silver_dll_w64")):
                            sFilenameSilverDll = species_name+"_"+family_name+"_"+type_name
                            # check for module name (name of dll):
                            for modelFileEle in modelSetEle.findall(".//{*}ModelFile"):
                                if ((modelFileEle.get("isMain")=="1") and (modelFileEle.get("name").endswith(".dll"))):
                                    sFilenameSilverDll = modelFileEle.get("name")[0:-4]
                            # write to ini file
                            hSFUIniFile.write("%s_file_dll_w64=%s\n"%(species_name.upper(),(sFilenameSilverDll)))
                    ################################################################################################################
                        
                        
                # If modelset is sfcn which has to be handled as open due to lack of parameter then proceed with next module
                if "sfcn" in model_set and sModelname in dSfcnModelandStatus:
                    if dSfcnModelandStatus[sModelname]:
                        bSfcnAsOpen = True
                        
                #if modelSet is open then proceed to next module
                if model_set == "open" and not bOpenSilver or bSfcnAsOpen:
                    for dataSetElem in module_setup.findall(".//{*}DataSet[@className='initIO']"):
                        # hIniFile.write("%s_DIVe_dataClass_initIO=%s\n"%(species_name.upper(),dataSetElem.get('variant')))
                        hSFUIniFile.write("%s_DIVe_dataClass_initIO=%s\n"%(species_name.upper(),dataSetElem.get('variant')))
                    #------ no need of other INI parameters in case of open modelSet. So break out of the loop ----#
                    continue
                
                for dataSetElem in module_setup.findall(".//{*}DataSet[@className='initIO']"):
                    hSFUIniFile.write("%s_DIVe_dataClass_initIO=%s\n"%(species_name.upper(),dataSetElem.get('variant')))

            #-----------------If ModeSet is FMU -------------------------#
            if model_set=="fmu10" or model_set=="fmu20":
                sFmuPath = pathSep.join([sPathDiveDbContent,context_name,species_name,family_name,
                                    type_name,"Module",model_var,model_set])
                sFmuFileName = ""
                checkPathLength(sFmuPath)
                for (sDirPath,sDirName,sFileNames) in os.walk(sFmuPath):
                    for eachFile in sFileNames:
                        if eachFile.endswith("fmu"):
                            sFmuFileNamePath = pathSep.join([sFmuPath,eachFile])
                            sFmuFileName=eachFile
                            break
                try:
                    sFmuFileNameRelative = os.path.relpath(sFmuFileName)
                    if sFmuFileName.find("fmu")!=-1:                                                        # this should also distinguish between 32 bit and 64 bit...
                        if context_name == "ctrl" and family_name == "sil":
                            hSFUIniFile.write("%s_file_fmu20=%s\n"%(species_name.upper(),(sFmuFileName)))
                        else:
                            hSFUIniFile.write("%s_file_fmu20cs=%s\n"%(species_name.upper(),(sFmuFileName)))
                        
                        
                except:
                    oPrintToLogLogger.error("\nCannot find specified path "+os.path.abspath(sFmuFileNameRelative))
            #-----------end of condition for FMU modelset-----------------#
                
            #----------------if model set is s-function-------------------#
            if model_set!="open" and model_set!="fmu10" and model_set!="fmu20" and not bOpenSilver:  # rechtsa 06.12.2019
                #if the module is GT suite engine module
                if species_name == 'eng' and family_name == 'detail' and type_name == 'gtfrm':
                    hSFUIniFile.write("ENG_DIVe_StepSize=0.005\n")
                    hSFUIniFile.write("GtSuiteVer=" + sGtSuiteVer + "\n")
                
                else:
                    #get the sFunc file path
                    sFuncFilePath = pathSep.join([sPathDiveDbContent,context_name,species_name,family_name,
                                        type_name,"Module",model_var,model_set])
                    
                    sFuncFileName = ""
                    for (sDirPath,sDirName,sFileNames) in os.walk(sFuncFilePath):
                        for eachFile in sFileNames:
                            if eachFile.endswith("mexw32") or eachFile.endswith("mexw64"):
                                sFuncFileNamePath = pathSep.join([sFuncFilePath,eachFile])
                                sFuncFileName=eachFile
                                break
                    try:
                        if sFuncFileName.find("mexw64")!=-1:
                            hSFUIniFile.write("%s_file_mexw64=%s\n"%(species_name.upper(),(sFuncFileName)))
                        else:
                            hSFUIniFile.write("%s_file_mexw32=%s\n"%(species_name.upper(),(sFuncFileName)))                    
                        
                        sFuncFileName = os.path.relpath(sFuncFileNamePath)
                        
                        #pdb.set_trace()  
                    except:
                        oPrintToLogLogger.error("\nCannot find specified path "+sFuncFileNamePath)
            #----------------End of condition for s-function modules ------------
                hSFUIniFile.close()
        os.chdir(sCurDir)
        return True
    except Exception as e:
        oPrintToLogLogger.error("Error while generating INI file for final SIL generation.")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        sys.exit(-2)
