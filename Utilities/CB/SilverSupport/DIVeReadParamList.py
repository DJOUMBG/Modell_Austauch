import sys
import os
from synopsys.silver import *
from subprocess import Popen, PIPE, STDOUT
import time as pytime

def pre_init(time):
    # input arguments
    sParamListTxt = sys.argv[1].replace("\"","")
    
    # read ParamListTxt
    with open(sParamListTxt, "r") as r_obj:
        lParamList = r_obj.read().splitlines()
    
    for line in lParamList:
        if ";" in line:
            sParam = line.split(" = ")[0]
            sValue = line.split(" = ")[1]
            
            # check if parameter is array or matrix
            if "[" in sValue:
                sValue = sValue.replace("[","")
                sValue = sValue.replace("];","")
                
                if ";" in sValue:
                    lMatrix = sValue.split(";")
                    i = 0
                    for sArray in lMatrix:
                        lArray = sArray.split(" ")
                        j = 0
                        for value in lArray:
                            sParamName = sParam + "[" + str(i) + "]" + "[" + str(j) + "]"
                            param = Variable(sParamName)
                            param.Value = float(value)
                            j+=1
                        i+=1
                else:
                    lArray = sValue.split(" ")
                    i = 0
                    for value in lArray:
                        sParamName = sParam + "[" + str(i) + "]"
                        param = Variable(sParamName)
                        param.Value = float(value)
                        i+=1
                
            else:
                value = sValue.replace(";","")
                param = Variable(sParam)
                param.Value = float(value)
            
    logThis(ERROR_INFO,"Parameter initialized")
    
    return DLL_OK