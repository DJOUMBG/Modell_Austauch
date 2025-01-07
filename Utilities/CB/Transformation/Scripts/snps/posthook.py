import logging
import re, glob, copy
import xml.etree.ElementTree as ET
import os
from supportFcn.dispFileLog import dispFileLog, print_to_log
# necessary inputs:
# ModuleSetup
# -> corr. datasets
# -> corr. sfu

oPrintToLogLogger = logging.getLogger("print_to_log")

def posthook(configuration_xml_file, main_sil_name, dInitOrderModels):
    main_sil_name = os.path.abspath(main_sil_name)
    posthook_support = {}
    posthook_info_list = []
    sfu_list = []
    module_dict = {}
    data_dict   = {}
    global_param_log_path = "Master/globalParam.log"
    ini_global_params = {}
    ini_global_params = return_global_params(global_param_log_path)
    # gather information from config xml and support/data xml's
    config_xml = ET.parse(configuration_xml_file).getroot()
    defaultInitOrder = 0

    for module_setup in config_xml.findall(".//{*}ModuleSetup"):
        important_paths = {}
        # gather important paths into dictionary, see posthook template
        important_paths["pathRunDir"] = os.path.join(os.getcwd(), "Master")
        nInitOrder   = module_setup.get("initOrder")
        if nInitOrder == "":
            defaultInitOrder += 1
            nInitOrder = defaultInitOrder
        module       = module_setup.findall(".//{*}Module")[0]
        context_name = module.get('context')
        species_name = module.get('species')
        family_name  = module.get('family')
        type_name    = module.get('type')
        variant_name = module.get('variant')
        model_set    = module.get('modelSet')
    
        family_path = "..\\..\\Content\\" + context_name + "\\" + species_name + "\\" + family_name + "\\"
        module_xml_folder = family_path + type_name + "\\Module\\" +  variant_name

        # add module name to important_paths
        important_paths["pathModel"] = return_module_path(module_xml_folder, model_set)
        ####################################

        # get all data sets for each module
        important_paths["listPathDatasets"] = return_data_set_list(module_setup, family_path, type_name)    
        ##################################

        # get sfu name for the current module
        if (context_name != "pltm" and context_name != "human") or model_set != "open":
            sfu_name = "SFUs\\SFU_" + context_name + "_" + species_name + "_" + family_name + "_" + type_name + "_" + variant_name + "_" + model_set 
            sfu_name = sfu_name.upper() + ".sil"
        else:
            sfu_name = ""
            for dataset_path in important_paths["listPathDatasets"]:                
                sfus_found = glob.glob(dataset_path + "\\*.sil")
                inis_found = glob.glob(dataset_path + "\\*.ini")
                if len(sfus_found) > 0:
                    sfu_name = os.path.join("SFUs", os.path.split(sfus_found[0])[-1])
                    break

        important_paths["pathSFU"] = os.path.abspath(sfu_name)
        #####################################

        # get ini name for the current module and its parameters
        important_paths["dictIniParams"] = {}
        ini_name = ""
        if (context_name != "pltm" and context_name != "human") or model_set != "open":   
            ini_name =  context_name + "_" + species_name + "_" + family_name + "_" + type_name + "_" + variant_name + "_" + model_set 
            ini_name = "SFUs\\initParams\\SFU_" + ini_name.upper() + ".ini"
        else:
            for dataset_path in important_paths["listPathDatasets"]:
                sfus_found = glob.glob(dataset_path + "\\*.sil")
                inis_found = glob.glob(dataset_path + "\\*.ini")        
                if len(sfus_found) == 0 and len(inis_found) == 1:
                    ini_name = inis_found[0]
                    break
                
        if os.path.exists(ini_name):
            with open(ini_name, "r") as ini_fobj:
                for line in ini_fobj:
                    key_value = line.split("=")
                    if len(key_value) == 2:
                        key_value[0] = key_value[0].replace(" ", "")
                        key_value[1] = key_value[1].replace("\n", "")
                        key_value[1] = re.sub(r"#.*", "", key_value[1]).rstrip()
                        important_paths["dictIniParams"][key_value[0]] = key_value[1]
        else:
            important_paths["dictIniParams"][""] = "" 
        ########################################################
        
        # set global parameters from "globalParams.log"
        important_paths["dictGlobalIniParams"] = copy.deepcopy(ini_global_params)
        ###############################################
        
        init_order = int(module_setup.get("initOrder"))
        module_dict[init_order] = module


        #iterate through support sets
        posthook_support[nInitOrder] = []
        for support_set in module_setup.findall(".//{*}SupportSet"): 
            support_name = support_set.get("name")
            # filter for posthooks in support sets
            if "posthook" in support_name.lower():
                if support_set.get("level") == "family":
                    path = "..\\..\\Content\\" + context_name + "\\" + species_name + "\\" + family_name + "\\Support\\" + support_name
                elif support_set.get("level") == "type":
                    path = "..\\..\\Content\\" + context_name + "\\" + species_name + "\\" + family_name + "\\" + type_name + "\\Support\\" + support_name
                elif support_set.get("level") == "species":
                    path = "..\\..\\Content\\" + context_name + "\\" + species_name + "\\Support\\" + support_name
                posthook_support[nInitOrder].append([os.path.abspath(path), support_name + ".xml", [],  important_paths])
                path_support_xml = os.path.join(posthook_support[nInitOrder][-1][0], posthook_support[nInitOrder][-1][1]) 
                # get support script name(s)
                supportRootElem = ET.parse(path_support_xml).getroot()
                for  support_file in supportRootElem.findall(".//{*}SupportFile"): 
                    posthook_support[nInitOrder][-1][2].append(support_file.get("name"))
                ############################
            ######################################
        #############################
            
    ##############################################################
    
    # write ordered dicts into list ("handier")
    for key, value in sorted(dInitOrderModels.items()):
        if "--"  in value:
            plt_human_match = re.search(r"--[Ss][Ff][Uu] (.*).sil", value)  
            if plt_human_match:
                sfu_list.append(os.path.abspath(plt_human_match.group(1) + ".sil"))
            else:
                oPrintToLogLogger.warning("WARNING: could not add the sfu  " + value + " to posthook list.\n")
        else:
            sfu_list.append(os.path.abspath("SFUs\\" + value.upper() + ".sil"))
    
    for key, module_posthooks in sorted(posthook_support.items()):
        for module_posthook in module_posthooks:
            posthook_info_list.append(module_posthook)
    ##########################################

    #iterate through posthook support sets
    for info in posthook_info_list:
        #iterate through scripts per support sets
        for script_name in info[2]:
            script_path = os.path.abspath(os.path.join(info[0], script_name))
            oPrintToLogLogger.info("    ==========================================")
            oPrintToLogLogger.info("    executing posthook <" + script_path + ">")
            #              1           2             3             4        5         6
            code_wrapper(info[0], script_path, main_sil_name,  sfu_list, info[3], config_xml)
    oPrintToLogLogger.info("    ==========================================")
        #########################################
    ######################################
    
def return_global_params(global_param_log_path):    
    log_re = r"(.*?)\s*=\s*(.*?);"
    gather_params = {}
    if os.path.isfile(global_param_log_path):
        with open(global_param_log_path, "r") as log_fo:
            for line in log_fo:
                match_log = re.search(log_re, line)
                if match_log:
                    gather_params[match_log.group(1)] = match_log.group(2)
    else:
        pass # for now
    return gather_params
    
def return_module_path(module_xml_folder, type):
    module_xml = glob.glob(module_xml_folder + "\\*.xml")[0]
    try:
        module_xml_root = ET.parse(module_xml).getroot()
    except Exception as e:
        oPrintToLogLogger.error("in posthook, can't read module xml as it is trying to reference external resource...")
        return ""
    for module_setup in module_xml_root.findall(".//{*}ModelSet"):
        if module_setup.get("type") == type:
            for model_file in module_setup:
                if model_file.attrib["isMain"] == "1":
                    return os.path.abspath(module_xml_folder + "\\" + module_setup.attrib["type"] + "\\" + model_file.attrib["name"])
    return ""

def return_data_set_list(model_setup, family_path, type_name):
    data_set_list = []
    for sub_elem in model_setup:
        if "DataSet" in sub_elem.tag:                
            data_set = copy.deepcopy(sub_elem) 
            if   data_set.attrib["level"] == "family":
                data_set_list.append(os.path.abspath(family_path + "Data\\" + data_set.attrib["classType"] + "\\" + data_set.attrib["variant"]))
            elif data_set.attrib["level"] == "type":
                data_set_list.append(os.path.abspath(family_path + type_name + "\\Data\\" + data_set.attrib["classType"] + "\\" + data_set.attrib["variant"]))                    
    return data_set_list
#                      1           2               3             4                 5         6    
def code_wrapper(pathPosthook, pathPosthookPy, pathMainSil, listPathSFUs, dictModule, etreeCfg):
    script = ""
    with open(pathPosthookPy, "r") as s_obj:
        for line in s_obj.readlines():
            script = script + line
    # store current working dir & change wd to posthook support script folder
    current_wd = os.getcwd()    
    os.chdir(pathPosthook)
    #########################################################################
    try:
        exec(script)
    except Exception as e:
        oPrintToLogLogger.error("in " + pathPosthookPy + ", " + str(e))
    # restore original wd
    os.chdir(current_wd)
    ######################
