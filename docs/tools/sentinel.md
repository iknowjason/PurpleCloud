# Azure Sentinel lab 

```$ python3 sentinel.py -n <NAME> -l <LOCATION> -odc -adc```

This generates a terraform format HCL file for ```sentinel.tf``` and ```providers.tf```.

Specify the resource group and name of resources with ```NAME``` and the Azure location wit ```LOCATION```.

```-n <NAME>```:  Specify a resource group name and name for other resources (Default: purplecloud-sentinel)

```-l <LOCATION>```:  Specify a different location (Default: centralus)

```-odc```:  Optionally enables the Office 365 data connector for Sentinel.

```-adc```:  Optionally enables the Azure AD data connector for Sentinel.
