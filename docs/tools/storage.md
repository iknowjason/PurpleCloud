# Azure Storage lab 

## Overview

```$ python3 storage.py -n <NAME> -l <LOCATION>```

**Example Usage**:

```
python3 storage.py -n mystoragename -l eastus
```

Generates a terraform format HCL file for ```storage.tf``` and ```providers.tf```.

This is a great generator for quickly creating a bunch of vulnerable cloud storage resources or studying the different security permission levels.  It also builds an Azure Key Vault resources.

**Important Note:** This generator lives in the ```generators/storage``` directory.  Navigate into this directory first.
```
cd generators/storage
```

### Resources Created

* Azure Storage Account (1)
* Azure Containers (3)
The containers have three different access levels (Blob, Container, Private)
* Azure Blobs (3).  All three are uploaded to all three containers.
* Azure Shares (2)
* Two files are uploaded to the two shares
* Azure Key Vault
* Secrets (3)
* Private Keys (1)
* Certificates (1) 

### Options

Specify the resource group and name of resources with ```NAME``` and the Azure location wit ```LOCATION```.

```-n <NAME>```:  Specify a resource group name and name for other resources (Default: purplecloud-sentinel)

```-l <LOCATION>```:  Specify a different location (Default: centralus)

## Demo
A video demonstration of building a storage lab with options and illustrations.

[![Storage Demo]()](https://youtu.be/yIgKUjiTb7M "Storage Demo")
