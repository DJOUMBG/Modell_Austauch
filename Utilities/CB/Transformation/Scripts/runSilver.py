"""
1. Import silver APIs.
2. Validate license availability for silver FlexLM/dedicated.
3. Check if there is a valid license or terminate the process with error.
4. Invokes and configures silver with user preferences.
5. Based on the tTimeOut option selected it will run for infinite or defined time.
6. If Configuration sil file is not found it will exit with error message
    'Please pass the Configuration sil file'.
"""

import os
import sys
import argparse
from time import time, sleep
from synopsys.silver.remotescripting import remotesilverapi

bFlexLM = False
try:
    from synopsys.internal.common import _check_silver_license
except:
    try:
        from synopsys.internal.common import _clm_checkout_license
        bFlexLM = True
    except:
        print ("Could not import license check function, exiting!")
        exit(1)


oParser = argparse.ArgumentParser()
oParser.add_argument("sSilFilePath", help="The path of configuration SIL")
oParser.add_argument("bGui", nargs='?', default=True, help="True/False")
oParser.add_argument("bStopped", nargs="?", default=False, help="True/False")
oParser.add_argument("tTimeOut", nargs="?", default="", help="time to run silver simulation in sec")
oArgs = oParser.parse_args()
sSilverFile = oArgs.sSilFilePath
bGui = oArgs.bGui
bStopped = oArgs.bStopped
tTimeOut = oArgs.tTimeOut
# inf : infinite
if oArgs.tTimeOut and not oArgs.tTimeOut == 'inf':
    tTimeOut = int(tTimeOut)
elif not oArgs.tTimeOut:
    tTimeOut = ""
else:
    tTimeOut = 'inf'
dSilverOptions = {}
if sSilverFile:
    # Checking Silver License
    if bFlexLM:
        error_code              = _clm_checkout_license("Silver", 0) # network pool
    else:
        [error_code, message]   = _check_silver_license('Silver')# local

    # Check if generally there is a valid license
    if error_code != 0 :
        print('You dont have valid silver license')
        sys.exit(-2)

    dSilverOptions["sil"] = sSilverFile
    dSilverOptions["speedup"] = True
    if not bGui in ["True", True]:
        dSilverOptions['timeout'] = 180
        dSilverOptions['gui'] = False
        bGui = False
    else:
        dSilverOptions['timeout'] = (time() + (10 * 365 * 24 * 60 * 60)) # setting unlimited time
    if bStopped in [True, "True"]:
        dSilverOptions['stopped'] = True
        # silver = remotesilverapi.RemoteSilver(sil=sSilverFile, speedup=True)
    # invoke silver
    oSilver = remotesilverapi.RemoteSilver(**dSilverOptions)
    if not oSilver.started_successfully():
        print('Failed: Silver did not start successfully!')
        oSilver.exit()
    # set time
    if not tTimeOut == 'inf' and tTimeOut:
        try:
            bStatus = oSilver.run_for(int(tTimeOut))
            if bStatus:
                print("SUCCESS: DIVe CB Transformation completed.Simulation Completed")
        except Exception as e:
            print("Failed: Unable to run the simulation")
            print("Exception: "+ str(e))
        oSilver.exit()
    # run infinitely
    elif tTimeOut == 'inf':
        oSilver.run()
        # if silver is keep running code will sleep
        while oSilver.started_successfully():
            sleep(2)
        # If silver simulation stops by module exit the silver
        while not oSilver.started_successfully():
            oSilver.exit()
            break
    sys.exit()
else:
    print("Please pass the Configuration sil file")
    sys.exit()
