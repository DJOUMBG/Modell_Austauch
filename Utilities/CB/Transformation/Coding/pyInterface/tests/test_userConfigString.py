import re
import sys
import pdb


sUserConfig = sys.argv[1]


sUserConfig = " " + \
    sUserConfig if sUserConfig[0] != " " else sUserConfig
sUserCodeRe = r" -[a-zA-Z] "
lSplit = re.split(sUserCodeRe, sUserConfig)
pdb.set_trace()
lSplit.pop(0)
lParam = re.findall(sUserCodeRe, sUserConfig)
print(lParam)
print(lSplit)