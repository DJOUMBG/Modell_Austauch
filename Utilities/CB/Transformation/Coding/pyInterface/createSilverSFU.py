import os, sys

# load the Silver scripting API
from synopsys.silver.remotescripting import remotesilverapi
import tempfile


# input arguments
sSfuTargetFile = sys.argv[1]
sMasterFolder = sys.argv[2]
sModuleLinesString = sys.argv[3]
sConfigParamString = sys.argv[4]
sOutputRenameParam = sys.argv[5]
sSeparatorCharacter = sys.argv[6]
sConfigIniReplaceString = sys.argv[7]
sQuotReplaceString = sys.argv[8]


# split string with separator
lModuleLine = sModuleLinesString.split(sSeparatorCharacter)
lConfigParam = sConfigParamString.split(sSeparatorCharacter)


#write an empty sil file
empty_sil = tempfile.mktemp(".sil")
hEmptySil = open(empty_sil,"w")
hEmptySil.close()


# create silver SFU object
silver = remotesilverapi.RemoteSilver(sil=empty_sil, args=[], timeout=180, stopped=True, speedup=True, gui=False)


# clear run directory
silver.clear(sMasterFolder)


# add modules with sil line
nModIdx = 0
for moduleLine in lModuleLine:
    if len(moduleLine) > 0:
        moduleLine = moduleLine.replace(sQuotReplaceString,'"')
        oModuleId = silver.add_module(index=nModIdx, sil_line=moduleLine)
        silver.set_module_property(oModuleId, 'multiply_macro_step', False)
        silver.set_module_property(oModuleId, 'macro_step_multiplier', 1)
        silver.set_module_property(oModuleId, 'divide_macro_step', False)
        silver.set_module_property(oModuleId, 'macro_step_divider', 1)
        if not(sOutputRenameParam == sQuotReplaceString):
            silver.set_module_property(oModuleId, 'output_rename_rules_file', sOutputRenameParam)
        nModIdx = nModIdx + 1


# add config parameter
for configParam in lConfigParam:
    if len(configParam) > 0:
        silver.set_config_parameter(configParam, "")


# set replacement string for config file
silver.set_project_property(name="paramsIniConfigPath", value=sConfigIniReplaceString)


# save SFU sil and close API
silver.save(sSfuTargetFile)
silver.exit(force=False)
os.remove(empty_sil)
