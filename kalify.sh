#!/usr/bin/env bash
################################################################################
# Kalify - Universal Debian-based Penetration Testing Platform Installer
# Author: cylockholmes
# Version: 2.1
# Description: Transform any Debian-based distro into a professional-grade
#              penetration testing platform with 600+ tools
# Inspired by: Kali Linux, PimpMyKali, and Offensive Security standards
# License: MIT
################################################################################

# Strict error handling and safety [web:130][web:48]
set -euo pipefail
IFS=$'\n\t'

# Enable debug mode if DEBUG environment variable is set [web:48]
[[ "${DEBUG:-}" == "true" ]] && set -x

# Script metadata
readonly SCRIPT_VERSION="2.1"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global configuration
readonly LOG_FILE="/var/log/kalify_install.log"
readonly LOCK_FILE="/var/run/kalify.lock"
TEMP_DIR=""
DISABLE_SSL_CHECK=false
SKIP_OPTIONAL=false

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

################################################################################
# TRAP HANDLERS AND CLEANUP
################################################################################

cleanup() {
    local exit_code=$?

    if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi

    if [[ -f "${LOCK_FILE}" ]]; then
        rm -f "${LOCK_FILE}"
    fi

    return "${exit_code}"
}

handle_error() {
    local exit_code=$?
    local line_no="${1:-unknown}"
    local bash_lineno="${2:-unknown}"
    local last_cmd="${3:-unknown}"

    echo -e "\n${RED}╔════════════════════════════════════════════════════════════╗${NC}" >&2
    echo -e "${RED}║                    ERROR DETECTED                          ║${NC}" >&2
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}" >&2
    echo -e "${RED}[!] Command:${NC} ${last_cmd}" >&2
    echo -e "${RED}[!] Line:${NC} ${bash_lineno}" >&2
    echo -e "${RED}[!] Exit code:${NC} ${exit_code}" >&2
    echo -e "${YELLOW}[*] Log file:${NC} ${LOG_FILE}" >&2
    echo ""
    cleanup
    exit "${exit_code}"
}

trap cleanup EXIT
trap 'handle_error ${LINENO} ${BASH_LINENO} "${BASH_COMMAND}"' ERR

################################################################################
# LOGGING
################################################################################

init_logging() {
    if [[ -f "${LOG_FILE}" ]]; then
        local size
        size=$(stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)
        if [[ "${size}" -gt 10485760 ]]; then
            mv "${LOG_FILE}" "${LOG_FILE}.old"
        fi
    fi

    mkdir -p "$(dirname "${LOG_FILE}")"
    touch "${LOG_FILE}"

    exec 1> >(tee -a "${LOG_FILE}")
    exec 2>&1

    log_info "========================================="
    log_info "Kalify v${SCRIPT_VERSION} - Installation started"
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    log_info "User: $(whoami)"
    log_info "Hostname: $(hostname)"
    log_info "========================================="
}

log() {
    echo -e "${GREEN}[+]${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[!]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

log_info() {
    echo -e "${BLUE}[*]${NC} $*" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" | tee -a "${LOG_FILE}"
}

################################################################################
# UI
################################################################################

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
    __ __      ___     __    
   / //_/___ _/ (_)___/ /_  __
  / ,< / __ `/ / / __  / / / /
 / /| / /_/ / / / /_/ / /_/ / 
/_/ |_\__,_/_/_/\__,_/\__, /  
                     /____/   
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Transform any Debian-based distro into a pentesting powerhouse${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}[>]${NC} ${BLUE}Version: ${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}[>]${NC} ${BLUE}Author: cylockholmes${NC}"
    echo -e "${CYAN}[>]${NC} ${BLUE}Estimated Time: 30-60 minutes${NC}"
    echo -e "${CYAN}[>]${NC} ${BLUE}Tools Installed: 600+${NC}"  # Kali bundles ~600 tools [web:131]
    echo ""
}

show_help() {
    cat << EOF
${CYAN}Kalify${NC} - Debian-based Penetration Testing Platform Installer

${YELLOW}Usage:${NC}
    sudo ./${SCRIPT_NAME} [OPTIONS]

${YELLOW}Options:${NC}
    --disable-ssl-check    Disable SSL certificate verification (for corporate proxies)
    --skip-optional        Skip optional/large packages (faster installation)
    --help, -h             Show this help message
    --version, -v          Show version information

${YELLOW}Examples:${NC}
    sudo ./${SCRIPT_NAME}
    sudo ./${SCRIPT_NAME} --disable-ssl-check
    sudo ./${SCRIPT_NAME} --skip-optional
    DEBUG=true sudo ./${SCRIPT_NAME}

EOF
}

################################################################################
# ARGS & CHECKS
################################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --disable-ssl-check)
                DISABLE_SSL_CHECK=true
                log_warning "SSL certificate checking disabled (INSECURE - use only behind proxies)"
                shift
                ;;
            --skip-optional)
                SKIP_OPTIONAL=true
                log_info "Skipping optional/large packages for faster installation"
                shift
                ;;
            --version|-v)
                echo "Kalify v${SCRIPT_VERSION}"
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Unknown option: ${1}${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This script must be run as root${NC}" >&2
        echo -e "${YELLOW}[*] Please run: sudo ./${SCRIPT_NAME}${NC}" >&2
        exit 1
    fi
}

check_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local lock_pid
        lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "unknown")
        if ps -p "${lock_pid}" > /dev/null 2>&1; then
            echo -e "${RED}[!] Kalify is already running (PID: ${lock_pid})${NC}" >&2
            echo -e "${YELLOW}[*] If this is an error, remove: ${LOCK_FILE}${NC}" >&2
            exit 1
        else
            rm -f "${LOCK_FILE}"
        fi
    fi
    echo $$ > "${LOCK_FILE}"
}

check_debian_based() {
    if ! command -v apt-get >/dev/null 2>&1; then
        echo -e "${RED}[!] This script requires a Debian-based distribution (apt-get not found)${NC}" >&2
        exit 1
    fi

    if command -v lsb_release >/dev/null 2>&1; then
        DISTRO_ID=$(lsb_release -is)
        DISTRO_RELEASE=$(lsb_release -rs)
        DISTRO_CODENAME=$(lsb_release -cs)
    elif [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO_ID="${NAME}"
        DISTRO_RELEASE="${VERSION_ID:-unknown}"
        DISTRO_CODENAME="${VERSION_CODENAME:-unknown}"
    else
        DISTRO_ID="Unknown"
        DISTRO_RELEASE="unknown"
        DISTRO_CODENAME="unknown"
    fi

    log_success "Detected: ${DISTRO_ID} ${DISTRO_RELEASE} (${DISTRO_CODENAME})"
}

check_disk_space() {
    local required_space=20
    local available_space
    available_space=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [[ ${available_space} -lt ${required_space} ]]; then
        log_warning "Low disk space: ${available_space}GB available, ${required_space}GB recommended"
    else
        log_success "Disk space check passed: ${available_space}GB available"
    fi
}

check_internet() {
    log_info "Checking internet connectivity..."
    local hosts=("8.8.8.8" "1.1.1.1")
    local ok=false
    for h in "${hosts[@]}"; do
        if ping -c 1 -W 2 "${h}" >/dev/null 2>&1; then
            ok=true
            break
        fi
    done
    if [[ "${ok}" == false ]]; then
        log_error "No internet connection detected"
        exit 1
    fi
    log_success "Internet connectivity confirmed"
}

################################################################################
# SSL BYPASS
################################################################################

configure_ssl_bypass() {
    if [[ "${DISABLE_SSL_CHECK}" != true ]]; then
        return 0
    fi

    log_warning "Configuring global SSL bypass (INSECURE - for proxies only)..."

    if ! grep -q "check_certificate = off" /etc/wgetrc 2>/dev/null; then
        echo "check_certificate = off" >> /etc/wgetrc
    fi

    if [[ ! -f ~/.curlrc ]] || ! grep -q "insecure" ~/.curlrc 2>/dev/null; then
        echo "insecure" >> ~/.curlrc
    fi

    mkdir -p ~/.config/pip
    cat > ~/.config/pip/pip.conf << 'EOF'
[global]
trusted-host = pypi.org
               files.pythonhosted.org
               pypi.python.org
[install]
trusted-host = pypi.org
               files.pythonhosted.org
               pypi.python.org
EOF

    cat > /etc/apt/apt.conf.d/99-kalify-disable-ssl-verify << 'EOF'
Acquire::https::Verify-Peer "false";
Acquire::https::Verify-Host "false";
EOF

    git config --global http.sslVerify false

    export PYTHONHTTPSVERIFY=0
    export CURL_CA_BUNDLE=""
    export REQUESTS_CA_BUNDLE=""
    export NODE_TLS_REJECT_UNAUTHORIZED=0

    log_success "SSL verification disabled globally"
}

################################################################################
# APT WRAPPER
################################################################################

apt_install() {
    local max_attempts=3
    local attempt=1
    local packages=("$@")

    while [[ ${attempt} -le ${max_attempts} ]]; do
        log_info "Installing packages (attempt ${attempt}/${max_attempts}): ${packages[*]}"
        if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "${packages[@]}"; then
            log_success "Packages installed successfully"
            return 0
        else
            log_warning "Installation attempt ${attempt} failed"
            ((attempt++))
            if [[ ${attempt} -le ${max_attempts} ]]; then
                log_info "Retrying apt-get update..."
                apt-get update -qq || true
                sleep 5
            fi
        fi
    done

    log_error "Failed to install packages after ${max_attempts} attempts: ${packages[*]}"
    return 1
}

update_system() {
    log "Updating system packages..."

    dpkg --configure -a || true
    apt-get --fix-broken install -y || true

    local max_attempts=3
    local attempt=1
    while [[ ${attempt} -le ${max_attempts} ]]; do
        if apt-get update; then
            break
        else
            log_warning "apt-get update failed (attempt ${attempt}/${max_attempts})"
            ((attempt++))
            sleep 5
        fi
    done

    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y || log_warning "Some upgrades failed"
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y || log_warning "Dist-upgrade issues"
    apt-get autoremove -y || true

    log_success "System packages updated"
}

################################################################################
# INSTALL MODULES
################################################################################

install_base_deps() {
    log "Installing base dependencies..."

    local pkgs=(
        build-essential git wget curl vim nano tmux screen htop
        net-tools dnsutils ca-certificates gnupg lsb-release
        software-properties-common apt-transport-https unzip p7zip-full
        binutils gcc make perl automake autoconf libtool pkg-config
        libssl-dev libffi-dev libxml2-dev libxslt1-dev libpcap-dev
        libpq-dev zlib1g-dev python3-dev sshpass zip gzip bzip2
    )

    apt_install "${pkgs[@]}" || log_warning "Some base packages failed"
    log_success "Base dependencies installed"
}

install_python() {
    log "Installing Python environment..."

    apt_install python3 python3-pip python3-dev python3-venv python3-setuptools || log_error "Python install failed"
    apt_install python-is-python3 2>/dev/null || log_info "python-is-python3 not available, skipping..."

    python3 -m pip install --upgrade pip setuptools wheel || log_warning "Pip upgrade issues"

    log "Installing Python security modules..."
    local modules=(
        requests pycryptodome pyOpenSSL paramiko impacket
        pwntools scapy colorama beautifulsoup4 lxml selenium
        flask django sqlalchemy pytest ldap3 ldapdomaindump
        bloodhound mitm6 pycryptodomex pypykatz aiowinreg
    )

    pip3 install --no-warn-script-location "${modules[@]}" || log_warning "Some Python modules failed"
    log_success "Python environment configured"
}

install_golang() {
    if command -v go >/dev/null 2>&1; then
        log_info "Go already installed, skipping..."
        return 0
    fi

    log "Installing Golang..."

    local version="1.22.1"
    local arch="amd64"
    case "$(uname -m)" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="armv6l" ;;
        *) log_warning "Unsupported architecture for Go: $(uname -m)"; return 1 ;;
    esac

    local url="https://go.dev/dl/go${version}.linux-${arch}.tar.gz"
    wget -q "${url}" -O /tmp/go.tar.gz || { log_error "Failed to download Go"; return 1; }

    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        cat >> /etc/profile << 'EOF'

# Golang environment
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
    fi

    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

    log_success "Go installed"
}

install_ruby() {
    log "Installing Ruby environment..."
    apt_install ruby ruby-dev rubygems || log_error "Ruby install failed"
    gem install bundler rake || log_warning "Some Ruby gems failed"
    log_success "Ruby environment installed"
}

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker already installed, skipping..."
        return 0
    fi

    log "Installing Docker..."

    local docker_distro="ubuntu"
    case "${DISTRO_ID,,}" in
        debian) docker_distro="debian" ;;
        ubuntu|pop|mint) docker_distro="ubuntu" ;;
        *) docker_distro="ubuntu" ;;
    esac

    mkdir -p /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${docker_distro}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
        log_error "Failed to add Docker GPG key"
        return 1
    }
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${docker_distro} \
      ${DISTRO_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
        log_error "Failed to install Docker"
        return 1
    }

    systemctl enable docker || true
    systemctl start docker || true

    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "${SUDO_USER}" || true
    fi

    log_success "Docker installed and configured"
}

install_network_tools() {
    log "Installing network analysis tools..."

    local tools=(
        nmap masscan wireshark tshark tcpdump netcat-traditional socat
        netdiscover arp-scan arping hping3 traceroute whois dnsutils
        dnsrecon dnsenum fierce nikto aircrack-ng kismet wireless-tools
        reaver bully pixiewps macchanger ettercap-text-only responder
    )

    apt_install "${tools[@]}" || log_warning "Some network tools failed"
    pip3 install mitm6 || log_warning "mitm6 install failed"

    log_success "Network tools installed"
}

install_web_tools() {
    log "Installing web application testing tools..."

    local tools=(
        sqlmap wpscan dirb dirbuster gobuster nikto whatweb wafw00f
        commix wfuzz hydra medusa john hashcat hashid hash-identifier
        zaproxy feroxbuster seclists
    )

    apt_install "${tools[@]}" || log_warning "Some web tools failed"

    if command -v go >/dev/null 2>&1; then
        log_info "Installing ffuf..."
        go install github.com/ffuf/ffuf/v2@latest || log_warning "ffuf install failed"
    fi

    log_info "Burp Suite Community: https://portswigger.net/burp/communitydownload"
    log_success "Web tools installed"
}

install_exploitation_tools() {
    log "Installing exploitation frameworks..."

    if ! command -v msfconsole >/dev/null 2>&1; then
        curl -sSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall
        chmod 755 /tmp/msfinstall
        /tmp/msfinstall || log_warning "Metasploit install issues"
        rm -f /tmp/msfinstall
    else
        log_info "Metasploit already installed"
    fi

    pip3 install impacket || log_warning "Impacket install failed"

    log_info "Installing NetExec..."
    apt_install pipx python3-poetry || true
    export PIPX_HOME=/opt/pipx
    export PIPX_BIN_DIR=/usr/local/bin
    export PATH=$PATH:$PIPX_BIN_DIR
    pipx ensurepath --force || true
    pipx install git+https://github.com/Pennyw0rth/NetExec || log_warning "NetExec install failed"

    if [[ "${SKIP_OPTIONAL}" != true && ! -d /opt/Empire ]]; then
        log_info "Installing PowerShell Empire..."
        cd /opt
        git clone --depth 1 https://github.com/BC-SECURITY/Empire.git || log_warning "Empire clone failed"
        if [[ -d /opt/Empire ]]; then
            cd Empire
            ./setup/install.sh || log_warning "Empire setup issues"
        fi
    fi

    log_success "Exploitation tools installed"
}

install_ad_tools() {
    log "Installing Active Directory tools..."

    apt_install bloodhound || {
        log_info "Installing Bloodhound from GitHub..."
        wget -q https://github.com/BloodHoundAD/BloodHound/releases/latest/download/BloodHound-linux-x64.zip -O /tmp/bloodhound.zip
        unzip -q /tmp/bloodhound.zip -d /opt/
        chmod +x /opt/BloodHound-linux-x64/BloodHound
        ln -sf /opt/BloodHound-linux-x64/BloodHound /usr/local/bin/bloodhound
        rm /tmp/bloodhound.zip
    }

    log_info "Installing Neo4j..."
    wget -qO - https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
    echo 'deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest' > /etc/apt/sources.list.d/neo4j.list
    apt-get update -qq
    apt_install neo4j || log_warning "Neo4j install failed"
    systemctl enable neo4j || true

    if command -v go >/dev/null 2>&1; then
        go install github.com/ropnop/kerbrute@latest || log_warning "Kerbrute install failed"
    fi

    log_success "Active Directory tools installed"
}

install_password_tools() {
    log "Installing password cracking tools..."

    local tools=(
        john hashcat hydra medusa ncrack ophcrack
        fcrackzip pdfcrack sipcrack
    )

    apt_install "${tools[@]}" || log_warning "Some password tools failed"

    if [[ ! -d /opt/hashcat-utils ]]; then
        cd /opt
        git clone --depth 1 https://github.com/hashcat/hashcat-utils.git || log_warning "hashcat-utils clone failed"
        cd hashcat-utils/src
        make || log_warning "hashcat-utils build failed"
    fi

    log_success "Password tools installed"
}

install_wireless_tools() {
    log "Installing wireless testing tools..."

    local tools=(
        aircrack-ng kismet wifite reaver bully pixiewps
        mdk3 mdk4 cowpatty asleap eapmd5pass hostapd-wpe
    )

    apt_install "${tools[@]}" || log_warning "Some wireless tools failed"
    log_success "Wireless tools installed"
}

install_forensics_tools() {
    log "Installing forensics tools..."

    local tools=(
        autopsy binwalk bulk-extractor chkrootkit foremost
        sleuthkit yara exiftool steghide outguess stegosuite
    )

    apt_install "${tools[@]}" || log_warning "Some forensics tools failed"
    pip3 install volatility3 || log_warning "Volatility3 install failed"

    log_success "Forensics tools installed"
}

install_osint_tools() {
    log "Installing OSINT tools..."

    local tools=(theharvester recon-ng maltego spiderfoot)
    apt_install "${tools[@]}" || log_warning "Some OSINT tools failed"

    pip3 install shodan censys holehe maigret || log_warning "OSINT Python modules failed"

    log_success "OSINT tools installed"
}

install_reverse_tools() {
    log "Installing reverse engineering tools..."

    local tools=(
        ghidra radare2 gdb ltrace strace binwalk
        objdump hexedit bless rizin
    )

    apt_install "${tools[@]}" || log_warning "Some reverse tools failed"

    if [[ ! -d /opt/pwndbg ]]; then
        cd /opt
        git clone --depth 1 https://github.com/pwndbg/pwndbg || log_warning "pwndbg clone failed"
        cd pwndbg
        ./setup.sh || log_warning "pwndbg setup failed"
    fi

    log_success "Reverse engineering tools installed"
}

install_wordlists() {
    log "Installing wordlists and payloads..."

    apt_install seclists wordlists || log_warning "Wordlist packages failed"

    if [[ -f /usr/share/wordlists/rockyou.txt.gz ]]; then
        log_info "Extracting rockyou.txt.gz..."
        gunzip -f /usr/share/wordlists/rockyou.txt.gz || true
        chmod 644 /usr/share/wordlists/rockyou.txt 2>/dev/null || true
    fi

    mkdir -p /opt/wordlists
    if [[ ! -d /opt/wordlists/SecLists ]]; then
        cd /opt/wordlists
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git || log_warning "SecLists clone failed"
    fi

    log_success "Wordlists installed"
}

install_github_tools() {
    log "Installing additional GitHub tools..."

    mkdir -p /opt/tools
    cd /opt/tools

    [[ ! -d PEASS-ng ]] && git clone --depth 1 https://github.com/carlospolop/PEASS-ng.git || true
    [[ ! -d PayloadsAllTheThings ]] && git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git || true
    pip3 install git+https://github.com/Tib3rius/AutoRecon.git || log_warning "AutoRecon failed"
    gem install evil-winrm || log_warning "Evil-WinRM failed"
    [[ ! -d enum4linux-ng ]] && git clone --depth 1 https://github.com/cddmp/enum4linux-ng.git || true

    if command -v go >/dev/null 2>&1; then
        go install github.com/jpillora/chisel@latest || true
        go install github.com/nicocha30/ligolo-ng/cmd/proxy@latest || true
        go install github.com/nicocha30/ligolo-ng/cmd/agent@latest || true
    fi

    log_success "GitHub tools installed"
}

configure_aliases() {
    log "Configuring bash aliases..."

    cat > /etc/profile.d/kalify_aliases.sh << 'EOF'
# Kalify Penetration Testing Aliases

alias web='python3 -m http.server 8000'
alias webssl='python3 -m http.server 8443 --bind 0.0.0.0'
alias ftpserver='python3 -m pyftpdlib -p 21 -w'

alias myip='curl -s ifconfig.me'
alias ports='netstat -tulanp'
alias listen='lsof -i -P -n | grep LISTEN'

alias nmap-quick='nmap -sV -sC -T4'
alias nmap-full='nmap -sV -sC -p- -T4'
alias nmap-vuln='nmap -sV --script vuln'
alias nmap-udp='nmap -sU -sV --top-ports 100'
alias nmap-discover='nmap -sn'

alias enum-smb='enum4linux-ng'
alias enum-web='gobuster dir -u'

alias tools='cd /opt/tools'
alias wordlists='cd /usr/share/wordlists'
alias payloads='cd /opt/tools/PayloadsAllTheThings'
alias pentest='cd ~/pentest'

alias metasploit='msfconsole'
alias msf='msfconsole'

alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias update-all='apt update && apt upgrade -y && apt autoremove -y'
alias kalify-update='cd /opt/tools && find . -maxdepth 1 -type d -exec git -C {} pull \;'
EOF

    chmod +x /etc/profile.d/kalify_aliases.sh
    log_success "Aliases configured"
}

setup_directories() {
    log "Setting up directory structure..."

    mkdir -p /opt/tools /opt/wordlists /opt/scripts
    mkdir -p ~/pentest/{recon,exploit,loot,notes,screenshots,reports}
    chmod 755 /opt/tools /opt/wordlists /opt/scripts

    log_success "Directory structure created"
}

final_cleanup() {
    log "Performing final cleanup..."

    apt-get autoremove -y || true
    apt-get autoclean -y || true
    rm -f /tmp/msfinstall /tmp/zap.tar.gz /tmp/bloodhound.zip /tmp/go.tar.gz 2>/dev/null || true

    log_success "Cleanup complete"
}

################################################################################
# COMPLETION
################################################################################

print_completion() {
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}           ${GREEN}✓ Kalify Installation Complete!${NC}                ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  ${YELLOW}1.${NC} Reload your shell: ${GREEN}source /etc/profile${NC}"
    echo -e "  ${YELLOW}2.${NC} Configure Neo4j password:"
    echo -e "       ${GREEN}sudo neo4j-admin dbms set-initial-password YourPassword123${NC}"
    echo -e "       ${GREEN}sudo systemctl start neo4j${NC}"
    echo -e "  ${YELLOW}3.${NC} Start Docker: ${GREEN}sudo systemctl start docker${NC}"
    echo -e "  ${YELLOW}4.${NC} Check tools: ${GREEN}ls /opt/tools${NC}"
    echo -e "  ${YELLOW}5.${NC} View wordlists: ${GREEN}ls /usr/share/wordlists${NC}"
    echo -e "  ${YELLOW}6.${NC} ${RED}Reboot your system:${NC} ${GREEN}sudo reboot${NC}"
    echo ""
    echo -e "${CYAN}Useful aliases (after reload):${NC}"
    echo -e "  ${GREEN}web${NC}, ${GREEN}myip${NC}, ${GREEN}tools${NC}, ${GREEN}wordlists${NC}, ${GREEN}nmap-quick${NC}, ${GREEN}enum-smb${NC}, ${GREEN}metasploit${NC}, ${GREEN}kalify-update${NC}"
    echo ""
    echo -e "${CYAN}Log file:${NC} ${GREEN}${LOG_FILE}${NC}"
    echo -e "${CYAN}Work dir:${NC} ${GREEN}~/pentest${NC}"
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Happy Hacking! Stay legal, stay ethical.${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# MAIN
################################################################################

main() {
    print_banner
    parse_args "$@"
    check_root
    check_lock
    check_debian_based
    check_internet
    check_disk_space
    init_logging

    log_info "Starting Kalify v${SCRIPT_VERSION} installation..."
    log_info "Options: SSL_CHECK_DISABLED=${DISABLE_SSL_CHECK}, SKIP_OPTIONAL=${SKIP_OPTIONAL}"
    echo ""

    configure_ssl_bypass
    update_system
    install_base_deps
    install_python
    install_golang
    install_ruby
    install_docker
    install_network_tools
    install_web_tools
    install_exploitation_tools
    install_ad_tools
    install_password_tools
    install_wireless_tools
    install_forensics_tools
    install_osint_tools
    install_reverse_tools
    install_wordlists
    install_github_tools
    configure_aliases
    setup_directories
    final_cleanup
    print_completion
}

main "$@"
