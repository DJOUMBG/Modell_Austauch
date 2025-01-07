"""
This file contains function to check the length of the filepath and
displays an error if length exceeds the threshold.

Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
"""

import logging
import os
import traceback

nAllowedFilePathLength = 255

oDispFileLogLogger = logging.getLogger("disp_file_log")
oPrintToLogLogger = logging.getLogger("print_to_log")


def lenCheck(file):
    """
    This function will check the length of the filepath and
    displays an error if length exceeds the threshold.

    Parameters:
        file (string):        Absolute path (system file path) of file.

    Example:
        bResult = lenCheck("D:\\Users\\test.xml")
        bResult = lenCheck("D:\\Users\\Content")

    Return:
        True:   If total number of characters in a path is not exceeds the threshold value.
        False:  If total number of characters in a path is exceeds the threshold value
                or error will get raised while checking.

    Error:
        If error will get raised this function will log
        the error message and return 'False'.

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.com
    """
    oDispFileLogLogger.debug("\tExecuting checkFileLength.py")
    oDispFileLogLogger.debug(
        "\t\tMethod lenCheck() Executed -> filepath : " + file)
    try:
        sAbsPath = os.path.abspath(file)
        if len(file) > nAllowedFilePathLength:
            oPrintToLogLogger.error("The file path is too long i.e it contains "+str(len(file))+" characters. More than " + str(
                nAllowedFilePathLength) + " characters are not allowed .\n\tPlease reduce file path ::" + sAbsPath)
            return False
        return True
    except Exception as e:
        oPrintToLogLogger.error(
            "Error while checking length of filepath : " + str(e))
        oPrintToLogLogger.error(traceback.format_exc(limit=1))
    return False
