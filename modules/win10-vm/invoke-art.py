"""
Description:  A very simple wrapper script for ansible-playbook and Invoke-Atomic RedTeam
This script uses Ansible configuration and playbook to remote into a Windows host and run atomic tests

Author:  Jason Ostrom

Usage Examples:

Example 1:
    $ python3 invoke-art.py
    (Note:  This runs against all hosts with hosts.cfg files in working directory.  It uses a default atomic of 'T1007')

Example 2:
    $ python3 invoke-art.py -a T1009
    (Note:  This runs against all hosts with a hosts.cfg file, with a specific atomic test of T1009)

Example 3:
    $ python3 invoke-art.py -h hosts-Win10-Lars.cfg -a T1009
    (Note:  This runs against one host as defined in the hosts.cfg file, with a specific atomic test of T1009)

"""

import os
import subprocess
import argparse
import os.path
from os import path
import ipaddress 

# Variables
list1 = []
ttp_str = ""

# argparser stuff
parser = argparse.ArgumentParser(description='A wrapper for Ansible Playbook and Invoke-AtomicRedTeam')

# Add argument for atomic
parser.add_argument('-a', '--atomic', dest='atomic_test')
# Add argument for host 
parser.add_argument('-c', '--config', dest='config_file')
# parse arguments
args = parser.parse_args()

### Functions
def replace_atomic(myatomic):

    # This function will replace or over-ride the specified atomic test with the user specified
    # Change the file:  ./roles/art/tasks/main.yml
    fpath = "./roles/art/tasks/main.yml"

    if os.path.exists(fpath):
        pass
    else:
        print("[-] Error:  File not found: " + fpath)
        return -1

    replaced_content = ""

    file = open(fpath, "r")

    for line in file:

        line = line.rstrip()
        new_line= ""

        if "win_shell: powershell.exe Invoke-AtomicTest" in line:
            values = line.split()
            atomic_val = values[3]
            new_line = line.replace(atomic_val, myatomic)
            print("[+] Replaced TTP in " + fpath)
            print("    [+] Old:  " + atomic_val)
            print("    [+] New:  " + myatomic)
            replaced_content += new_line + "\n"
        else:
            replaced_content += line + "\n"

    file.close()

    write_file = open(fpath, "w")

    write_file.write(replaced_content)

    write_file.close()

    return myatomic 

def isgoodipv4(s):
    pieces = s.split('.')
    if len(pieces) != 4:
        return False
    try:
        return all(0<=int(p)<256 for p in pieces)
    except ValueError:
        return False

def get_target(hostscfg):

    fpath = hostscfg 

    if os.path.exists(fpath):
        pass 
    else:
        print("[-] Error:  File not found: " + fpath)
        return -1

    file_handle = open(fpath, 'r')

    for line in file_handle:
        retval = isgoodipv4(line)

        if retval:
            myline = line.rstrip()
            return myline 

    return False

def get_ttp(myatomic):

    # windows index file containing atomic tests
    fpath = "./art/atomic-red-team/atomics/Indexes/Indexes-CSV/windows-index.csv"

    if os.path.exists(fpath):
        pass
    else:
        print("[-] Error:  File not found: " + fpath)
        return -1

    windex = open(fpath, 'r')

    for line in windex:
        values = line.split(',')
        atomic_string = values[1]
        if atomic_string == myatomic:
            # if this is True, the atomic specified by the user exists in the Windows index file
            # Now parse the values
            tactic = values[0]
            technique_num = values[1]
            technique_name = values[2]
            test_name = values[4]
            mylist = [tactic, technique_num, technique_name, test_name]
            return mylist


def check_atomic_exists(myatomic):

    # windows index file containing atomic tests
    fpath = "./art/atomic-red-team/atomics/Indexes/Indexes-CSV/windows-index.csv"

    if os.path.exists(fpath):
        pass 
    else:
        print("[-] Error:  File not found: " + fpath)
        return -1

    windex = open(fpath, 'r')

    for line in windex:
        values = line.split(',')
        atomic_string = values[1]
        if atomic_string == myatomic: 
            # if this is True, the atomic specified by the user exists in the Windows index file
            print("    [+] Found in windows index file")
            return True

    return False


### Print introduction 
print("[+] Running invoke-art.py")

if args.atomic_test is None:
    print("[+] The -a flag for specifying an atomic test is not enabled")
    print("    [+] Using default atomic test (T1007)")
    ttp_str = "T1007"
else:
    print("[+] User specified atomic test: " + args.atomic_test)

    # Check if the atomic exists in the windows index file
    retval = check_atomic_exists(args.atomic_test)

    # Check the return value
    if retval:
        # the atomic specified by the user should exist on the remote Windows target, so proceed forward
        # replace the ansible playbook main.yml with the user specified atomic
        ttp_str = replace_atomic(args.atomic_test) 
    else:
        # The atomic specified by the user does not exist on the local repo
        # Therefore it will not exist on the remote windows target
        # Warn the user and exit
        print("    [-] The atomic test specified by the user does not exist:  " + args.atomic_test)
        print("    [-] File checked:  ./art/atomic-red-team/atomics/Indexes/Indexes-CSV/windows-index.csv")
        print("    [-] Please verify you specified the correct atomic unit test for Windows")
        exit()

    # Check if it exists in Windows index of atomic unit tests in this local repo
    # If it doesn't, warn the user and exit ~ It won't work on the remote windows target either
    # If it does, go forward, and replace the main.yml file for the non-default

all_hosts = False
if args.config_file is None:
    all_hosts = True
    print("[+] No hosts.cfg specified ~ Will be looking for all hosts")
else:
    print("[+] User specified hosts.cfg file ~ Checking")
    if path.exists(args.config_file):
        print("    [+] File found: " + args.config_file)
    else:
        print("    [-] Config file doesn't exist: " + args.config_file)
        exit()

### Check if all_hosts is True
if all_hosts:
    ### Start of Find list of hosts.cfg in working directory
    print("[+] Looking for any Ansible host.cfg files")
    files = [f for f in os.listdir('.') if os.path.isfile(f)]
    for f in files:
        startw = f.startswith('hosts-')
        endw = f.endswith('.cfg')
        if startw and endw:
            print("    [+] Enumerated:  " + f)

            ## Append to a list for later running
            list1.append(f)
else:
    list1.append(args.config_file)
### End of Find list of hosts.cfg in working directory

### Loop through the list and run
for i in list1:
    print("[+] Running invoke-art against host in file: " + i)
    target_ip = get_target(i)
    print("    [+] Target IP:  " + target_ip)
    ttp_info = get_ttp(ttp_str)
    print("    [+] Tactic: " + ttp_info[0]) 
    print("    [+] Technique Number: " + ttp_info[1]) 
    print("    [+] Technique Name: " + ttp_info[2]) 
    print("    [+] Test Name: " + ttp_info[3]) 
    result = subprocess.run(['ansible-playbook', '-i', i, "playbook-art.yml"], stdout=subprocess.PIPE)
    print (result.stdout.decode('utf-8'))

