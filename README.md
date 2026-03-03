# ⚔️ Kalify

> **Turn any Debian-based Linux distro into a Kali‑style penetration testing platform**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Debian--based-success.svg)](https://www.debian.org)[web:143]
[![Shell](https://img.shields.io/badge/Shell-Bash-%23121011.svg)](https://www.gnu.org/software/bash/)

Kalify is a single Bash script that converts a normal Debian-based Linux distribution into a **Kali‑like offensive security platform**, installing hundreds of tools commonly bundled with Kali Linux while letting you keep your favorite desktop and workflow.[web:139][web:131]

---

## 🎯 Overview

Kalify automates the installation and configuration of **600+ penetration testing tools**, dev environments, and supporting components, giving you Kali‑style capability on any Debian-based system.[web:145][web:133]

**Highlights:**

- Extensive network, web, wireless, AD, OSINT, forensics, and reverse engineering toolsets
- Python, Go, and Ruby environments tuned for security tooling
- Docker and docker‑compose for modern containerized workflows
- Wordlists, payload collections, and common post‑exploitation utilities
- Helpful aliases and a consistent directory layout for pentest work

---

## ✅ Supported Distributions

Kalify targets any Linux distribution that uses `apt-get` for package management:[web:143]

- Debian 10 / 11 / 12+
- Ubuntu 20.04 / 22.04 / 24.04+
- Linux Mint 20 / 21+
- Pop!_OS 20.04 / 22.04+
- Kali Linux
- Parrot OS
- Other Debian-based distros with working `apt-get`

> Some tools may already exist on Kali/Parrot; Kalify will generally reuse or skip where appropriate.

---

## 🧰 Tool Categories

### Network & Discovery

- Nmap, Masscan, Wireshark, Tshark
- Netcat, Socat, Netdiscover, arp-scan, arping, hping3
- Traceroute, whois, DNS utilities (dnsutils, dnsrecon, dnsenum, fierce)
- Responder, mitm6, MAC changer[web:150][web:148]

### Web Application Testing

- SQLMap, WPScan, Nikto, WhatWeb, Wafw00f
- Gobuster, Dirb, Dirbuster, Feroxbuster
- Commix, Wfuzz, Hydra, Medusa
- ffuf (via Go)
- OWASP ZAP (zaproxy)
- Burp Suite Community (manual download link only)

### Exploitation & C2

- Metasploit Framework
- NetExec (CrackMapExec replacement)
- Impacket
- PowerShell Empire (optional; large dependency set)
- Chisel, Ligolo‑ng (tunneling/pivoting)

### Active Directory

- BloodHound + Neo4j
- Kerbrute
- enum4linux‑ng
- LDAP/AD helpers and Python libraries (ldap3, ldapdomaindump)

### Password Cracking

- John the Ripper
- Hashcat + hashcat‑utils
- Hydra, Medusa, Ncrack
- Ophcrack, fcrackzip, pdfcrack, sipcrack

### Wireless

- aircrack‑ng suite, Kismet, Wifite
- Reaver, Bully, Pixiewps
- MDK3 / MDK4
- Cowpatty, Asleap
- hostapd‑wpe

### Forensics & OSINT

- Autopsy, Binwalk, Sleuthkit, Yara
- Bulk‑extractor, chkrootkit, Foremost, Steghide, Outguess, Stegosuite
- Volatility3
- theHarvester, Recon‑ng, Maltego, SpiderFoot
- Shodan, Censys, Holehe, Maigret Python clients

### Reverse Engineering

- Ghidra
- Radare2, Rizin
- GDB + pwndbg
- ltrace, strace, objdump
- hexedit, Bless

---

## 🧱 Directory Layout

Kalify standardizes where tools and loot live:

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
