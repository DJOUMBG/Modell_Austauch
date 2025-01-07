# -*- coding: utf-8 -*-
"""
This package contains subfunctions required for generating SFUs. 
1. Function for generating SFU for s-function modules
2. Function for generating SFU_SUPPORT.sil
3. Function for generating SFU_LOGGING.sil
4. Function for generating SFU for GT based model
5. Function for generating SFU for FMU model
6. Function for generating SFU for Slave model

@author: nramach
email-id: nagaraj.ramachandra@daimler.com
phone: +918067686240
"""

import logging
import os
import subprocess
import sys
import zipfile
import re
import traceback
from shutil import copy
from . import patchSFU
import pdb

oDispFileLogLogger = logging.getLogger("disp_file_log")
oPrintToLogLogger = logging.getLogger("print_to_log")

def createSFUforSFunction(sCurDir,context_name,species_name,family_name,type_name,model_var,model_set,sSfupath,sSfuStr):
    oDispFileLogLogger.debug("\tProcessing {} to create SFU for SFunction".format(species_name))
    oDispFileLogLogger.debug("\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\tMethod createSFUforSFunction() exected")
    nErrorFlag = 0
    pathSep = "\\"
    sSfuStr = "SFU_"+context_name+"_"+species_name+"_"+family_name+"_"+type_name+"_"+model_var+"_"+model_set
    
    try:
        oPrintToLogLogger.info("\tGenerating SFU for "+ pathSep.join([context_name,species_name,family_name,type_name,"Module",model_var,model_set]))
        if (("w32" in model_set) or ("W32" in model_set)):
            conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : "", "_file_mexw32" : ""}
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_SFunc_32Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_SFunc_32Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        elif (("w64" in model_set) or ("W64" in model_set)):
            conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : "", "_file_mexw64" : ""}
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_SFunc_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_SFunc_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        else:
            conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : "", "_file_mexw64" : ""}
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_SFunc_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_SFunc_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
    except Exception as e:
        oPrintToLogLogger.error("SFU generation failed for s-function models")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    #check if SFU is generated
    if not os.path.isfile(sSfupath+"\\"+sSfuStr.upper()+".sil"):
        oPrintToLogLogger.error("\tSFU generation failed for s-function models because of some unexpected exceptions.")
        nErrorFlag = 1  
    return nErrorFlag

def createSFUforRBU(sSfupath,sCurDir):
    oDispFileLogLogger.debug("\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\tMethod createSFUforRBU() executed")
    nErrorFlag = 0
    conf_pars = {}
    if os.path.isfile(sSfupath+"\SFU_SUPPORT.sil"):
        os.remove(sSfupath+"\SFU_SUPPORT.sil")
    try:
        oPrintToLogLogger.info("\tGenerating SFU_SUPPORT.sil")
        patchSFU.patchSFU("", conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_SUPPORT.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_SUPPORT_configParams.ini"), sSfupath, "SFU_SUPPORT")
    except Exception as e:
        oPrintToLogLogger.error("\tSFU_SUPPORT.sil cannot be generated")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    if not os.path.isfile(sSfupath+"\SFU_SUPPORT.sil"):
        oPrintToLogLogger.error("\tSFU_SUPPORT.sil cannot be generated because of some unexpected exceptions.")
        nErrorFlag = 1
    return nErrorFlag
    
def createSFUforTemplate(sSfupath,sCurDir):
    oDispFileLogLogger.debug("\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\t\tMethod createSFUforTemplate() executed")
    nErrorFlag = 0
    conf_pars = {}
    
    if os.path.isfile(sSfupath+"\SFU_TEMPLATE.sil"):
        os.remove(sSfupath+"\SFU_TEMPLATE.sil")
    try:
        oPrintToLogLogger.info("\tGenerating SFU_TEMPLATE.sil")
        patchSFU.patchSFU("", conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_TEMPLATE.sil"), "", sSfupath, "SFU_TEMPLATE")
    except Exception as e:
        oPrintToLogLogger.error("\tSFU_TEMPLATE.sil cannot be generated")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    if not os.path.isfile(sSfupath+"\SFU_TEMPLATE.sil"):
        oPrintToLogLogger.error("\tSFU_TEMPLATE.sil cannot be generated because of some unexpected exceptions.")
        nErrorFlag = 1
    return nErrorFlag

def createSFUforFMUcs(sCurDir,sCbContentPath,model_set,model_var,type_name,family_name,species_name,context_name,sSfupath,sSfuStr):
    oDispFileLogLogger.debug("\tProcessing {} to create SFU for FMU".format(species_name))
    oDispFileLogLogger.debug("\t\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\t\tMethod createSFUforFMUcs() executed")
    pathSep = "\\"
    nErrorCheck = 0
    bFmuType32 = 0
    bFmuType64 = 0
    fmu_filelist = []
    sFmuFileName = ""
    sSfuStr = "SFU_"+context_name+"_"+species_name+"_"+family_name+"_"+type_name+"_"+model_var+"_"+model_set
    conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : "", "_file_fmu20cs" : ""}

    try:
        oPrintToLogLogger.info("\tGenerating SFU for "+ pathSep.join([context_name,species_name,family_name,type_name,"Module",model_var,model_set]))
        
        # check FMU for available model sets by looking into package
        sFmuPath = pathSep.join([sCbContentPath,context_name,species_name,family_name,type_name,"Module",model_var,model_set])
        for (sDirPath,sDirName,sFileNames) in os.walk(sFmuPath):
            for eachFile in sFileNames:
                if eachFile.endswith("fmu"):
                    sFmuFileName = pathSep.join([sFmuPath,eachFile])
        fmu_filelist = zipfile.ZipFile(sFmuFileName, 'r').namelist()
        for fmu_file in fmu_filelist:
            if ("binaries/win32" in fmu_file):
                bFmuType32 = 1
            if ("binaries/win64" in fmu_file):
                bFmuType64 = 1
        if bFmuType64 == 1:
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_FMU20CS_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_FMU20CS_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        else:
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_FMU20CS_32Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_FMU20CS_32Bit_configParams.ini"), sSfupath, sSfuStr.upper())
    except Exception as e:
        oPrintToLogLogger.error("\tSFU generation failed for FMU models")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    #check if SFU is generated
    if not os.path.isfile(sSfupath+"\\"+sSfuStr.upper()+".sil"):
        oPrintToLogLogger.error("\tSFU generation failed for FMU models because of some unexpected exceptions.")
        nErrorCheck = 1         
    return nErrorCheck

def createSFUforFMU(sCurDir,sCbContentPath,model_set,model_var,type_name,family_name,species_name,context_name,sSfupath,sSfuStr):
    oDispFileLogLogger.debug("\tProcessing {} to create SFU for FMU".format(species_name))
    oDispFileLogLogger.debug("\t\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\t\tMethod createSFUforFMU() executed")
    pathSep = "\\"
    nErrorCheck = 0
    bFmuType32 = 0
    bFmuType64 = 0
    fmu_filelist = []
    sFmuFileName = ""
    sSfuStr = "SFU_"+context_name+"_"+species_name+"_"+family_name+"_"+type_name+"_"+model_var+"_"+model_set
    conf_pars = {"_file_fmu20" : ""}

    try:
        oPrintToLogLogger.info("\tGenerating SFU for "+ pathSep.join([context_name,species_name,family_name,type_name,"Module",model_var,model_set]))
        # check FMU for available model sets by looking into package
        sFmuPath = pathSep.join([sCbContentPath,context_name,species_name,family_name,type_name,"Module",model_var,model_set])
        for (sDirPath,sDirName,sFileNames) in os.walk(sFmuPath):
            for eachFile in sFileNames:
                if eachFile.endswith("fmu"):
                    sFmuFileName = pathSep.join([sFmuPath,eachFile])
        fmu_filelist = zipfile.ZipFile(sFmuFileName, 'r').namelist()
        for fmu_file in fmu_filelist:
            if ("binaries/win32" in fmu_file):
                bFmuType32 = 1
            if ("binaries/win64" in fmu_file):
                bFmuType64 = 1
        if bFmuType64 == 1:
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_FMU20_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_FMU20_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        else:
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_FMU20_32Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_FMU20_32Bit_configParams.ini"), sSfupath, sSfuStr.upper())
    except Exception as e:
        oPrintToLogLogger.error("\tSFU generation failed for FMU models")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    #check if SFU is generated
    if not os.path.isfile(sSfupath+"\\"+sSfuStr.upper()+".sil"):
        oPrintToLogLogger.error("\tSFU generation failed for FMU models because of some unexpected exceptions.")
        nErrorCheck = 1         
    return nErrorCheck
    
def createSFUforGT(sCurDir,model_set,model_var,type_name,family_name,species_name,context_name,sSfupath,sSfuStr):
    oDispFileLogLogger.debug("\tProcessing {} to create SFU for GT".format(species_name))
    oDispFileLogLogger.debug("\t\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\t\tMethod createSFUforGT() exected")
    pathSep = "\\"
    nErrorCheck = 0
    sSfuStr = "SFU_"+context_name+"_"+species_name+"_"+family_name+"_"+type_name+"_"+model_var+"_"+model_set
    conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : ""}
    
    try:
        oPrintToLogLogger.info("\tGenerating SFU for "+ pathSep.join([context_name,species_name,family_name,type_name,"Module",model_var,model_set]))

        if (("w32" in model_set) or ("W32" in model_set)):
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_Gt_32Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_Gt_32Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        elif (("w64" in model_set) or ("W64" in model_set)):
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_Gt_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_Gt_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        else:
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_Gt_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_Gt_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
    except Exception  as e:
        oPrintToLogLogger.error("\tSFU generation failed for GT-Engine models")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    #check if SFU is generated
    if not os.path.isfile(sSfupath+"\\"+sSfuStr.upper()+".sil"):
        oPrintToLogLogger.error("\tSFU generation failed for GT Engine models because of some unexpected exceptions.")
        nErrorCheck = 1
    return nErrorCheck

def createSfuForLogging(sSfupath,sMasterFolder,sCurDir, logSetupAttrib, solverAttrib, copyToRunDir):
    oDispFileLogLogger.debug("\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\tMethod createSFUforLogging() executed")
    pathSep = "\\"
    nErrorCheck = 0
    conf_pars = {}
    sampleTypeDict  = {"MDF": "mdf", "CSV": "csv", "MAT":"mat", "ToASCII":"csv", "ToWorkspace":"mat", "Simulink":"mat", "LDYN":"mat"}
    sampleType = sampleTypeDict[logSetupAttrib["sampleType"]]
    sampleTime = logSetupAttrib["sampleTime"] # in s 
    macroStep  = solverAttrib["maxCosimStepsize"]
    if not os.path.isdir(pathSep.join([sMasterFolder,'..','results'])):
        os.mkdir(pathSep.join([sMasterFolder,'..','results']))
    if os.path.isfile(sSfupath+"\SFU_LOGGING.sil"):
        os.remove(sSfupath+"\SFU_LOGGING.sil")
    try:
        oPrintToLogLogger.info("\tGenerating SFU_LOGGING.sil")
        patchSFU.patchSFU("", conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_LOGGING.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_LOGGING_configParams.ini"), sSfupath, "SFU_LOGGING")
        ########## patch logging module sil-line #######
        sfu_name = os.path.join(sSfupath, "SFU_LOGGING.sil")
        path_log_file_base = "..\\results\\sim_logging_DIVe."
        path_log_file = path_log_file_base + sampleType
        if sampleType   == "mat":
            logging_sil_line = "matwriter.dll -a pltmLogSilver.txt -f "
        elif sampleType == "csv":
            logging_sil_line = "csvwriter.dll -l pltmLogSilver.txt -m t "
        elif sampleType == "mdf":
            path_log_file = path_log_file.replace("mdf", "mf4")
            logging_sil_line = "mdfwriter.dll -l pltmLogSilver.txt "
        else:
            oPrintToLogLogger.warning("No valid logging chosen, going with mf4.")
            path_log_file = path_log_file_base + "mf4"
            logging_sil_line = "mdfwriter.dll -l pltmLogSilver.txt "
        logging_sil_line = logging_sil_line + path_log_file 
        try:
            logging_macro_multiplier = str(max(int(float(sampleTime)/float(macroStep)), 1))
        except:
            oPrintToLogLogger.warning("Logging sampleTime cannot be converted to float, setting it to 0.1")
            logging_macro_multiplier = "10"
        template_content = ""
        patched_content  = ""
        with open(sfu_name, "r") as r_obj:
            template_content = r_obj.read()
        patched_content = template_content.replace("{logging_sil_line}", logging_sil_line).replace("123456789", logging_macro_multiplier).replace("{path_log_file}", path_log_file)
        with open(sfu_name, "w") as w_obj:
            w_obj.write(patched_content)
        #################################


    except Exception  as e:
        oPrintToLogLogger.error("\tSFU_LOGGING.sil cannot be generated")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    if not os.path.isfile(sSfupath+"\SFU_LOGGING.sil"):
        oPrintToLogLogger.error("\tSFU_LOGGING.sil cannot be generated because of some unexpected exceptions.")
        nErrorCheck = 1
    return nErrorCheck

def createSfuForPostProcessing(sSfupath,sMasterFolder,sCurDir):
    oDispFileLogLogger.debug("\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\tMethod createSfuForPostProcessing() executed")
    pathSep = "\\"
    nErrorCheck = 0
    conf_pars = {}
    if os.path.isfile(sSfupath+"\SFU_POST.sil"):
        os.remove(sSfupath+"\SFU_POST.sil")
    try:
        oPrintToLogLogger.info("\tGenerating SFU_POST.sil")
        patchSFU.patchSFU("", conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_POST.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_POST_configParams.ini"), sSfupath, "SFU_POST")

    except Exception  as e:
        oPrintToLogLogger.error("\tSFU_POST.sil cannot be generated")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    if not os.path.isfile(sSfupath+"\SFU_POST.sil"):
        oPrintToLogLogger.error("\tSFU_POST.sil cannot be generated because of some unexpected exceptions.")
        nErrorCheck = 1
    #else:
        #oDispFileLogLogger.debug("\tNo Python script for post processing - no post processing.")
    return nErrorCheck

def createSfuForSlaveModels(sExecutionTool,sCurDir,sSfupath):
    oDispFileLogLogger.debug("\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\tMethod createSFUforSlaveModels() executed")
    nErrorCheck = 0
    conf_pars = {}

    if os.path.isfile(sSfupath+"\\SFU_"+sExecutionTool+".sil"):
        os.remove(sSfupath+"\\SFU_"+sExecutionTool+".sil")
    try:
        oPrintToLogLogger.info("\nGenerating SFU_"+sExecutionTool+".sil")

        if (not ('ENV' in sExecutionTool)):
            patchSFU.patchSFU("", conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_Slave_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_Slave_64Bit_configParams.ini"), sSfupath, ("SFU_"+sExecutionTool))
        else:
            patchSFU.patchSFU("", conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_Slave_ENV_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_Slave_ENV_64Bit_configParams.ini"), sSfupath, ("SFU_"+sExecutionTool))
    except Exception as e:
        oPrintToLogLogger.error("\tSFU_"+sExecutionTool+".sil cannot be generated")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    if not os.path.isfile(sSfupath+"\\SFU_"+sExecutionTool+".sil"):
        oPrintToLogLogger.error("\tSFU_"+sExecutionTool+".sil cannot be generated because of some unexpected exceptions.")
        nErrorCheck = 1
    return nErrorCheck
        
def createSFUforOpenSilver(sCurDir,model_set,model_var,type_name,family_name,species_name,context_name,sSfupath,sSfuStr):
    oDispFileLogLogger.debug("\tProcessing {} to create SFU for OpenSilver".format(species_name))
    oDispFileLogLogger.debug("\tExecuting sfuCreation.py")
    oDispFileLogLogger.debug("\t\tMethod createSFUforOpenSilver() executed")
    nErrorFlag = 0
    pathSep = "\\"
    sSfuStr = "SFU_"+context_name+"_"+species_name+"_" + family_name+"_"+type_name+"_"+model_var+"_"+model_set
    
    try:
        oPrintToLogLogger.info("\tGenerating SFU for "+ pathSep.join([context_name,species_name,family_name,type_name,"Module",model_var,model_set]))
        if (("w32" in model_set) or ("W32" in model_set)):
            conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : "", "_file_dll_w32" : "", "_user_config" : ""}
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_SilverDLL_32Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_SilverDLL_32Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        elif (("w64" in model_set) or ("W64" in model_set)):
            conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : "", "_file_dll_w64" : "", "_user_config" : ""}
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_SilverDLL_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_SilverDLL_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
        else:
            conf_pars = {"_DIVeContext" : "", "_DIVeSpecies" : "", "_DIVeFamily" : "", "_DIVeType" : "", "_DIVeVariant" : "", "_DIVeModelSet" : "", "_PathContent" : "", "_DIVe_dataClass_initIO" : "", "_file_dll_w64" : "", "_user_config" : ""}
            patchSFU.patchSFU(species_name.upper(), conf_pars, (sCurDir+r"\templates\template_SFUs\template_SFU_SilverDLL_64Bit.sil"), (sCurDir+r"\templates\template_SFUs\template_configParams\template_SFU_SilverDLL_64Bit_configParams.ini"), sSfupath, sSfuStr.upper())
    except Exception as e:
        oPrintToLogLogger.error("\tSFU generation failed for Open-Silver models")
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
        nErrorFlag = 1
        return nErrorFlag
    #check if SFU is generated
    if not os.path.isfile(sSfupath+"\\"+sSfuStr.upper()+".sil"):
        oPrintToLogLogger.error("\tSFU generation failed for Open-Silver models because of some unexpected exceptions.")
        nErrorFlag = 1  
    return nErrorFlag