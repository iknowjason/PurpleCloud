# Cost Analysis

## Important Information
As this tool spins up cloud resources, it will result in charges to your Azure account.  Efforts have been made to minimize the costs incurred, but the tool author is not responsible for any charges or security issues that may result from usage of this tool.  Be sure to tear down all resources when not using them.

## Cost Analysis / Pricing Estimate
As this tool spins up cloud resources, it will result in charges to your Azure subscription.  Efforts have been made to minimize the costs incurred and research the best options for most uses cases.  The best way to use this is reference the estimated cost below, check your Azure costs daily, and verify them against this information included below.  Be sure to tear down all resources when not using them.

There are other small costs associated with Azure cloud resources, but the most expensive resources by far are the Azure Virtual Machines.  When it comes to Compute VM resources, Azure is more expensive than AWS.  If you are looking to run this range in AWS, check out the sister project, BlueCloud:  https://github.com/iknowjason/BlueCloud

By default, both the Windows 10 Pro and Domain Controller are using a ```Standard_D2as_v4``` instance size, which is the lowest cost hardware that I could find which will provide sufficient performance.  The Hunting ELK SIEM system requires a scaled up Linux instance size of ```Standard_D4s_v3```.  This is because it uses HELK install option four for data science capabilities.  

Reference the Azure "Windows Virtual Machine Pricing" for the most up to date pricing:

https://azure.microsoft.com/en-us/pricing/details/virtual-machines/windows/

Reference the Azure "Linux Virtual Machines Pricing" for the most up to date pricing on the Linux VM:

https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/

Here are the defaults I've researched for this range.  Each Windows and Linux VM should approximately accrue the following with range defaults:
### Table:  Azure Accrued Costs per VM with Windows License Included
| System   |  Default Size    | Default Region |  1 day cost |  7 day cost | 30 day cost |
|----------|------------------|----------------|-------------|-------------|-------------|
| Win10Pro | Standard_D2as_v4 |     US East    |     $2.30   |   $16.10    |   $70.08    |
|    DC    | Standard_D2as_v4 |     US East    |     $2.30   |   $16.10    |   $70.08    |
|  HELK    | Standard_D4s_v3  |     US East    |     $4.60   |   $32.26    |   $140.16   |

### Changing Default VM Instance Size in ad.py
To change the default hardware instance sizes for each VM, modify the following variables in ad.py:

```
# The instance size for each system
size_win10 = "Standard_D2as_v4"
size_dc = "Standard_D2as_v4"
# Note:  Hunting ELK install options #4 requires 8 GB available memory
size_helk  = "Standard_D4s_v3"
```
