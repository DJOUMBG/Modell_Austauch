"""
Contains utility methods for transformation process.

author: Mira Rudani, DTICI
mail: mira.rudani@daimler.com

"""

import logging
import os
import sys

import xml.etree.ElementTree as ET
from supportFcn import checkFileLength
from transformation_constants import sTerminationErrorMessage

oPrintToLogLogger = logging.getLogger("print_to_log")


def xmlTagRecursiveGeneric(i, list_, tag):
    """
    This function will find given list of tags.

    Parameters:
        i (number):
        list_ (list):
        tag (string):

    Example:
        dTagOfInterest = xmlTagRecursiveGeneric(0, lLogTagList, parent_tag)

    Return:
        List of tags.
    """

    lFinalTagList = []
    nIterCount = 0
    for oSubTag in tag:
        if list_[i][0] in oSubTag.tag:
            nIterCount = nIterCount + 1
            if i < len(list_) - 1:
                return xmlTagRecursiveGeneric(i+1, list_, oSubTag)
            elif i == len(list_) - 1:
                lFinalTagList.append(oSubTag)
            if nIterCount != 0 and nIterCount == list_[i][1]:
                break
    return lFinalTagList


def checkIfSfunForSilver(context, family, modelset):
    """
    Check if sfunc model is standard.

    Parameters:
        context(string):    Context name.
        family(string):     Family name.
        modelset(string):   Modelset name.

    Example:
        bResult = checkIfSfunForSilver(sContextName, sFamilyName, sModelSet)

    Return:
        True :  If sfunc model is standard.
        False : If sfunc model is not standard.
    """
    if context == "ctrl" and family == "sil" and "sfcn" in modelset:
        return True
    else:
        return False


def checkPathLength(sPath):
    """
    This function will check the length of the filepath and
    displays an error if length exceeds the threshold.

    Parameters:
        sPath(string):   Absolute path(system file path) of file.

    Example:
        checkPathLength(sModuleXML)

    Return:
        If length exceeds the threshold this function will log
        the error message and terminate execution of the caller script.

    Error:
        If error will get raised this function will log
        the error message and terminate execution of the caller script.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com

    """
    if not checkFileLength.lenCheck(sPath):
        oPrintToLogLogger.error("\t" + sTerminationErrorMessage)
        sys.exit(-2)


def removeFiles(files):
    """
    This function Will delete given file path or list of file paths from file system by checking its existence.

    Parameters:
        files(string or list):     Path(system file path) of a file or
                                    list of Path(system file path) of a files.

    Example:
        removeFiles('createMatFail.log')
        removeFiles(['createMatFail.log', 'createMatSuc.log'])

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
    """

    if isinstance(files, str):
        if os.path.isfile(files):
            os.remove(files)
    elif isinstance(files, list):
        for file in files:
            if os.path.isfile(file):
                os.remove(file)


def createFolder(sLocation, sFolderName='NewFolder', pathSep=os.sep):
    """
    This function will generate folder path using given location and folder name.
    Check path length of that folder.
    Create folder if not exist in file system.

    Parameters:
        sLocation(string):   Absolute path(system file path) of folder to create subfolder.

    Keyword Arguments:
        sFolderName(string):   Name of new folder.
        pathSep(string):       File path separator for current os.

    Example:
        sRbuFolder = createFolder(
            'D:\\Users\\', sFolderName="rbu", pathSep='\\')
        sRbuFolder = createFolder(
            'D:\\Users\\', sFolderName="rbu")  # Use path separator of current os.

    Return:
        Absolute path(system file path) of folder created.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
    """
    # generate folder path
    sPath = pathSep.join([sLocation, sFolderName])
    checkPathLength(sPath)
    # create folder if not exist
    if not os.path.isdir(sPath):
        os.makedirs(sPath)
    return sPath


def validateFileLocation(sFilePath, sErrorMessage=None):
    """
    Check if path is exist in file system.

    Parameters:
        sFilePath(string):        Absolute path(system file path) of file.

    Keyword Arguments:
        sErrorMessage(string):    Error message to print if file is not exist in file system.

    Example:
        validateFileLocation(
            D:\\Users\\test.xml, "Please mention valid path of configuration XML")

    Return:
        True:   If path is exist in file system.
        False:  If error message is not passed and if path is not exist in file system.

    Error:
        If error message is passed and If file is not exist in file system error will get raised, this function will log
        the error message and terminate execution of the caller script.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
    """

    if os.path.isfile(sFilePath):
        return True
    if sErrorMessage:
        oPrintToLogLogger.error(sErrorMessage)
        sys.exit(-2)
    return False


def validateDirectoryLocation(sDirectoryPath, sErrorMessage=None):
    """
    Check if path is exist in file system.

    Parameters:
        sDirectoryPath(string):   Absolute path(system folder path) of folder.

    Keyword Arguments:
        sErrorMessage(string):    Error message to print if folder is not exist in file system.

    Example:
        validateDirectoryLocation(
            'D:\\Users\\Content', 'Unable to get DIVe models. Please mention the valid DIVe DB content path')

    Return:
        True:   If path is exist in file system.
        False:  If error message is not passed and if path is not exist in file system.

    Error:
        If error message is passed and If folder is not exist in file system
        error will get raised, this function will log the error message and
        terminate execution of the caller script.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
    """
    if os.path.isdir(sDirectoryPath):
        return True
    if sErrorMessage:
        oPrintToLogLogger.error(sErrorMessage)
        sys.exit(-2)
    return False


def CheckEmptyDirectory(sDirectoryPath, sErrorMessage=None):
    """
    Check if given directory contains any file or subdirectory.

    Parameters:
        sDirectoryPath(string):   Absolute path(system file path) of folder to check.

    Keyword Arguments:
        sErrorMessage(string):    Error message to print if unable to find any file or subdirectory.

    Example:
        CheckEmptyDirectory(
            "D:\\Users\\Content", "The content path is empty. Please mention the valid DIVe DB content path")

    Return:
        True:   If file or subdirectory exist.
        False:  If error message is not passed and file or subdirectory not exist.

    Error:
        If error message is passed and If file or subdirectory not exist
        error will get raised, this function will log the error message and
        terminate execution of the caller script.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
    """

    if os.listdir(sDirectoryPath) == []:
        if sErrorMessage:
            oPrintToLogLogger.error(sErrorMessage)
            sys.exit(-2)
        return False
    return True


def parseXmlFile(sFileName, sErrorMessage="Error while parsing the XML", bGetRootElement=True):
    """
    Parse given XML file using xml package.

    Parameters:
        sFileName(string):   Absolute path(system file path) of xml file.

    Keyword Arguments:
        sErrorMessage(string):        Error message to print if unable to parse given xml file.
        bGetRootElement(boolean):    Set it as True if want to get root element of xml file.
                                        Set it as False if want to get parsed file object.
    Example:
        oConfigRootElem = parseXmlFile(
            sConfigurationXml, sErrorMessage="Error while parsing configuration xml file.")

    Return:
        Root element of xml file or parsed file object.

    Error:
        If error will get raised this function will terminate execution of the caller script.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com

    """
    try:
        oParsedFile = ET.parse(sFileName)
        return oParsedFile.getroot() if bGetRootElement else oParsedFile
    except Exception as e:
        oPrintToLogLogger.error(f"{sErrorMessage} - {sFileName}. \n {e}")
        sys.exit(-2)
        return None


def parseXmlInterfaceTagAttributes(sFileName, lLogTagList, sErrorMessage="Error while parsing the XML"):
    """
    This will parse xml file and find given tag and its attributes.

    Parameters:
        sFileName(string):        Absolute path(system file path) of xml file.
        lLogTagList(list):        List of list which contains tagname and count as sub list.

    Keyword Arguments:
        sErrorMessage(string):    Error message to print if unable to parse given xml file.

    Example:
        logSetupAttrib = parseXmlInterfaceTagAttributes(
            [["Interface", 1], ["LogSetup", 1]], lLogTagList, "Error: something went wrong parsing the xml LogSetup.")

    Return:
        dictionary which contains attribute name as key and value as value.

    Error:
        If error will get raised this function will log
        the error message and terminate execution of the caller script.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
    """

    oParsedFile = parseXmlFile(sFileName, sErrorMessage=sErrorMessage)

    dTagOfInterest = xmlTagRecursiveGeneric(
        0, lLogTagList, oParsedFile)[0]
    return dTagOfInterest.attrib
