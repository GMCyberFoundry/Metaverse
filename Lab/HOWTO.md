# Lab

## Overview

This document details the process of creating the system detailed in the accompanying paper.
It is intended to be complete.
It is a how to guide.

### Summary of software

Summarise the software and functionality 

## Prerequisites

Ensure that the BIOS / firmware / etc of the hardware you intend to use is up to date.

## Network details

In the example setup provided here there are currently two networks:

1. The virtual server resides in a LAN with the following details:

192.168.x.0/24

Replace x with an integer between 0 and 254

This LAN has a gateway to the Internet and DNS server configured. Of course, it could be replaced with a direct connection to the Internet, though for research and development purposes it is often better to work within a clean LAN and manage access to the Internet as required.

2. There is a virtual network configured on the virtual machine host upon which virtual machines can reside:

This virtual network is not configured to bridge with the physical network adapter rather a virtual machine is configured as a gateway to route IP traffic through. This provides a level of isolation. More on this later (@todo).

## Server configuration

### Server hardware details

@todo

### Disk configuration details

@todo

## Proxmox VE

### Installation and configuration

Version used: 7.1

Keep in mind that this setup uses the Proxmox VE installer (https://www.proxmox.com/en/proxmox-ve/get-started) which, as noted on the site, is a bare-metal installer and will erase all data on at least one disk. There are alternative methods to install Proxmox VE but these are not covered here.

A brief summary of the steps taken using Proxmox VE 7.1:

#### Dialogue 1

Choose the target harddisk (/dev/sda in this case).

#### Dialogue 2

Select country, time zone, keyboard layout.

#### Dialogue 3

Set a password (this is the root password, see proxmox hardening section), and email address.

#### Dialogue 4

Select a Network Interface Card (NIC) on which the management interface will be available and provide a hostname, IP address, gateway and DNS server.

In this example the following settings were used:

Hostname: proxmoximus.local
IP address: 192.168.x.220 / 24
Gateway: 192.168.x.254
DNS server: 192.168.x.254

Either replace x with the integer used earlier and update the last octet of the gateway and server with that that corresponds to your setup (assuming the setup is local and has a local dns server or forwarder) or configure the values according to your intended setup.

Once the install has completed and the system has rebooted it is time to begin configuring. This is done (almost entirely) via the web interface, in this case, available at https:// proxmoximus | 192.168.x.220 : 8006

It is also possible to login to a shell via the local terminal and SSH (which is enabled by default @todo: in hardening, add keys and remove ability to login with password).

### Software updates

If you are in a testing and non-production environment then it is possible access updates without a subscription as detailed here: https://pve.proxmox.com/wiki/Package_Repositories. Update `/etc/apt/sources.list` as detailed under the Proxmox VE No-Subscription Repository. This can be achieved via the local terminal, SSH or web interface (via Shell option).

For example, edit the file:

`nano /etc/apt/sources.list`

Add the following:

```
# PVE pve-no-subscription repository provided by proxmox.com,
# NOT recommended for production use
deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
```

To the existing:
```
deb http://ftp.uk.debian.org/debian bullseye main contrib

deb http://ftp.uk.debian.org/debian bullseye-updates main contrib

# security updates
deb http://security.debian.org bullseye-security main contrib
```

Resulting in:

```
deb http://ftp.debian.org/debian bullseye main contrib
deb http://ftp.debian.org/debian bullseye-updates main contrib

# PVE pve-no-subscription repository provided by proxmox.com,
# NOT recommended for production use
deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription

# security updates
deb http://security.debian.org/debian-security bullseye-security main contrib
```

The Proxmox VE system will now retrieve updates for both itself and the base Debian system.

Then from a shell run:

```
$ apt update
$ apt upgrade
```

@todo: determine if system needs a reboot

### Proxmox VE hardening

Links

@todo

Adding users

Add SSH keys and remove ability to login with password

## Setup an internal only network in Proxmox VE

From the Web GUI navigate to Datacenter - > your server -> Network

From the menu select Create then Linux Bridge

Input the desired IPv4/CIDR in this case 192.168.y.0/24 and add a comment if desired (“Internal network” was used here). Note that y must not be the same as x previously used.

Name was left as vmbr1

Credit: https://dannyda.com/2020/06/01/how-to-create-an-internal-only-isolated-network-for-guest-os-virtual-machines-vm-on-proxmox-ve-pve-like-in-vmware-workstation-host-only-network-but-different/


## Install and configure Internet gateway server virtual machine

VyOS was selected (https://vyos.io/)

### Create an ISO of the stable version (as of writing 1.3.0)

@todo: the built version seemed to be a nightly release, is it possible to add a tag to get a stable build?

Follow the build instructions:

https://docs.vyos.io/en/latest/contributing/build-vyos.html

This document does not list this version (goes up to 10 "buster") but Debian 11 "bullseye" was successfully used in this setup.

Run the following commands:

```
$ apt install git
$ apt install build-essential
```

Follow the instructions here https://docs.docker.com/engine/install/debian/ to install Docker

Run the following commands:

```
$ git clone -b equuleus --single-branch https://github.com/vyos/vyos-build

$ docker run --rm -it --privileged -v $(pwd):/vyos -w /vyos vyos/vyos-build:equuleus bash
```

Then in the Docker terminal run the following commands:

```
./configure --architecture amd64

sudo make iso
```

### Upload the ISO image to the Proxmox VE server

1. Via the web GUI navigate to Datacenter -> your server -> local.

2. In the right hand pane select ISO Images and then upload.

3. Upload the ISO image

Tip: you can also pass the checksum to the Proxmox VE upload tool 

### Create VyOS virtual machine

1. From the top right of the web GUI select Create VM

2. In the appearing dialogue type a Name “VyOS” and optionally select advanced and Start at boot

3. On the next tab select the target ISO image

4. On the System tab leave everything as default

5. n the Disk tab leave the defaults (this exceeds requirements https://docs.vyos.io/en/latest/installation/install.html)

6. On the CPU tab:

    Sockets: 1, 
    Cores: 2

7. On the Memory tab

    Memory: 4096MiB

8. On the Network tab

    Choose the bridge with the internet vmbr0 (it is possible to add the second later) and leave the defaults including firewall

    Confirm all the settings on the next tab but **do not** select start after created

    Navigate to the newly created VM on the left-hand pane then selected Hardware from the menu that is presented on the right. Choose Add and then Network Device. In the dialogue that appears select the Internal network bridge (vmbr1 in this case) that was created earlier and leave all other options as is.

    So, the VM will have the following Network Devices:

    net0: Internet

    net1: Internal only

9. Start the VM and connect the console (top right)

10. Login with vyos and vyos

    Run the command:

    ```
    $ install image
    ```

11. Follow the instructions

12. Set the CD/DVD to none in Web GUI

13. Reboot

### Configure VyOS

Open a noVNC window to the host

Login with vyos and vyos

Switch to configure mode:

```
vyos@vyos$ configure
vyos@vyos#
```

Then configure as desired. Below is configuration used in the setup here (if you use for inspiration do take care to replace the x and y octet values correctly with previously chosen values):

```
set interfaces ethernet eth0 address '192.168.x.221/24'
set interfaces ethernet eth0 description 'OUTSIDE'
set protocols static route 0.0.0.0/0 next-hop 192.168.x.254 distance 1
set service dns forwarding system
set service dns forwarding name-server 192.168.x.254
set service dns forwarding listen-address 192.168.y.1
set service dns forwarding allow-from 192.168.y.0/24
set system name	-server 192.168.x.254

set interfaces ethernet eth1 address '192.168.y.1/24'
set interfaces ethernet eth1 description 'INSIDE'

set nat source rule 100 outbound-interface eth0
set nat source rule 100 source address 192.168.y.0/24
set nat source rule 100 translation address masquerade

set service ssh listen-address 0.0.0.0
```

Once done remember to commit the config (correcting any misconfiguration) and save.

```
commit
save
```

Inspiration for the above was taken from: https://bertvv.github.io/cheat-sheets/VyOS.html

@todo: hardening, IDS, IPS