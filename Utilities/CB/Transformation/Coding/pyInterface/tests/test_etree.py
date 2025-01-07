import os
import sys
import xml.etree.ElementTree as ET
# necessary inputs:
# ModuleSetup
# -> corr. datasets
# -> corr. sfu


configuration_xml_file = sys.argv[1]

posthook_support = {}
posthook_info_list = []
sfu_list = []
module_dict = {}
data_dict   = {}
global_param_log_path = "Master/globalParam.log"
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
        
        
        
        
