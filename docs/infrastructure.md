## Infrastructure and Credentials
* **All Domain User passwords:**  Password123
* **Domain:**  RTC.LOCAL
* Local Administrator Credentials on all Windows OS Systems
  * RTCAdmin:Password123
* **Subnets**
  * 10.100.1.0/24 (Server Subnet with Domain Controller, HELK + Velociraptor)
  * 10.100.10.0/24 (waf subnet - currently reserved)
  * 10.100.20.0/24 (AD Domain Services (If Enabled))
  * 10.100.30.0/24 (User Subnet with Windows 10 Pro)
  * 10.100.40.0/24 (Linux Adversary (If Enabled)
  * 10.100.50.0/24 (db subnet - currently reserved)
* **Velociraptor + HELK Internal IP**
  * 10.100.1.5
* **Windows Server 2019**  
  * 10.100.1.4
* **HELK + Velociraptor Linux OS username**  
  * helk (Uses SSH public key auth)
* **HELK Kibana Administrator Password for https port 443**  
  * helk:hunting
* **Velociraptor GUI Administrator Password for Port 8889**  
  * vadmin:vadmin
* **Azure Active Directory**
  * Users created:  25
  * Groups created:  8
  * Applications created:  2
  * Service Principals created:  2
  * Module Directory:  /modules/azure_ad/

## Remote Access
* **Velociraptor + HELK Server:**  View contents of modules/velocihelk-vm/hosts.cfg.  The second line 
should show the IP address of the Velociraptor + HELK server that is provisioned a public IP from Azur
e.  You can SSH to the host from within that directory:
```
$ ssh -i ssh_key.pem helk@<IP ADDRESS>
```

* **Kibana GUI:**  Use the step above to get the public Azure IP address of the HELK Server.  Use Fire
fox browser to navigate to:
```
https://<IP ADDRESS>
```
* **Velociraptor GUI:**  Use the step above to get the public Azure IP address of the Velociraptor Ser
ver.  Use Firefox browser to navigate to:
```
https://<IP ADDRESS>:8889
```
* **Windows Systems:**  For remote RDP access to the Windows 2019 Server or Windows 10 Pro endpoints: 
 Change into correct modules directory and view contents of hosts.cfg.  The second line should show th
e public IP address provisioned by Azure.  Just RDP to it with local Admin credentials above.  The Win
dows Server will be located in the ```/modules/dc-vm/hosts.cfg```.  The Windows endpoints will be in t
he directory:  ```/modules/win10-vm```.  Depending on which Windows 10 module is enabled, the followin
g files will specify the public IP address for which host you are attempting to RDP into:
```
hosts-Win10-John.cfg
hosts-Win10-Lars.cfg
hosts-Win10-Liem.cfg
hosts-Win10-Olivia.cfg
```
