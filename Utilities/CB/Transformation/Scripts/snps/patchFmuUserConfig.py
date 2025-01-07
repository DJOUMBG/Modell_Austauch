
import logging
import re
import shutil
import subprocess
import os, sys

# unzip it in Master/delete fmu in Master
# patch userconfig(Default)
# zip it again / remove unzipped file
   
   
oPrintToLogLogger = logging.getLogger("print_to_log")

def determine_architecture_(fmu_unzipped):
    folder_name = os.path.join(fmu_unzipped, "binaries")
    for root, dirs, files in os.walk(folder_name):
        for dir in dirs:
            if "win" in dir:
                if "64" in dir:
                    return True
                elif "32" in dir:
                    return False
                else:
                    oPrintToLogLogger.error("The fmu {}.fmu has neither a 32 nor a 64 bit folder".format(fmu_unzipped))
                    sys.exit(-2)
                    
                pass

def copy_from_content_to_master(fmu_path, fmu_name):
    content_path_fmu = os.path.join(fmu_path,fmu_name)
    master_path_fmu  = os.path.abspath(fmu_name)
    shutil.copy2(content_path_fmu, master_path_fmu)                

def call_7z(fmu_name):
    store_cwd = os.getcwd()

    fmu_extract = fmu_name.replace(".fmu", "")
    cmd = "\"%SILVER_HOME%\\common\\ext-tools\\mingw\\bin\\7z.exe\" x -aoa -o\"" + fmu_extract + "\" \"" + fmu_name + "\" 2>&1"
    print(cmd)
    if os.path.isfile(fmu_name):
        subprocess.check_output(cmd, shell=True)
        os.remove(fmu_name)


def patch_user_config_string(fmu_name, user_config):
    fmu_extract = fmu_name.replace(".fmu", "")
    architecture = "64" if determine_architecture_(fmu_extract) else "32"
    user_config_default_file = "/".join([fmu_extract, "binaries", "win" + architecture, "userConfig.cfg"])
    config_content_patched = ""
    with open(user_config_default_file, "r") as fobj:
        config_content = fobj.read()        
        config_re = "userConfigDefault=(.*)\n"
        match_config = re.match(config_re, config_content)
        if match_config:
            print("user_config: ", user_config)
            config_content_patched = config_content.replace(match_config.group(1),  user_config )
    with open(user_config_default_file, "w") as fobj:
        fobj.write(config_content_patched)

def zip_fmu_again(fmu_name):
    # os.delete()
    store_cwd = os.getcwd()
    newd      = fmu_name.replace(".fmu", "")    
    os.chdir(newd)
    cmd = "\"%SILVER_HOME%\\common\\ext-tools\\mingw\\bin\\7z.exe\" a -r " + fmu_name.replace(".fmu", "") 
    subprocess.check_output(cmd, shell=True)        
    os.chdir(store_cwd)
    shutil.move(os.path.join(newd, fmu_name.replace("fmu", "7z")), fmu_name)
    shutil.rmtree(fmu_name.replace(".fmu", ""))

    
def patchFmuUserConfig(fmu_path, fmu_name, user_config):
    copy_from_content_to_master(fmu_path, fmu_name)
    call_7z(fmu_name)
    patch_user_config_string(fmu_name, user_config)
    zip_fmu_again(fmu_name)






   
   