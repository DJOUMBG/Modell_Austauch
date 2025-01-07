''' This script checks for the version of Silver installed on the machine,
and checks if valid license is available for Silver, C Export Tool and Simulink Export Tool
Input : Integer which depicts Silver version 
    Example : If checking for Silver 3.5.10 then input is 3510
Output : String indicating the errors output to STDOUT
Author: Daniel Peter, Synopsys GmbH
email: daniel.peter@synopsys.com
Date: 13-06-2018
'''

import sys, os, re

try:
    from synopsys.internal.common import _check_silver_license
except:
    try:
        from synopsys.internal.common import _clm_checkout_license
    except:
        print ("Could not import license check function, exiting!")
        exit(1)

from subprocess import Popen, PIPE
import getSilverVersion as getSilverVersion
bIsValidSilver = True


def _checkSilverVersionOk(min_version):
    global bIsValidSilver
    flex_lm = False
    try:
        silverVersionNumber = 0
        flex_lm, silver_version_major, silver_version_minor, silver_version_bugfix = getSilverVersion.getSilverVersion()
        silverVersionNumber = float(silver_version_major + silver_version_minor + silver_version_bugfix)     

        if silver_version_major  == "0":
            bIsValidSilver = False
            return False, flex_lm
        
        if any([True for nVersion in min_version if silverVersionNumber >= nVersion]) and silverVersionNumber:
            return True, flex_lm
        else:
            return False, flex_lm

    except Exception as e:
        print("Error: ", str(e))
        bIsValidSilver = False
        return False, flex_lm


def _checkSilverLicenseOptions(lic_options, flex_lm):
    lic_codes=[]
    lic_messages=[]
    if not flex_lm:
        for lic_option in lic_options:
            (lic_codes.append(_check_silver_license(lic_option)[0]))
            (lic_messages.append(_check_silver_license(lic_option)[1]))
    else:
        for lic_option in lic_options:
            lic_codes.append(_clm_checkout_license("Silver", lic_option))
            lic_messages.append("")
        
    return lic_codes, lic_messages

def main():
    # get Silver versions with `,` seperated and in string format with "." as delimeter
    sMinVersion = sys.argv[1]
    sMinVersion = sMinVersion.strip('][').split(",")
    
    # convert dotted format string to float which is easy to compare
    min_version = list(
        map(lambda sVersion: float("".join(sVersion.split("."))), sMinVersion))

    check_version, flex_lm = _checkSilverVersionOk(min_version)
    valid_license = True
    if not flex_lm:
        check_for_lic_options = ["Silver", "C Export Tool", "Simulink Export Tool"]
    else:
        check_for_lic_options = [0]
    lic_codes=[]
    lic_messages=[]
    
    # Check Version:
    if (not check_version):
        if bIsValidSilver:
            print ("ERROR: Silver version installed on the machine is old. Recommended version are {} or above".format(sMinVersion))
        else:
            print ("ERROR: Please Check Silver Installed Properly")
        return 1
		# DP:sys.exit(1)
    else:
        # Check License:
        (lic_codes, lic_messages) = _checkSilverLicenseOptions(check_for_lic_options, flex_lm)
        sError = "ERROR: Valid Silver licenses are not found for: "
        for lic_code, lic_option in zip(lic_codes, check_for_lic_options):
            if (lic_code != 0):
                sError += (str(lic_option) + ', ')
                valid_license = False
        if not (valid_license):
            print (sError)
            return 1

    print ("Valid Silver license")
    return 0


if __name__ == '__main__':
    main()