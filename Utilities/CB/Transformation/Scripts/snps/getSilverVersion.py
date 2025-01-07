from subprocess import Popen, PIPE
import re

def getSilverVersion():
    flex_lm = False
    cmd_get_silver_version = ["silversim", "--version"]
    p_get_silver_version = Popen(cmd_get_silver_version, stdout=PIPE, stderr=PIPE)
    p_get_silver_version_out = p_get_silver_version.communicate()
    p_get_silver_version_output = p_get_silver_version_out[0].decode()
    silver_version_major  = "0"
    silver_version_minor  = "0"
    silver_version_bugfix = "00"
    if p_get_silver_version_output != "":
        silver_version_split  = []
        if "-" in p_get_silver_version_output:
            silver_version_match = re.search(r"\s*[A-Z]+\D(\d+)\D(\d+).*", p_get_silver_version_output)
            if silver_version_match:
                silver_version_split.extend([silver_version_match.group(1), silver_version_match.group(2), "00"])
            flex_lm = True
        else:
            silver_version_split = p_get_silver_version_output.split(".")
            silver_version_split = [re.sub('\D', '', string) for string in silver_version_split]
        if len(silver_version_split) > 0:
            silver_version_major  = silver_version_split[0]
        if len(silver_version_split) > 1:
            silver_version_minor  = silver_version_split[1]
        if len(silver_version_split) > 2:
            silver_version_bugfix  = silver_version_split[2]
    return flex_lm, silver_version_major, silver_version_minor, silver_version_bugfix[:2]