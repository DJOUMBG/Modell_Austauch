'''This script communicates with DIVe ONE via curl

Inputs:
-
Outputs:
-

author: Elias Rohrer
'''

from synopsys.silver import *
import sys
import os
import time as TIME
from subprocess import Popen, PIPE, STDOUT


# HELP: 
#   See Utilities\CB\Transformation\Coding\classes\dveClasses\dveClassDiveOneSimState.m


# default realtime duration to wait for next heartbeat update
vRealWaitDuration = 30

# default name of DIVe ONE com data file:
#   Must be confirmed with Matlab class sfuClassStdSupport.m
#   line 1: DIVe ONE com id and token
#   line 2: DIVe ONE com locations
#   line 3: DIVe ONE curl put URL
#   line 4: DIVe ONE curl post URL
#   line 5: Simulation end time
sStdDiveOneComFileName = 'diveOneComData.txt'

# default curl system call 
sStdCurlPut  =  'curl -H "Content-Type: application/json"  -X PUT  -d '
sStdCurlPost =  'curl -H "Content-Type: application/json"  -X POST  -d '

# default curl cancel string
sStdCurlCancelString = '"isCancellationRequested":true';


# create Silver variables
t = Variable('time')


# =========================================================================
# Read file with DIVe ONE com data:
# =========================================================================

# init DIVe ONE com data strings
bIsDiveOne = False
sDiveOneComIdent = ''
sDiveOneComLocations = ''
sPutUrl = ''
sPostUrl = ''
sEndTime = ''

# check if file exists
if os.path.isfile(sStdDiveOneComFileName):
    
    # read DIVe ONE com data file
    with open(sStdDiveOneComFileName, "r") as oFileRead:
        lComDataLine = oFileRead.read().splitlines()
    
    # check number of lines
    if len(lComDataLine) >= 5:
        sDiveOneComIdent = lComDataLine[0]
        sDiveOneComLocations = lComDataLine[1]
        sPutUrl = lComDataLine[2]
        sPostUrl = lComDataLine[3]
        sEndTime = lComDataLine[4]
        bIsDiveOne = True

# get heartbeat factor
if bIsDiveOne:
    
    # convert to floating point
    vEndTime = float(sEndTime)
    
    
# =========================================================================
# Create heartbeat for DIVe ONE:
# =========================================================================

def MainGenerator(*args):
    
    # init cummulated times
    vCumSimTime = 0
    vCumRealTime = 0
    
    if bIsDiveOne:
        
        # init timer
        vSimTimeStart = t.Value
        vRealTimeStart = TIME.time()
        
        # run 
        while True:
            
            # get timer values
            vSimTimeEnd = t.Value
            vRealTimeEnd = TIME.time()
            
            # get time differences
            vSimTimeDiff = vSimTimeEnd - vSimTimeStart
            vRealTimeDiff = vRealTimeEnd - vRealTimeStart
            
            # check duration
            if vRealTimeDiff >= vRealWaitDuration:
                
                # cummulate time differences
                vCumSimTime = vCumSimTime + vSimTimeDiff
                vCumRealTime = vCumRealTime + vRealTimeDiff
                vSpeedUpFactor = vCumSimTime / vCumRealTime
                
                # get current simulation time
                vSimTime = t.Value
                
                # ---------------------------------------------------------
                
                # current put message
                sPutMessage = 'heartbeat: SimTime = ' + str(round(vSimTime,4)) + ' s  |  RealTime = ' + str(round(vCumRealTime,1)) + ' s  (SpeedUp = ' + str(round(vSpeedUpFactor,2)) + ')'
                
                # curl put message data string
                sPushMsgData = '""stateId"":2,""stateNote"":""' + sPutMessage + '""'
                
                # create curl put command
                sPutCommand = sStdCurlPut + '"{' + sPushMsgData + ',' + sDiveOneComIdent + ',' + sDiveOneComLocations + '}"  ' + sPutUrl
                
                # execute put command
                oRunPutObj = Popen(sPutCommand, stdout=PIPE, stderr=STDOUT, text=True)
                (stdout, stderr) = oRunPutObj.communicate()
                nPutReturnCode = oRunPutObj.returncode
                
                # check return code
                if nPutReturnCode != 0:
                    logThis(ERROR_WARNING, "Can not push message to DIVe ONE.")
                
                # ---------------------------------------------------------
                
                # create curl post command
                sPostCommand = sStdCurlPost + '"{' + sDiveOneComIdent + '}"  ' + sPostUrl
                
                # execute post command
                oRunPostObj = Popen(sPostCommand, stdout=PIPE, stderr=STDOUT, text=True)
                (stdout, stderr) = oRunPostObj.communicate()
                nPostReturnCode = oRunPostObj.returncode
                sPostCmdOutMsg = stdout
                
                # check return code
                if nPostReturnCode != 0:
                    logThis(ERROR_WARNING, "Can not get message from DIVe ONE.")
                
                # ---------------------------------------------------------
                
                # get returned message of curl post command
                lPostLogLines = sPostCmdOutMsg.splitlines()
                if len(lPostLogLines) > 0:
                    sLastLogLine = lPostLogLines[len(lPostLogLines)-1]
                else:
                    sLastLogLine = ''
                sLastLogLine = sLastLogLine.lower()
                
                # check if simulation was cancled via DIVe ONE
                if sLastLogLine.find(sStdCurlCancelString.lower()) > -1:
                    
                    # create cancel message
                    sCancelMsgData = '""stateId"":4,""stateNote"":""' + 'Simulation canceled by DIVe ONE user.' + '""'
                    sCancelCommand = sStdCurlPut + '"{' + sCancelMsgData + ',' + sDiveOneComIdent + ',' + sDiveOneComLocations + '}"  ' + sPutUrl
                    
                    # execute cancel command
                    oRunCancelObj = Popen(sCancelCommand, stdout=PIPE, stderr=STDOUT, text=True)
                    (stdout, stderr) = oRunCancelObj.communicate()
                    nCancelReturnCode = oRunCancelObj.returncode
                    
                    # check return code
                    if nCancelReturnCode != 0:
                        logThis(ERROR_WARNING, "Can not push cancel message to DIVe ONE.")
                    
                    # cancel simulation
                    logThis(ERROR_INFO, 'Simulation was canceled by DIVe ONE user.')
                    yield DLL_END
                
                # reset start timer
                vSimTimeStart = t.Value
                vRealTimeStart = TIME.time()
                
            yield
    
    # wait for simulation end
    while True:
        yield


# =========================================================================
# Clean up function to delete DIVe ONE com data file:
# =========================================================================

def cleanup(time):
    
    # delete file due to suppress communication if restart
    if os.path.isfile(sStdDiveOneComFileName):
        os.remove(sStdDiveOneComFileName)
