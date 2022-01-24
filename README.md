# omsa_install.sh
Simple automated script I use to install Dell OMSA on my Dell PowerEdge R720xd and R510 servers. (might work for other series, too)

Tested on Debian-based OS's *(Debian 10, Debian 11, Ubuntu, Proxmox, etc...)*

Script will parse the Dell repo for available OMSA versions/builds and will prompt the user to select what they want.
*Note: The parsing can take up to 30 seconds... due to the Dell website, not this script.*

## Requirements:
- Git *(Needed for install and self-update to work)*

## Install:
This script is self-updating and uses Git commands to make the needed changes, therefore, it must be installed via a git clone.

`git clone https://github.com/DocDrydenn/omsa_install.git`

*(Future update will allow the user to skip the self-update function, allowing it to be "installed" and run from outside of a git clone.)*

## Usage:
```
./omsa_install.sh [-dh]

  -h | h    - Display (this) Usage Output
  -d | d    - Enable Debug (Simulation-Only)

```
## Screenshot
![omsa_install](https://user-images.githubusercontent.com/48564375/150648855-f7de1207-dba3-44bd-b927-f559f19ade5a.png)

## References
- https://linux.dell.com/repo/community/openmanage/
- https://forum.proxmox.com/threads/dell-openmanage-on-proxmox-6-x.57932/
