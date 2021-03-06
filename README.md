# Centos Hardening

This script has been developed to install and configure Centos automatically on bare metal servers in production environments. 
This project involved PXE, DHCP, TFTP, Hardening, and Kickstart. First of all, the pxe server will be run on the production environments. 
After that you can configure your bare metal server setting for boot from the network mode(pxe).
At this moment your server will be connected to the pxe server and can get an IP from dhcp server. Your server now is ready to install on the network. 
At this process we have some of bash scripts for automate os hardening based on OPEN SCAP checklist. Also we have a kickstart file for managing our installation process and 
how we should install and configure our OS. You can define your OS install settings such as disk size, username, partitioning etc in the kickstart configuration file. 
Using this scripts you can install for example 16 bare metal servers simultaneously from one pxe server. 
For this process you will need a Hub for connecting all servers and pxe server to each other or private network to connect pxe and other servers to each other.



## Installation

1. At first create a VM for PXE Server and install pxe on your virtual machine

2. Then install and configure pxe servervices(DHCP, TFTP and xinetd)

3. Copy pub directory contents to the /var/ftp/pub path on the PXE server

4. Download Centos 7 iso file, Mount to temporary path such as /mnt and then accomodate its packages to Packages directory on pxe server.

5. Copy your OS squashfs file to pub/LiveOS/squashfs.img

```bash
cp OS_FILES_PATH/vmlinuz   pub/images/pxeboot/vmlinuz 
cp OS_FILES_PATH/initrd.img  pub/images/pxeboot/initrd.img 
cp OS_FILES_PATH/isolinux/*  pub/isolinux/*
```
6. Restart your PXE services 

7. Create client machine for automatic installation test.



## Usage

Install, configure and hardening centos automatically on the bare metal servers or virtual machines simultaneously.


## License



## Contact

a.abaszadeh1363@gmail.com

Project Link: [https://github.com/ali-abaszadeh/Centos-Hardening.git]
