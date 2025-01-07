"""
Contains utility methods for Dive CB process.

author: Mira Rudani, DTICI
mail: mira.rudani@daimler.com

"""

import importlib


def classFromName(sClassPath):
    """
    Import a calss from module. The sClassPath argument specifies what calss
    from what module to import in absolute or relative terms
    (e.g. either pkg.mod.CslName or ..mod.CslName).
        1. Load the module, will raise ImportError if module cannot be loaded
        2. Get the class, will raise AttributeError if class cannot be found

    Parameters:
        sClassPath (string):    Import path (e.g.'OsClasses.WindowsOSClass.windowsOsClass') .

    Example:
        oClassObj = classFromName("OsClasses.WindowsOSClass.windowsOsClass")

    Return:
        c (Class):  Imported class.

    Error:
        Raise ImportError if module cannot be loaded
        Raise AttributeError if class cannot be found

    Notes:
        author: Mira Rudani, DTICI
        mail: mira.rudani@daimler.coms
    """

    sModuleName, sClassName = sClassPath.rsplit(".", 1)

    # load the module, will raise ImportError if module cannot be loaded
    m = importlib.import_module(sModuleName)
    # get the class, will raise AttributeError if class cannot be found
    c = getattr(m, sClassName)
    return c
