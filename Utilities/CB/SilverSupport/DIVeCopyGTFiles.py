'''This script copies parameter.txt, signal.txt, .dat and .gtm files of required engine
variant to the Silver working directory.

Inputs:
 Path for main data variant of engine
 Path for Exhaust Piping Data Set
 Name of the DIVe configuration

Outputs:
DLL_OK - If the files are copied correctly, then continue simulation.

author: Nagaraj Ramachandra, EE, MBRDI
mail: nagaraj.ramachandra@damler.com
'''
import os
import glob
from shutil import copyfile
from synopsys.silver import *


# access simulation time
time = Variable('currentTime')

# -----------------------------
#  declare SUT interface
# -----------------------------

def get_module_interface(argv,time):
    sPathSep="\\"
    sGTIVersion = argv[1].replace("\"","")
    sStepSize = argv[2].replace("\"","")
    replacedContents = ""
    sGtiHome = os.environ['GTIHOME']
    sMexFilePath = sPathSep.join([sGtiHome,sGTIVersion,"simulink"])
    sMexFile = ""
    sCurDir = os.getcwd()
    for file in glob.glob(sMexFilePath+r"/gtsuitesl*_dp.mexw32"):
        sMexFile = file
    # DP: check working directory for existing files and store them in a textfile:
    ##############################################################################
    try:
        sExistingFiles = "existingFilesBeforeGTLoad.txt"
        filesBeforeGTLoad = os.listdir(sCurDir)
        tmpFileHandler = open(sExistingFiles, "w")
        for filename in filesBeforeGTLoad:
            tmpFileHandler.write(filename + "\n")
        tmpFileHandler.close()
    except:
        return DLL_ERROR
    ##############################################################################
    try:
        # change the step size parameters
        with open("parameter.txt") as oFile:
            contents = oFile.read()
            replacedContents = contents.replace("p[3] = 0.005","p[3] = "+sStepSize)
        with open("parameter.txt","w") as oFile:
            oFile.write(replacedContents)
        #copy gtSuitesl*.dll file needed for running GT-Suite models in Silver
        copyfile(sMexFile,sMexFile.split("\\")[-1])
    except:
        return DLL_ERROR
    return DLL_OK

def pre_init(time):
# part of the initialization API
# used in order to access and modify initial values, e.g. model parameters
    return DLL_OK

def init(time):
# part of the initialization API
# used in order to finalize initial values for simulation
    return DLL_OK

# def cleanup(time):
    # return DLL_OK

# -----------------------------
#  MainGenerator, called in each computation cycle
# -----------------------------
# def MainGenerator(*args):
    # while True:
        # yield
        