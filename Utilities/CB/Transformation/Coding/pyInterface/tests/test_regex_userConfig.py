# -*- coding: utf-8 -*-
"""
Created on Tue Feb 28 16:18:23 2023

@author: ROHRERE
"""

import re


sUserConfig = '-a cpc_eep.par -b cpc_defaults.txt -d cpc_cds.hex -f cpc_out_def.txt -g cpc_out_val.txt -h cpc_debug.csv -i cpc_debug.txt -j 1 -W 0 -X 0 -Y 0 -Z 5555'

sUserCodeRe = r" -[a-zA-Z] "
lSplit = re.split(sUserCodeRe, sUserConfig)
lSplit.pop(0)
lParam = re.findall(sUserCodeRe, sUserConfig)




