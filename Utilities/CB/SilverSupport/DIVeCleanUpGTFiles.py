'''This script deletes the files used and created by the GT-Model. 

Inputs:
-
Outputs:
-

author: Daniel Peter, Synopsys GmbH
mail: daniel.peter@synopsys.com
'''


from synopsys.silver import *
import glob
import re
import os
import time as TIME

def remove_file(filename):
    if (os.path.exists(filename)):
        try:
            os.remove(filename)
            logThis(ERROR_INFO, "removed " + str(filename) + " successfully")
        except:
            logThis(ERROR_WARNING, "could NOT remove " + str(filename) + " successfully")

time = Variable('currentTime')

# remove gt files
def cleanup(time):
    logThis(ERROR_INFO, "clean up of gt files")
    TIME.sleep(1.0)
    # DP: check for files which existed before the load of GT-Model:
    sExistingFiles = "existingFilesBeforeGTLoad.txt"
    try:
        tmpFileHandler = open(sExistingFiles, "r")
    except:
        logThis(ERROR_WARNING, "no clean up of gt files because " + sExistingFiles + " was missed!")
        return DLL_OK
    filesToDelete = []
    filesBeforeGTLoad = []
    filesAfterGTLoad = os.listdir(os.getcwd())
    for line in tmpFileHandler:
        filesBeforeGTLoad.append(line.rstrip())
    tmpFileHandler.close()
    for fileAfterGTLoad in filesAfterGTLoad:
        fileExistedBefore = False
        for fileBeforeGTLoad in filesBeforeGTLoad:
            if fileAfterGTLoad == fileBeforeGTLoad:
                fileExistedBefore = True
        if not fileExistedBefore:
            filesToDelete.append(fileAfterGTLoad)
    # Only files with special ending are finally removed:
    lRemoveFilesWithEnding=[".dat", ".gdx", ".gtm", ".mexw32", ".msg", ".spr", ".txt"]
    # for sFileEnding in lRemoveFilesWithEnding:
        # for file in glob.glob(sFileEnding):
            # remove_file(file)
    for fileToDelete in filesToDelete:
        for sFileEnding in lRemoveFilesWithEnding:
            if re.search(sFileEnding, fileToDelete):
                remove_file(fileToDelete)
    # 2nd try:
    TIME.sleep(1.0)
    for fileToDelete in filesToDelete:
        for sFileEnding in lRemoveFilesWithEnding:
            if re.search(sFileEnding, fileToDelete):
                remove_file(fileToDelete)
    # finally remove list with existed files before GT-Load:
    remove_file(sExistingFiles)
    return DLL_OK