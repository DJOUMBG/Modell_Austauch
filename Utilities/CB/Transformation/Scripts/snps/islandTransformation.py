
#    Most SFU's have parameterized content path, nothing needs to be done here.
#    Those SFUs that have hard coded content_paths are patched/edited.
#    Also accounting for the fixed "..\..\..\Utilities\.*" paths which will manually be patched to "Master" (e.g. DIVeInitialization.py)
#    User_config paths are patched in the inis themselves (-> see islandUserConfigPatch in diveConfig_transformation.py)
#    Gather all the paths from all the sil-lines (Content aswell as Utilities paths)
#    Either copytree the folders (Content paths) or copy2 the scripts/batch files (Utilities scripts/batch files)
  
#    Author   Alexei Mate, Synopsys GmbH
#    Contact: alexei.mate@synopsys.com

import logging
import os, re, glob
from string import Template
from shutil import copytree, copy2, ignore_patterns
import time

content_island = "ContentLocal"
content_old = "..\\..\\..\\Content"

oPrintToLogLogger = logging.getLogger("print_to_log")

# make island content path globally accessible to reduce maintenance
def get_island_content_name():
    return content_island

# This may be reused at another point in the code (.mat)...
def islandUserConfigPatch(old_content_path, island_flag=True):
    if island_flag:
        island_content_path = re.sub(r"[\\/\.]+Content", content_island, old_content_path)
        return island_content_path
    else:
        return old_content_path
        
def replace_double_backslashes_for_copytree(path_old):
    return path_old.replace("\\\\", "\\")
    
def replace_utilities_path(sfu_content):
    old_DIVeInit_path_re = r"([\\/\.]+Utilities.*?)\\(\w+\.[a-zA-Z]+)"
    sfu_content = re.sub(old_DIVeInit_path_re, r"\2", sfu_content)
    return sfu_content
    
def islandTransformation(s_final_sil_loc):
    oPrintToLogLogger.info("\n\t========Performing Island Transformation========")
    time.sleep(2)           # wait shortly for all the async tasks to be done
    s_cur_dir = os.getcwd()
    os.chdir(os.path.join(s_final_sil_loc, "Master"))
    ini_regex = r"(\w+)=(.*)"
    old_content_path_re = r"[\\/\.]+Content"
    content_path_par = r"_PathContent"
    old_DIVeInit_path_re = r"([\\/\.]+Utilities.*)\\(\w+\..+)"
    ini_list = glob.glob("..\\SFUs\\initParams\\*.ini")
    sfu_list = glob.glob("..\\SFUs\\*.sil")
    sfu_list_patched = dict()
    d_params = dict()
    resolved_sfu_content = []
    for ini_file in ini_list:
        ini_content = []
        with open(ini_file, "r") as ini_fobj:
            ini_content = ini_fobj.readlines()
        for line in ini_content:
            match_ini = re.search(ini_regex, line)
            if match_ini:
                param = match_ini.group(1)
                value = match_ini.group(2)
                if "user_config" in param:
                    d_params["${" + param + "}"] = islandUserConfigPatch(value)
                else:
                    d_params["${" + param + "}"] = value
        
    for sfu_file in sfu_list:
        oPrintToLogLogger.info("\t" + sfu_file)
        content_tracking = []
        with open(sfu_file, "r") as sfu_fobj:
            sfu_content = sfu_fobj.read()
            # resolve ini parameters
            for key in d_params:
                if not re.search(r"\$\{\w+\}",d_params[key]):
                    sfu_content = sfu_content.replace(key, d_params[key])
            if re.search(content_path_par, sfu_content):
                sfu_list_patched[sfu_file] = sfu_content
            if re.search(old_content_path_re, sfu_content):
                sfu_content = re.sub(old_content_path_re, content_island, sfu_content)
                sfu_list_patched[sfu_file] = sfu_content
            if re.search(old_DIVeInit_path_re, sfu_content) and sfu_file not in sfu_list_patched:                
                sfu_list_patched[sfu_file] = sfu_content
            
            resolved_sfu_content = sfu_content.split("\n")
            for sfu_line in resolved_sfu_content:
                sil_line_re = r"<sil-line>(.*)</sil-line>"
                sil_line_match = re.search(sil_line_re, sfu_line)
                if sil_line_match:
                    sil_line_content = sil_line_match.group(1)
                    sil_line_split = sil_line_content.split(" ")
                    for sub_string in sil_line_split:
                        path = sub_string.replace("&quot;", "")
                        content_or_utility = 0
                        if content_island in path:
                            content_or_utility = 1
                        elif "Utilities" in path:
                            content_or_utility = 2
                        elif "_PathContent" in path:
                            content_or_utility = 3
                        if content_or_utility == 1 or content_or_utility == 3:
                            if content_or_utility == 1:
                                content_path = path
                                content_path_old = content_path.replace(content_island, content_old)
                            elif content_or_utility == 3:
                                content_path = content_island + "\\" + path.split("\\",1)[1]
                                content_path_old = content_old + "\\" + path.split("\\",1)[1]
                            content_dir = os.path.dirname(content_path)
                            content_dir_old = os.path.dirname(content_path_old)
                            if os.path.isdir(content_dir_old):
                                if content_dir_old not in content_tracking:
                                    try:
                                        copytree(content_dir_old, content_dir, ignore=None)
                                    except Exception as e:
                                        oPrintToLogLogger.warning("Could not copy " + content_dir_old + " to " + content_island + ".")
                                        oPrintToLogLogger.error("         The reason could either be a too long path, a non existent file or something else I didn't think of.")
                                        oPrintToLogLogger.error("         " + str(e))
                            else:
                                oPrintToLogLogger.warning("The file can't be copied to "+ content_island + " as it doesn't exist.")
                            content_tracking.append(content_dir_old)
                        elif content_or_utility == 2:
                            utilities_path_old = path
                            utilities_dir_old = os.path.dirname(utilities_path_old)
                            utilities_path = replace_utilities_path(utilities_path_old)
                            utilities_dir = os.path.dirname(utilities_path)                                                        
                            if os.path.isfile(utilities_path_old) :
                                try:
                                    copy2(utilities_path_old, utilities_path)                                       
                                except Exception as e:
                                    oPrintToLogLogger.warning("Could not copy \"" + utilities_path_old + "\" to \"Master\".")
                                    oPrintToLogLogger.error("         The reason could either be a too long path, a non existent file or something else I didn't think of.")
                                    oPrintToLogLogger.error("         " + str(e))
                            else:
                                oPrintToLogLogger.warning("The file" +  utilities_path_old + "can't be copied to \"Master\" as it doesn't exist.")
                            
    # patching all paths in sfu's manually which contain fixed Content/Utilities paths, e.g. non DIVe SFU's
    for sfu_file in sfu_list_patched:
        with open(sfu_file, "w") as sfu_fobj:
            sfu_fobj.write(replace_utilities_path(sfu_list_patched[sfu_file]))
    
    
    os.chdir(s_cur_dir)
    oPrintToLogLogger.info("\t================================================")
        
        




    
    