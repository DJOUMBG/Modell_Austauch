from subprocess import call, check_output
from glob import glob
from utilsFunctions.SetupLogging import setupLogging
import os

'''
Input: list of libraries that need to be installed

Description: check_python_libraries() installs a set of python libraries via pip from *.whl-files.
If you wish to change the libraries that are being installed, add/remove from the list "critical_module_list".

The libraries will be installed into %SILVER_HOME%\common\ext-tools\python3\Lib\site-packages


Output: checks if listed modules can be imported, if not exit()
'''

oLoggingObj = setupLogging()

oStreamLogger = oLoggingObj.setupStreamLogger('cmd_logger')

def get_module_import_line(critical_module):
    if critical_module[0] == "" or critical_module[1] == "":
        oStreamLogger.error("Import module doesn't have a name!\n")
        exit(1)
    if critical_module[2] != "":
        if critical_module[3] != "":        
            import_line =  "from {import_module} import {sub_module} as {alias}\n"
        else:
            import_line =  "from {import_module} import {sub_module}\n"
    else:
        if critical_module[3] != "":
            import_line =  "import {import_module} as {alias}"
        else:
            import_line =  "import {import_module}"
    return import_line.format(import_module=critical_module[1], sub_module=critical_module[2], alias=critical_module[3])


def check_python_libraries():
    pip_cmd_temp = "\"%SILVER_HOME%\\common\\ext-tools\\python3\\python.exe\"  -m pip install --no-index --find-links={} {}"
    
    # relative path to folder with wheel files
    rel_wheel_file_loc = r"..\..\..\python_wheels"   # relative to this script
    
    # create path to python wheel files
    sLocDir = os.path.join(os.path.dirname(__file__),os.path.normpath(rel_wheel_file_loc))
    path_modules = os.path.realpath(sLocDir)

    critical_module_list = []
    #                            pip-module, import-module, sub_module,   alias
    critical_module_list.append(["numpy",  "numpy",          "",           "np"])
    #critical_module_list.append(["lxml",   "lxml",           "etree",      "ET"])
    critical_module_list.append(["scipy",  "scipy.io",       "loadmat",    ""])
    critical_module_list.append(["psutil", "psutil",         "cpu_count",  ""])
    critical_module_list.append(["openpyxl", "openpyxl",     "",           ""])

    for critical_module in critical_module_list:
        try:     
            exec(get_module_import_line(critical_module))
            oStreamLogger.info("Successfully loaded module \"{}\".".format(critical_module[0]))
        except Exception as e:
            oStreamLogger.info(str(e) + ", trying to load package \"{}\" from folder \"{}\"".format(critical_module[0], path_modules))
            try:
                call(pip_cmd_temp.format(path_modules, critical_module[0]), shell=True)
                exec(get_module_import_line(critical_module))
                oStreamLogger.info("Successfully installed module \"{}\" from folder \"{}.".format(critical_module[0], path_modules))
            except Exception as e:        
                oStreamLogger.error(str(e) + " Error: Could not load package \"{}\" from folder \"{}\".".format(critical_module[0], path_modules))
                exit(1)
        
# check_python_libraries()