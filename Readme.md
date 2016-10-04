### LabilityBootstrap ###
<img align="right" alt="Lability logo" src="https://raw.githubusercontent.com/VirtualEngine/Lability/dev/Lability.png">

The __LabilityBootstrap__ module enables manual deployment of (virtual) machines using
[__Lability__](https://github.com/VirtualEngine/Lability) configuration data. This makes
it possible to use the same lab/testing configuration documents outside of the standard
[__Lability__](https://github.com/VirtualEngine/Lability) local Hyper-V host deployment
model; for example using VMware Workstation or Oracle VirtualBox.

[__Lability__](https://github.com/VirtualEngine/Lability) automatically injects the required certificates, file (DSC and custom)
resources and configuration files into a VM's VHD(X) file during the provisioning
process. __LabilityBootstrap__ works by creating a self-contained .ISO file containing
all the required resources with a bootstrap script. The .ISO file can then be mounted within
each (virtual) machine to manually bootstrap a node's deployment.

_Note: it is possible to manually bootstrap virtual machine in either Amazon Web Services or
Microsoft Azure!_

## Versions

### Unreleased

* Sets PowerShell console colours in Bootstrap
* Adds IsLocal resource support
* Adds elapsed time to New-IsoImage
* Implements multiple configurations in a single ISO


[__Lability__ image/logo attribution credit](https://openclipart.org/image/300px/svg_to_png/22734/papapishu-Lab-icon-1.png)
