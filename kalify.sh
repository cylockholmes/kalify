# ⚔️ Kalify

> **Turn any Debian-based Linux distro into a Kali‑style penetration testing platform**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Debian--based-success.svg)](https://www.debian.org)[web:143]
[![Shell](https://img.shields.io/badge/Shell-Bash-%23121011.svg)](https://www.gnu.org/software/bash/)

Kalify is a single Bash script that converts a normal Debian-based Linux distribution into a **Kali‑like offensive security platform**, installing hundreds of the tools commonly bundled with Kali Linux while letting you keep your favorite desktop and workflow.[web:139][web:131]

---

## 🎯 What Kalify Does

- Installs and configures **600+ offensive security tools** across:
  - Network reconnaissance and scanning
  - Web application testing
  - Exploitation frameworks
  - Active Directory and internal network attacks
  - Password cracking and wordlists
  - Wireless, forensics, OSINT, and reverse engineering[web:145][web:133]
- Sets up **development environments**:
  - Python 3 + common security libraries
  - Golang with GOPATH and PATH configured
  - Ruby with Bundler and gems
- Installs and configures **Docker** for containerized tooling
- Creates a clean **pentest workspace** at `~/pentest`
- Adds **productivity aliases** to speed up common tasks

You get the power of Kali’s toolset on **any Debian-based system** without changing distro.[web:131]

---

## ✅ Supported Distributions

Kalify targets any Linux distribution with `apt-get`, including:[web:143]

- Debian 10/11/12+
- Ubuntu 20.04/22.04/24.04+
- Linux Mint 20/21+
- Pop!_OS 20.04/22.04+
- Kali Linux
- Parrot OS
- Other Debian-based distros with working apt-get

> ℹ️ Some tools may already be present on Kali/Parrot; Kalify will skip or reuse what’s installed where possible.

---

## 🧰 Major Tool Categories

### Network & Discovery

- Nmap, Masscan, Wireshark, Tshark
- Netcat, Socat, Netdiscover, arp-scan, hping3
- Responder, mitm6, MAC changer[web:150][web:148]

### Web Application Testing

- SQLMap, WPScan, Nikto, WhatWeb, Wafw00f
- Gobuster, Dirb, Dirbuster, Feroxbuster
- Commix, Wfuzz, Hydra, Medusa
- ffuf (via Go)
- OWASP ZAP (zaproxy)
- Burp Suite Community (manual download)

### Exploitation & C2

- Metasploit Framework
- NetExec (CrackMapExec replacement)
- Impacket
- PowerShell Empire (optional, large)
- Chisel, Ligolo-ng (pivoting)

### Active Directory

- BloodHound + Neo4j
- Kerbrute
- enum4linux-ng
- LDAP / Kerberos helpers

### Password Cracking

- John the Ripper
- Hashcat + hashcat-utils
- Hydra, Medusa, Ncrack
- Ophcrack, fcrackzip, pdfcrack, sipcrack

### Wireless

- aircrack-ng suite, Kismet, Wifite
- Reaver, Bully, Pixiewps
- MDK3/MDK4, Cowpatty, Asleap, hostapd-wpe

### Forensics & OSINT

- Autopsy, Binwalk, Sleuthkit, Yara
- Volatility3
- theHarvester, Recon-ng, Maltego, SpiderFoot
- OSINT Python tools: Shodan, Censys, Holehe, Maigret

### Reverse Engineering

- Ghidra, Radare2, Rizin
- GDB + pwndbg
- ltrace, strace, objdump
- Hexedit, Bless

---

## 🧱 Directory Layout

Kalify keeps tools and loot in predictable locations:

```text
/opt/
├── tools/              # GitHub-cloned tools
│   ├── PEASS-ng/
│   ├── PayloadsAllTheThings/
│   ├── enum4linux-ng/
│   ├── hashcat-utils/
│   └── ...
├── wordlists/          # Extra wordlists (SecLists, etc.)
└── scripts/            # Your custom scripts

/usr/share/wordlists/
└── rockyou.txt         # Decompressed if present

~/pentest/              # Working area
├── recon/
├── exploit/
├── loot/
├── notes/
├── screenshots/
└── reports/
