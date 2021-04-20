# Infrastructure and Credentials
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

