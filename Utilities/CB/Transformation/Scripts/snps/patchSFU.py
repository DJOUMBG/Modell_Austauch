import logging
from string import Template
import os

oDispFileLogLogger = logging.getLogger("disp_file_log")

def patchSFU(dive_species, conf_pars, template_silfile, template_inifile, sfu_path, sfu_name):
    oDispFileLogLogger.debug("\t\tExecuting patchSFU.py")
    oDispFileLogLogger.debug("\t\t\tMethod patchSFU() executed")
    f = open(template_silfile, 'r')
    silfile = f.read();
    f.close();
    
    if (template_inifile != ""):
        f = open(template_inifile, 'r')
        inifile = f.read();
        f.close();
    
    for key in conf_pars.keys():
        conf_pars[key] = (dive_species + key)
        
    silfile = Template(silfile).safe_substitute(conf_pars) # replace keys by values
    silfile = Template(silfile).safe_substitute({"paramsIniConfigPath" : ("..\\SFUs\\configParams\\" + sfu_name + ".ini")}) # replace keys by values
    if (template_inifile != ""):
        inifile = Template(inifile).safe_substitute(conf_pars) # replace keys by values
    if "silverdll" in template_silfile.lower():
        silfile = silfile.replace("<remote-module-cluster>_</remote-module-cluster", "<remote-module-cluster>{cluster}</remote-module-cluster".format(cluster=dive_species + "_CLUSTER"))
    f = open((sfu_path + "\\" + sfu_name + ".sil"), 'w')
    f.write(silfile);
    f.close();
    
    if (template_inifile != ""):
        f = open((sfu_path + "\\configParams\\" + sfu_name + ".ini"), 'w')
        f.write(inifile);
        f.close();
        