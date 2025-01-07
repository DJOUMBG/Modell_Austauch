# -*- coding: utf-8 -*-
"""
Created on Tue Feb 28 16:18:23 2023

@author: ROHRERE
"""

dSfcnModelandStatus = dict()

sModelName = 'hallo'

dSfcnModelandStatus.setdefault(sModelName, False)

#print(dSfcnModelandStatus[sModelName])

dSfcnModelandStatus[sModelName] = True

print(dSfcnModelandStatus[sModelName])


A = dSfcnModelandStatus.get(sModelName, None)

B = None


## 

dExeToolInitOrder = dict()
dExeToolInitOrderModified = dict()
dExeToolInitOrder.setdefault("Simulink", [])
dExeToolInitOrder.setdefault("Simulink_ENV", [])

dExeToolInitOrder["Simulink"].append(5)
dExeToolInitOrder["Simulink"].append(6)

dExeToolInitOrderModified = {k: v for k, v in dExeToolInitOrder.items() if len(v) != 0}




