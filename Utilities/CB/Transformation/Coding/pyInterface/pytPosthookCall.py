### Posthook for DIVe CB ###

# -------------------------------------------------------------------------

# default libraries
import os
import sys

# parse input arguments
sScriptDir = sys.argv[1]

# add directory with Python modules
sys.path.append(sScriptDir)

# add Synopsys modules
import posthook

# -------------------------------------------------------------------------

# parse additional arguments
configuration_xml_file = sys.argv[2]
main_sil_name = sys.argv[3]


# create dictionary with additional arguments:
# -------------------------------------------------------------------------

# number of additional arguments
nAddArgs = (len(sys.argv) - 1) - 3

# instantly return if no additional argument
if nAddArgs < 1:
    sys.exit(0)

# get list of arguments
lArgList = sys.argv[4:len(sys.argv)-1]

# create init order model dictionary
dInitOrderModels = {}
initOrder = 1
for sSfuStr in lArgList:
    dInitOrderModels[initOrder] = sSfuStr
    initOrder = initOrder + 1

# -------------------------------------------------------------------------

# call posthook script
posthook.posthook(configuration_xml_file, main_sil_name, dInitOrderModels)
