import sys
import os
import shutil
import datetime
from synopsys.silver import *

def cleanup(time):
    sDefaultFileFormat = "csv" # used if file-extension not given within argv[1]
    bArgumentsGiven = False
    if len(sys.argv) > 1:
        oldFilepath = sys.argv[1].replace("\"","")
        bArgumentsGiven = True
        sConfigurationName = sys.argv[2].replace("\"","")
    
    # get date and time string
    oCurrentTime = datetime.datetime.now()
    timestamp = oCurrentTime.strftime("%Y%m%d_%H%M%S")

    # get path of result file
    splittedFilepath = oldFilepath.split("\\")
    oldFilename = splittedFilepath[len(splittedFilepath) - 1]
    filePath = ""
    if len(splittedFilepath) > 0:
        filePath = oldFilepath.split(oldFilename)[0]
    
    # search for signals list
    sSignalNameListFile = "pltmLogSilver.txt"
    sSilMainFolder = oldFilepath.split(os.path.join("results",oldFilename))[0]
    sOldSignalListPath = os.path.join(sSilMainFolder,"Master",sSignalNameListFile)
    
    # check if signallist does exist
    if not(os.path.exists(sOldSignalListPath)):
        logThis(ERROR_WARNING,"Signallist '" + sSignalNameListFile + "' was not found in Master folder of SiL.")
    else:
        newSignalListFilename = os.path.join(sSilMainFolder,"results",sSignalNameListFile)
        # recopy signal list
        if os.path.exists(newSignalListFilename):
            os.remove(newSignalListFilename)
        shutil.copyfile(sOldSignalListPath,newSignalListFilename)
    
    # create new paths of result file and signal list
    splittedFilename = oldFilename.split(".")
    if len(splittedFilename) > 0:
        newResultFilename = filePath + str(timestamp) + '__' +sConfigurationName + "." + sDefaultFileFormat
    if len(splittedFilename) > 1:
        newResultFilename = filePath + str(timestamp) + '__'+ sConfigurationName + "." + splittedFilename[1]
    
    # rename result file
    if bArgumentsGiven:
        if os.path.exists(newResultFilename):
            os.remove(newResultFilename)
        if os.path.exists(oldFilepath):
            os.rename(oldFilepath, newResultFilename)
            logThis(ERROR_INFO,"Create result file '"+newResultFilename+"'.")
        else:
            if os.path.exists(oldFilepath + "." + sDefaultFileFormat):
                os.rename((oldFilepath + "." + sDefaultFileFormat), newResultFilename)
                logThis(ERROR_INFO,"Create result file '"+newResultFilename+"'.")
    
    return DLL_OK