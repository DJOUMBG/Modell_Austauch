'''This script checks if the given Matlab-Path exists. 

Inputs:
-
Outputs:
-

author: Lena Goetz, Synopsys
'''

from synopsys.silver import *
import sys
import os
import time as TIME

# check if Matlab path exists
def pre_init(time):
    
    sMatlabExePath = sys.argv[1].replace("\"","")
    
    if os.path.exists(sMatlabExePath):
        logThis(ERROR_INFO, "Matlab path in DIVe_Matlab64Exe found")
        
    else:
        logThis(ERROR_ERROR, "Matlab path in DIVe_Matlab64Exe not found. Please check the defined path in the configuration tab or change the path in createSiL.bat and rebuild the sil.")
        # return DLL_ERROR  # !!! comment for workaround with island transformation
