import datetime
import os, sys
import configparser

sCbRootPath =  os.path.abspath(__file__).split("Utilities")[0]

def dispFileLog(sMessage="", bModuleInfo=False):
    bDisp = False
    nFileLog = int(os.getenv('displayLog')) if os.getenv('displayLog') else ""
    sLogFile = os.environ.get('transformationLogFile', None)
    if not nFileLog:
        config = configparser.RawConfigParser()
        config.read(sCbRootPath+r"\\Preferences\\myDIVeCB.ini")
        nFileLog = config.get("Logs","verbosity", fallback='')
        os.environ['displayLog'] = nFileLog
        nFileLog = int(nFileLog) if nFileLog else nFileLog
    if nFileLog:
        if nFileLog == 2 and bModuleInfo:
            bDisp = True
        elif nFileLog <= 2 and not bModuleInfo:
            bDisp = True
    if bDisp:
        print(sMessage)
        try:
            with open(sLogFile, 'a') as oFile:
                oFile.write("\n"+ datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') +" "+sMessage)
        except Exception as e:
            print("Error while logging to file {} -> {}".format(sLogFile, e))
            sys.exit(-2)


def print_to_log(sMessage):
    print(sMessage)
    sys.stdout.flush()
    sConfigName = os.environ.get('configName', None)
    if sConfigName:
        sLogFile = os.environ.get('log_file', None)
        try:
            with open(sLogFile, 'a') as oLog:
                oLog.write("\n"+sMessage)
        except Exception as e:
            print("Error while logging to file {} -> {}".format(sLogFile, e))
            sys.exit(-2)