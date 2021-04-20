# Running APT Simulation Tools
This project includes three security tools to run APT simulations for generating forensic artifacts in an automated way.  Here is a quick walkthrough on the three tools that are automatically deployed.  To test efficacy of the detection solution, it is recommended to disable Windows Defender real-time protection setting.  This will allow the simulation tools to run in an environment that will allow them to fully execute, allowing you to look deeper at the forensic artifacts.

**1.  Atomic Red Team (ART)**

The Atomic Red Team scripts are downloaded from the official Github repo [5] and the Invoke-AtomicRedTeam execution framework is automatically downloaded and imported from the following repo [6].  This allows you to more easily run atomic tests and the modules are imported into the powershell session everytime you launch a powershell session.  This is controlled from the following powershell environment script:

```C:\Users\RTCAdmin\Documents\WindowsPowerShell\Microsoft.Powershell_profile.ps1```

Now that this is out of the way, let's show how to run an atomic test for ART!

**Remotely Running Atomics from Linux**

First, there is a python script that you can run to remotely invoke ART from your linux system.  It's a simple wrapper to Ansible Playbook and the location of the script is here:
```
PurpleCloud/modules/win10-vm/invoke-art.py
```
Run it like this:
```
python3 invoke-art.py
```
The script looks for all hosts.cfg files in the working directory and runs the atomic tests against all Windows 10 hosts.  If you only want to run against one of the hosts, run it with the -h flag.  For example:
```
python3 invoke-art.py -h hosts-Win10-Liem.cfg
```
Running it with the -a flag will specify an atomic.
```
python3 invoke-art.py -a T1558.003
```
The script looks for the atomic tests in windows index file:
```
/modules/win10-vm/art/atomic-red-team/atomics/Indexes/Indexes-CSV/windows-index.csv

```

**Manually Running Atomics from the Windows Endpoint**

RDP into the Windows 10 endpoint.  From a powershell session, simply run:
```PS C:\ > Invoke-AtomicTest <ATOMIC_TEST> -PathToAtomicsFolder C:\terraform\ART\atomic-red-team-master\atomics```


The atomics are in the main project directory path of ```C:\terraform\ART\atomic-red-team-master\atomics```.  Browse through them to find which atomic test you want to run.


Example of running T1007: 

```PS C:\Users\RTCAdmin> Invoke-AtomicTest T1007 -PathToAtomicsFolder C:\terraform\ART\atomic-red-team-master\atomics```

**2.  Elastic Detection Rules RTA (Red Team Attacks) scripts**

In June of 2020, Elastic open sourced their detection rules, including Python attack scripts through the Red Team Automation (RTA) project.  The following repo [7] is automatically downloaded and extracted using Terraform and Ansible scripts.  To run them, launch a cmd or powershell session and use python to run each test from the following directory:

Change into the directory:  

```C:\terraform\Elastic_Detections\detection-rules-main```

Run each python script test that you wish.  Each test is in the RTA directory and you invoke the test by removing the *.py (TTPs are referenced as a name by just removing the last *.py from the script):

```PS C:\terraform\Elastic_Detections\detection-rules-main> python -m rta <TTP_NAME>```

Example of 'smb_connection' ttp:

```PS C:\terraform\Elastic_Detections\detection-rules-main> python -m rta smb_connection```

You can browse all TTPs in the 'rta' sub-directory

**3.  APTSimulator**

The APTSimulator tool [8] is automatically downloaded.  Simply extract the Zip archive and supply the zip password of 'apt'.

```C:\terraform\APTSimulator.zip```

Invoke a cmd prompt and run the batch file script:

```C:\terraform\ATPSimulator\APTSimulator\APTSimulator.bat```
