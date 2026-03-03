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

🚀 Installation
1. Download Kalify
bash
wget https://raw.githubusercontent.com/yourusername/kalify/main/kalify.sh
chmod +x kalify.sh
Replace yourusername with your GitHub username.

2. Run the Installer
Standard install:

bash
sudo ./kalify.sh
Behind an SSL‑intercepting corporate proxy (disables SSL verification):

bash
sudo ./kalify.sh --disable-ssl-check
Faster / minimal install (skips large optional tools like Empire):

bash
sudo ./kalify.sh --skip-optional
Verbose debug mode:

bash
DEBUG=true sudo ./kalify.sh
Strongly recommended: run in a fresh VM or dedicated lab system, not on production hosts.

🔐 SSL Check Bypass (Proxies)
If you run Kalify with --disable-ssl-check, it will:

Disable certificate checks for:

wget via /etc/wgetrc

curl via ~/.curlrc

apt via /etc/apt/apt.conf.d/99-kalify-disable-ssl-verify

Configure pip trusted hosts

Disable git SSL verification

Set environment variables such as PYTHONHTTPSVERIFY=0 and REQUESTS_CA_BUNDLE=

This is insecure on untrusted networks and should be used only when absolutely necessary behind a trusted enterprise proxy.[web:119][web:122][web:124]

📋 Post‑Install Steps
After Kalify completes:

Reload your shell:

bash
source /etc/profile
Configure Neo4j for BloodHound:

bash
sudo neo4j-admin dbms set-initial-password YourPassword123
sudo systemctl start neo4j
Start Docker:

bash
sudo systemctl start docker
Check installed tooling:

bash
ls /opt/tools
ls /usr/share/wordlists
Reboot for all changes to fully apply:

bash
sudo reboot
⚡ Built‑In Aliases
Once your shell is reloaded, Kalify provides quality‑of‑life aliases:

Quick Servers
web – Python HTTP server on port 8000

webssl – Python HTTP server on port 8443

ftpserver – Quick FTP using pyftpdlib

Network & Scanning
myip – Show public IP (ifconfig.me)

ports – Show listening ports via netstat -tulanp

listen – List listening sockets via lsof

nmap-quick – nmap -sV -sC -T4

nmap-full – Full TCP port scan

nmap-vuln – nmap with vuln scripts

nmap-udp – Top UDP ports

nmap-discover – Host discovery (nmap -sn)

Enumeration & Navigation
enum-smb – enum4linux-ng

enum-web – gobuster dir -u

tools – cd /opt/tools

wordlists – cd /usr/share/wordlists

payloads – cd /opt/tools/PayloadsAllTheThings

pentest – cd ~/pentest

Metasploit & Updates
metasploit / msf – Launch Metasploit console

update-all – apt update && apt upgrade && apt autoremove

kalify-update – git pull all repos under /opt/tools

🧪 Reliability & Script Quality
Kalify aims to follow modern shell scripting best practices for reliability:[web:130][web:48][web:146]

Uses #!/usr/bin/env bash and set -euo pipefail for strict error handling

Defensive quoting and input handling

Lock file at /var/run/kalify.lock to prevent concurrent runs

Retry logic for apt-get install with multiple attempts

Non‑interactive apt usage (DEBIAN_FRONTEND=noninteractive) to avoid hangs

Logging to /var/log/kalify_install.log with basic log rotation

Optional flags for SSL bypass and skipping heavy components

📄 Usage Summary
Common invocations:

bash
# Standard full install
sudo ./kalify.sh

# Proxy environment (disable SSL verification globally - risky)
sudo ./kalify.sh --disable-ssl-check

# Faster / minimal install
sudo ./kalify.sh --skip-optional

# See help
./kalify.sh --help

# Show version
./kalify.sh --version
📜 License
Kalify is released under the MIT License. See the LICENSE file for the full text.

⚖️ Legal Disclaimer
Kalify is intended only for:

Authorized penetration testing and red teaming

Security research in controlled lab environments

Training and education

You are solely responsible for complying with all applicable laws and regulations. Use these tools only on systems you own or have explicit written permission to test. The author assumes no liability for misuse, damage, or legal consequences.

🤝 Contributing
Contributions are welcome:

Add or refine tool modules

Improve distro detection and handling

Enhance logging, error handling, and configurability

Extend docs and usage examples

Basic workflow:

Fork this repository

Create a feature branch

Make changes and test on at least one Debian‑based distro

Submit a pull request with a clear description

🔭 Roadmap
 Interactive mode (choose categories: Web / AD / Wireless / OSINT / etc.)

 Profiles: “OSCP lab”, “AD‑heavy internal”, “Web‑only”

 Uninstaller / rollback helper

 GitHub Actions CI for linting and basic functional checks

 Containerized mode for non‑Debian hosts (via Docker)

⭐ Support
If Kalify saves you time or becomes part of your workflow:

⭐ Star the repository

🐛 Open issues for bugs or unexpected behavior

💡 Open PRs with fixes, features, or improved defaults

Happy hacking – build responsibly, test ethically.
