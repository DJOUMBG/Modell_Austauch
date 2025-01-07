import sys
import os
from synopsys.silver import *
from subprocess import Popen, PIPE, STDOUT
import time as pytime

def cleanup(time):
    
    # input arguments
    sPltmPostTxt = sys.argv[1].replace("\"","")
    sResultFolder = sys.argv[2].replace("\"","")
    sMatlabExePath = sys.argv[3].replace("\"","")

    # format result folder string
    sResultFolderpath = os.path.abspath(sResultFolder)

    # format additional paths
    sMatLogFile = os.path.join(sResultFolderpath,r"logMatPostScriptExec.log")
    sDIVeCBSupportFolder = os.path.abspath(r"..\..\..\Utilities\CB\SilverSupport")
    sDIVeFunctionFolder = os.path.abspath(r"..\..\..\Function")
    
    # read PltmPostTxt
    with open(sPltmPostTxt, "r") as r_obj:
        lPltmPostScripts = r_obj.read().splitlines()
    index = 0
    for sPostFunction in lPltmPostScripts:
        sPostFunctionExt = ""
        sPostFunctionExt = sPostFunction.split(".")[1]
        index += 1
        
        #user info
        logThis(ERROR_INFO,"Execute post processing function '" + sPostFunction + "'.")
        
        # create command and run post processing script
        if sPostFunctionExt == "py":
            # create command to run python function
            sCmd = '"'+sys.executable+'"' + ' "'+sPostFunction+'"' + ' "'+sResultFolderpath+'"'
            # execute script in python
            oRunObj = Popen(sCmd, stdout=PIPE, stderr=STDOUT, text=True)
            (stdout, stderr) = oRunObj.communicate()
            nReturnCode = oRunObj.returncode
            lLogLines = stdout.splitlines()
        elif sPostFunctionExt == "m":
            # create command to run matlab function
            sCmd = '"'+sMatlabExePath+'"' + " -wait -nosplash -nodesktop -minimize -r "
            sCmd += r"cd('" + os.getcwd() + "');"
            sCmd += r"addpath(fullfile('" + sDIVeCBSupportFolder + "'));"
            sCmd += r"addpath(genpath(fullfile('" + sDIVeFunctionFolder + "')));"
            sCmd += r"executeMatlabPostScript('"+sPostFunction+"','"+sResultFolderpath+"','"+sMatLogFile+"');"
            sCmd += r"exit;"
            # execute script in matlab
            oRunObj = Popen(sCmd, stdout=PIPE, stderr=PIPE, text=True)
            (stdout, stderr) = oRunObj.communicate()
            nReturnCode = oRunObj.returncode
            # read log file
            with open(sMatLogFile, "r") as r_obj:
                lLogLines = r_obj.read().splitlines()
            # remove log file
            os.remove(sMatLogFile)
        
        # lines into string
        sOutput = "\n".join(lLogLines)
        
        # error handling
        if nReturnCode != 0:
            logThis(ERROR_ERROR,sOutput)
            return DLL_ERROR
        else:
            logThis(ERROR_INFO,sOutput)
        
    
    return DLL_OK
