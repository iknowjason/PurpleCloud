# Remote Access
* **Velociraptor + HELK Server:**  View contents of modules/velocihelk-vm/hosts.cfg.  The second line should show the IP address of the Velociraptor + HELK server that is provisioned a public IP from Azure.  You can SSH to the host from within that directory:
```
$ ssh -i ssh_key.pem helk@<IP ADDRESS>
```

* **Kibana GUI:**  Use the step above to get the public Azure IP address of the HELK Server.  Use Firefox browser to navigate to:
```
https://<IP ADDRESS>
```
* **Velociraptor GUI:**  Use the step above to get the public Azure IP address of the Velociraptor Server.  Use Firefox browser to navigate to:
```
https://<IP ADDRESS>:8889
```
* **Windows Systems:**  For remote RDP access to the Windows 2019 Server or Windows 10 Pro endpoints:  Change into correct modules directory and view contents of hosts.cfg.  The second line should show the public IP address provisioned by Azure.  Just RDP to it with local Admin credentials above.  The Windows Server will be located in the ```/modules/dc-vm/hosts.cfg```.  The Windows endpoints will be in the directory:  ```/modules/win10-vm```.  Depending on which Windows 10 module is enabled, the following files will specify the public IP address for which host you are attempting to RDP into:
```
hosts-Win10-John.cfg
hosts-Win10-Lars.cfg
hosts-Win10-Liem.cfg
hosts-Win10-Olivia.cfg
```
