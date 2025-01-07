import re
import os
def saveGlobalParams(pltm_sfu_par_file, pltm_sfu_par_file_target):
    global_par_re             = r".*#\s*[gG][lL][oO][bB][aA][lL]"
    from_global_par_re        = r".*#\s*[fF][rR][oO][mM][gG][lL][oO][bB][aA][lL]"
    global_name_value_re      = r"(\w+)\s*=\s*([\_\w\$\{\}]+).*"
    from_global_name_value_re = r"(\w+)\s*=\s*([\w\$\{\}\s]+).*#.*"
    array_global_pars = []
    

    with open(pltm_sfu_par_file, "r") as fobj:
        for line in fobj:
            match_global_par      = re.search(global_par_re, line)
            match_from_global_par = re.search(from_global_par_re, line)
            if match_global_par:
                match_global_name_value      = re.search(global_name_value_re, line)
                if match_global_name_value:
                    global_name  = match_global_name_value.group(1)
                    global_value = match_global_name_value.group(2)
                    array_global_pars.append([ pltm_sfu_par_file_target, "needle", global_name, global_value])

                    
            elif match_from_global_par:
                match_from_global_name_value = re.search(from_global_name_value_re, line)
                if match_from_global_name_value:
                    global_name  = match_from_global_name_value.group(1)
                    global_value = match_from_global_name_value.group(2)
                    array_global_pars.append([pltm_sfu_par_file_target, "pillow", global_name, global_value])                    

    return array_global_pars

def patchGlobalsInIni(array_global_pars):
    list_ini = {}
    for par in array_global_pars:
        if par[0] not in list_ini:
            list_ini[par[0]] = []

    for ini in list_ini:
        if os.path.isfile(ini):
            with open(ini, "r") as fobj:
                list_ini[ini] = fobj.readlines()            
        os.remove(ini)
            
    for ini in list_ini:
        new_lines = []
        
        for line in list_ini[ini]:
            fromGlobal_match = False
            # "for each line check if it starts with global/ fromGlobal param" 
            for i, par in enumerate(array_global_pars):
                # don't write to patched ini, if it matches global
                if   par[1] == "needle" and re.search("^" + par[2] + ".*#\s*[gG]", line):
                    break
                
                # write to patched ini, if it matches fromGlobal
                elif par[1] == "pillow" and re.search("^"  + par[2] + ".*#\s*[fF]", line):
                    # check if fromGlobal is set by global
                    for par2 in array_global_pars:
                        if par2[1] == "needle" and par2[2] == par[2]:
                            new_lines.append(par[2] + " = " + par2[3])
                            fromGlobal_match = True
                            break
                    # if fromGlobal is NOT set by global, take local value (#fromGlobal is cut out)                    
                    if not fromGlobal_match:
                        new_lines.append(par[2] + " = " + par[3])
                    break
               
               # if neither global nor fromGlobal just write original line to patched ini
                elif i == len(array_global_pars) - 1:
                    new_lines.append(line)
                    
        with open(ini, "w") as new_fobj:
            new_fobj.writelines(new_lines)

    
def patchGlobalInFinalSil(array_global_pars, sConfigSilName):
    # replace "<parameters/>" with following lines to sConfigSilName.sil:
    global_string = ""
    global_string = global_string + "<parameters>\n"
    for par in array_global_pars:
        if par[1] == "needle":
            global_string = global_string + "  <param>\n"
            global_string = global_string + "    <name>"  + par[2] + "</name>\n"
            global_string = global_string + "    <value>" + par[3] + "</value>\n"
            global_string = global_string + "  </param>\n"
    global_string = global_string + "</parameters>\n"
        
    with open(sConfigSilName + ".sil", 'r') as file :
        file_orig = file.read()                    
        # Patch in target string
        file_patch = file_orig.replace("<parameters/>", global_string)
        # Write the file out again
        with open(sConfigSilName + ".sil", 'w') as file:
            file.write(file_patch) 
            
    # log file to master to see which globalParameters exist, and where they originate from     
    with open("Master/globalParam.log", "w") as log_file:
        for i, par in enumerate(array_global_pars):
            fromGlobal_match = False
            if par[1] == "pillow":
                for par_2 in array_global_pars:
                    if par_2[1] == "needle" and par[2] == par_2[2]:
                        log_file.write(par[2] + " = " + par_2[3] + "; (" + par[0] + " inherits global from " + par_2[0] + ")\n")
                        fromGlobal_match = True
                        break
                if not fromGlobal_match:
                    log_file.write(par[2] + " = " + par[3] + "; (" + par[0] + ")\n")
            elif par[1] == "needle":
                log_file.write(par[2] + " = " + par[3] + "; (" + par[0] + ")\n")
    
            
            
