# LForM

LForM is a traffic/security log viewer for Firewalls(Fortigate 5.4.3).<br>
LForM collects the log of the next-generation firewall, to visualize the traffic and security log.

# Component

- Java : 1.8.0
- ElasticSearch : 2.3.3
- Fluentd(td-agent) : 2.3.1
- kibana : 4.5.1
- nginx : 1.10.1

# System Requirement

- Firewall
	- Fortigate 5.4.x

- Server
	- OS : Centos 7.x
	- CPU >= Intel® Core™ i3 , Intel® Xeon® Processor E3 Family
	- Memory(GiB) >= 4
	- Storage(GiB) >= 50

# Getting Start

## Installation

Installation procedure for PALallax is as below.(this requires root privileges)

	# git clone
	yum install -y git
	git clone -b v1.1.3 https://github.com/ap-communications/LForM

	# Move to LForM directory before following steps.
	cd LForM/

	# Run Shellscript.(Cent7.x Only)
	./LForM_install.sh

	# Installation is started.


