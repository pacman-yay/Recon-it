#!/bin/bash

# recon-it - Unified Reconnaissance Tool
# Slogan: "it's OUR tool"
# Version: 3.2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables
LOG_FILE=""
LOG_LEVEL="INFO"
VERBOSE=false
QUIET=false
AUTO_INSTALL=false
SKIP_INSTALL=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Banner
show_banner() {
    echo -e "${RED}"
    echo "    ╔══════════════════════════════════════════════════════════════╗"
    echo "    ║                                                              ║"
    echo "    ║    ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗              ║"
    echo "    ║    ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║              ║"
    echo "    ║    ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║              ║"
    echo "    ║    ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║              ║"
    echo "    ║    ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║              ║"
    echo "    ║    ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝              ║"
    echo "    ║              ██╗████████╗                                 ║"
    echo "    ║              ██║╚══██╔══╝                                 ║"
    echo "    ║              ██║   ██║                                    ║"
    echo "    ║              ██║   ██║                                    ║"
    echo "    ║              ██║   ██║                                    ║"
    echo "    ║              ╚═╝   ╚═╝                                    ║"
    echo "    ║                                                              ║"
    echo "    ║           ╔══════════════════════════════════════╗           ║"
    echo "    ║           ║       recon-it v3.2                ║           ║"
    echo "    ║           ║       it's OUR tool                ║           ║"
    echo "    ║           ╚══════════════════════════════════════╝           ║"
    echo "    ║                                                              ║"
    echo "    ║     Amass | Assetfinder | Sublist3r | Subfinder             ║"
    echo "    ║     DNSRecon | DNSDumpster | HTTPX | WHOIS                 ║"
    echo "    ║                                                              ║"
    echo "    ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Prompt for yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    
    while true; do
        read -p "$prompt [y/N]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) 
                [[ "$default" == "y" ]] && return 0 || return 1
                ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and package manager
detect_os() {
    if command_exists apt; then
        echo "debian"
    elif command_exists yum; then
        echo "rhel"
    elif command_exists dnf; then
        echo "fedora"
    elif command_exists pacman; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Install base system packages
install_system_package() {
    local package=$1
    local os=$(detect_os)
    
    case $os in
        debian)
            sudo apt install -y "$package" 2>/dev/null
            ;;
        rhel|fedora)
            sudo yum install -y "$package" 2>/dev/null
            ;;
        arch)
            sudo pacman -S --noconfirm "$package" 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Install Go with proper error handling
install_go() {
    if command_exists go; then
        echo -e "${GREEN}[+] Go already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] Go not found. Required for Amass and Assetfinder.${NC}"
    if ! prompt_yes_no "Install Go?"; then
        echo -e "${YELLOW}[!] Skipping Go installation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Installing Go...${NC}"
    
    sudo rm -rf /usr/local/go
    
    local go_version="1.21.0"
    local go_arch="amd64"
    
    if [[ "$(uname -m)" == "aarch64" ]]; then
        go_arch="arm64"
    fi
    
    wget -q --show-progress "https://golang.org/dl/go${go_version}.linux-${go_arch}.tar.gz" -O go.tar.gz
    
    if [[ ! -f "go.tar.gz" ]]; then
        echo -e "${RED}[-] Failed to download Go${NC}"
        return 1
    fi
    
    sudo tar -C /usr/local -xzf go.tar.gz
    rm go.tar.gz
    
    export PATH=$PATH:/usr/local/go/bin
    export PATH=$PATH:$HOME/go/bin
    
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    fi
    
    source ~/.bashrc
    
    if command_exists go; then
        echo -e "${GREEN}[+] Go installed successfully!${NC}"
        return 0
    else
        echo -e "${RED}[-] Go installation failed${NC}"
        return 1
    fi
}

# Install unzip if missing
ensure_unzip() {
    if ! command_exists unzip; then
        echo -e "${YELLOW}[!] unzip not found. Required for extracting tools.${NC}"
        if prompt_yes_no "Install unzip?"; then
            echo -e "${GREEN}[+] Installing unzip...${NC}"
            install_system_package "unzip"
            if command_exists unzip; then
                echo -e "${GREEN}[+] unzip installed!${NC}"
                return 0
            else
                echo -e "${RED}[-] Failed to install unzip${NC}"
                return 1
            fi
        else
            echo -e "${RED}[-] unzip is required. Cannot continue.${NC}"
            exit 1
        fi
    fi
    return 0
}

# Install pip3 if missing
ensure_pip3() {
    if ! command_exists pip3; then
        echo -e "${YELLOW}[!] pip3 not found. Required for Python tools.${NC}"
        if prompt_yes_no "Install pip3?"; then
            echo -e "${GREEN}[+] Installing pip3...${NC}"
            install_system_package "python3-pip"
            if command_exists pip3; then
                echo -e "${GREEN}[+] pip3 installed!${NC}"
                return 0
            else
                echo -e "${YELLOW}[!] Failed to install pip3 via package manager. Trying Python script...${NC}"
                curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                sudo python3 get-pip.py
                rm get-pip.py
                if command_exists pip3; then
                    echo -e "${GREEN}[+] pip3 installed via script!${NC}"
                    return 0
                else
                    echo -e "${RED}[-] Failed to install pip3${NC}"
                    return 1
                fi
            fi
        else
            echo -e "${YELLOW}[!] Skipping pip3 installation. Some tools may not work.${NC}"
            return 1
        fi
    fi
    return 0
}

# Install Subfinder
install_subfinder() {
    if command_exists subfinder; then
        echo -e "${GREEN}[+] Subfinder already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] Subfinder not found.${NC}"
    if ! prompt_yes_no "Install Subfinder?"; then
        echo -e "${YELLOW}[!] Skipping Subfinder installation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Installing Subfinder...${NC}"
    ensure_unzip || return 1
    
    if command_exists apt; then
        echo -e "${CYAN}[*] Trying apt install...${NC}"
        sudo apt install subfinder -y 2>/dev/null
        if command_exists subfinder; then
            echo -e "${GREEN}[+] Subfinder installed via apt!${NC}"
            return 0
        fi
    fi
    
    echo -e "${CYAN}[*] Downloading from GitHub...${NC}"
    local url="https://github.com/projectdiscovery/subfinder/releases/latest/download/subfinder-linux-amd64.zip"
    
    if ! wget -q "$url" -O subfinder.zip; then
        curl -L -o subfinder.zip "$url" 2>/dev/null
    fi
    
    if [[ -f "subfinder.zip" ]]; then
        unzip -q subfinder.zip
        sudo mv subfinder /usr/local/bin/
        rm subfinder.zip
        sudo chmod +x /usr/local/bin/subfinder
        
        if command_exists subfinder; then
            echo -e "${GREEN}[+] Subfinder installed!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] Subfinder installation failed.${NC}"
    return 1
}

# Install HTTPX
install_httpx() {
    if command_exists httpx; then
        echo -e "${GREEN}[+] HTTPX already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] HTTPX not found.${NC}"
    if ! prompt_yes_no "Install HTTPX?"; then
        echo -e "${YELLOW}[!] Skipping HTTPX installation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Installing HTTPX...${NC}"
    ensure_unzip || return 1
    
    if command_exists apt; then
        echo -e "${CYAN}[*] Trying apt install...${NC}"
        sudo apt install httpx -y 2>/dev/null
        if command_exists httpx; then
            echo -e "${GREEN}[+] HTTPX installed via apt!${NC}"
            return 0
        fi
    fi
    
    echo -e "${CYAN}[*] Downloading from GitHub...${NC}"
    local url="https://github.com/projectdiscovery/httpx/releases/latest/download/httpx-linux-amd64.zip"
    
    if ! wget -q "$url" -O httpx.zip; then
        curl -L -o httpx.zip "$url" 2>/dev/null
    fi
    
    if [[ -f "httpx.zip" ]]; then
        unzip -q httpx.zip
        sudo mv httpx /usr/local/bin/
        rm httpx.zip
        sudo chmod +x /usr/local/bin/httpx
        
        if command_exists httpx; then
            echo -e "${GREEN}[+] HTTPX installed!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] HTTPX installation failed.${NC}"
    return 1
}

# Install DNSRecon
install_dnsrecon() {
    if command_exists dnsrecon; then
        echo -e "${GREEN}[+] DNSRecon already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] DNSRecon not found.${NC}"
    if ! prompt_yes_no "Install DNSRecon?"; then
        echo -e "${YELLOW}[!] Skipping DNSRecon installation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Installing DNSRecon...${NC}"
    ensure_pip3 || return 1
    
    if command_exists apt; then
        echo -e "${CYAN}[*] Trying apt install...${NC}"
        sudo apt install dnsrecon -y 2>/dev/null
        if command_exists dnsrecon; then
            echo -e "${GREEN}[+] DNSRecon installed via apt!${NC}"
            return 0
        fi
    fi
    
    echo -e "${CYAN}[*] Trying pip install...${NC}"
    if sudo pip3 install dnsrecon --break-system-packages 2>/dev/null; then
        if command_exists dnsrecon; then
            echo -e "${GREEN}[+] DNSRecon installed via pip!${NC}"
            return 0
        fi
    fi
    
    if sudo pip3 install dnsrecon 2>/dev/null; then
        if command_exists dnsrecon; then
            echo -e "${GREEN}[+] DNSRecon installed via pip!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] DNSRecon installation failed.${NC}"
    return 1
}

# Install Amass
install_amass() {
    if command_exists amass; then
        echo -e "${GREEN}[+] Amass already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] Amass not found.${NC}"
    if ! prompt_yes_no "Install Amass?"; then
        echo -e "${YELLOW}[!] Skipping Amass installation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Installing Amass...${NC}"
    
    if command_exists apt; then
        echo -e "${CYAN}[*] Trying apt install...${NC}"
        sudo apt update 2>/dev/null
        sudo apt install amass -y 2>/dev/null
        if command_exists amass; then
            echo -e "${GREEN}[+] Amass installed via apt!${NC}"
            return 0
        fi
    fi
    
    echo -e "${CYAN}[*] Trying Go install...${NC}"
    if ! command_exists go; then
        install_go || return 1
    fi
    
    source ~/.bashrc
    
    if command_exists go; then
        for module in "github.com/owasp-amass/amass/v4/...@master" "github.com/OWASP/Amass/v3/...@master"; do
            echo -e "${CYAN}[*] Trying: $module${NC}"
            if go install -v "$module" 2>&1 | tail -3; then
                export PATH=$PATH:$HOME/go/bin
                echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
                if command_exists amass; then
                    echo -e "${GREEN}[+] Amass installed via Go!${NC}"
                    return 0
                fi
            fi
        done
    fi
    
    echo -e "${RED}[-] Amass installation failed.${NC}"
    return 1
}

# Install Assetfinder
install_assetfinder() {
    if command_exists assetfinder; then
        echo -e "${GREEN}[+] Assetfinder already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] Assetfinder not found.${NC}"
    if ! prompt_yes_no "Install Assetfinder?"; then
        echo -e "${YELLOW}[!] Skipping Assetfinder installation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Installing Assetfinder...${NC}"
    
    if ! command_exists go; then
        install_go || return 1
    fi
    
    source ~/.bashrc
    
    if command_exists go; then
        echo -e "${CYAN}[*] Installing Assetfinder via Go...${NC}"
        go install github.com/tomnomnom/assetfinder@latest 2>&1 | tail -3
        
        export PATH=$PATH:$HOME/go/bin
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
        
        if command_exists assetfinder; then
            echo -e "${GREEN}[+] Assetfinder installed!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] Assetfinder installation failed.${NC}"
    return 1
}

# Install Sublist3r
install_sublist3r() {
    if command_exists sublist3r; then
        echo -e "${GREEN}[+] Sublist3r already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] Sublist3r not found.${NC}"
    if ! prompt_yes_no "Install Sublist3r?"; then
        echo -e "${YELLOW}[!] Skipping Sublist3r installation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Installing Sublist3r...${NC}"
    ensure_pip3 || return 1
    
    sudo pip3 install requests dnspython --break-system-packages 2>/dev/null
    sudo pip3 install requests dnspython 2>/dev/null
    
    if [[ -d "/tmp/Sublist3r" ]]; then
        rm -rf /tmp/Sublist3r
    fi
    
    if ! git clone https://github.com/aboul3la/Sublist3r.git /tmp/Sublist3r 2>/dev/null; then
        echo -e "${RED}[-] Failed to clone Sublist3r${NC}"
        return 1
    fi
    
    cd /tmp/Sublist3r
    sudo python3 setup.py install 2>/dev/null || \
    sudo pip3 install -e . --break-system-packages 2>/dev/null || \
    sudo pip3 install -e . 2>/dev/null
    cd ..
    rm -rf /tmp/Sublist3r
    
    if command_exists sublist3r; then
        echo -e "${GREEN}[+] Sublist3r installed!${NC}"
        return 0
    else
        echo -e "${RED}[-] Sublist3r installation failed.${NC}"
        return 1
    fi
}

# Main dependency check
check_and_install_dependencies() {
    echo -e "${CYAN}[*] Checking dependencies...${NC}"
    echo ""
    
    echo -e "${CYAN}[*] Checking base packages...${NC}"
    local base_packages=()
    for pkg in whois dnsutils curl; do
        if ! command_exists $pkg; then
            base_packages+=($pkg)
        fi
    done
    
    if [[ ${#base_packages[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[!] Missing base packages: ${base_packages[*]}${NC}"
        if prompt_yes_no "Install missing base packages?"; then
            sudo apt update 2>/dev/null
            sudo apt install -y "${base_packages[@]}" 2>/dev/null
            echo -e "${GREEN}[+] Base packages installed!${NC}"
        fi
    fi
    
    echo ""
    install_subfinder
    install_httpx
    install_dnsrecon
    install_amass
    install_assetfinder
    install_sublist3r
    
    echo ""
    echo -e "${GREEN}[+] Dependency check complete!${NC}"
    echo ""
    
    echo -e "${CYAN}Installed tools:${NC}"
    for tool in whois dig curl host amass assetfinder sublist3r dnsrecon subfinder httpx; do
        if command_exists $tool; then
            echo -e "  ${GREEN}OK $tool${NC}"
        else
            echo -e "  ${RED}MISSING $tool${NC}"
        fi
    done
    echo ""
}

# Help menu
show_help() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./recon-it.sh [OPTIONS] -d <domain>"
    echo ""
    echo -e "${YELLOW}Target Options:${NC}"
    echo "  -d, --domain <domain>       Target domain"
    echo "  -f, --domain-list <file>    File with domains"
    echo ""
    echo -e "${YELLOW}Module Options:${NC}"
    echo "  -a, --all                   Run ALL modules"
    echo "  -w, --whois                 WHOIS lookup"
    echo "  -n, --dnsdumpster           DNSDumpster"
    echo "  -r, --dnsrecon              DNSRecon"
    echo "  -s, --subfinder             Subfinder"
    echo "  -m, --amass                 Amass"
    echo "  -t, --assetfinder           Assetfinder"
    echo "  -u, --sublist3r             Sublist3r"
    echo "  -x, --httpx                 HTTPX probe"
    echo ""
    echo -e "${YELLOW}Subdomain Options:${NC}"
    echo "  --subdomain-all             ALL subdomain tools"
    echo "  --subdomain-aggressive      Aggressive Amass"
    echo "  --output-subdomains <file>  Save subdomains"
    echo ""
    echo -e "${YELLOW}Installation Options:${NC}"
    echo "  --install                   Auto-install missing tools"
    echo "  --skip-install              Skip all installation prompts"
    echo ""
    echo -e "${YELLOW}Logging Options:${NC}"
    echo "  -o, --output <file>         Output file"
    echo "  -l, --log-file <file>       Log file"
    echo "  --log-level <level>         DEBUG|INFO|WARNING|ERROR"
    echo "  -v, --verbose               Verbose output"
    echo "  -q, --quiet                 Quiet mode"
    echo "  --json-log                  JSON logs"
    echo ""
    echo -e "${YELLOW}Other:${NC}"
    echo "  -h, --help                  Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./recon-it.sh --install                          # Install tools only"
    echo "  ./recon-it.sh -d example.com -a                  # Full scan"
    echo "  ./recon-it.sh -d example.com --install -a        # Install + scan"
    echo "  ./recon-it.sh -d example.com -m -t -u -s         # Subdomain tools only"
}

# Module functions
run_whois() {
    echo -e "${GREEN}[+] WHOIS Lookup${NC}"
    echo "================================================"
    whois "$DOMAIN" 2>/dev/null | head -50 || echo "No results"
    echo "================================================"
}

run_dnsdumpster() {
    echo -e "${GREEN}[+] DNSDumpster${NC}"
    echo "================================================"
    local token=$(curl -s -c /tmp/cookies.txt "https://dnsdumpster.com" | grep -oP 'csrfmiddlewaretoken" value="\K[^"]+' 2>/dev/null)
    if [[ -n "$token" ]]; then
        curl -s -b /tmp/cookies.txt -X POST -H "Referer: https://dnsdumpster.com" -H "X-CSRFToken: $token" -d "csrfmiddlewaretoken=$token&targetip=$DOMAIN" "https://dnsdumpster.com" | grep -oP '<td class="col-md-4">\K[^<]+' 2>/dev/null | head -20
        rm -f /tmp/cookies.txt
    else
        echo "DNSDumpster API unavailable"
    fi
    echo "================================================"
}

run_dnsrecon() {
    echo -e "${GREEN}[+] DNSRecon${NC}"
    echo "================================================"
    if command_exists dnsrecon; then
        dnsrecon -d "$DOMAIN" -t std 2>/dev/null | head -30
    else
        echo "DNSRecon not installed"
    fi
    echo "================================================"
}

run_subfinder() {
    echo -e "${GREEN}[+] Subfinder${NC}"
    echo "================================================"
    if command_exists subfinder; then
        subfinder -d "$DOMAIN" -silent 2>/dev/null | head -30
    else
        echo "Subfinder not installed"
    fi
    echo "================================================"
}

run_amass() {
    echo -e "${GREEN}[+] Amass${NC}"
    echo "================================================"
    if command_exists amass; then
        local cmd="amass enum -d $DOMAIN -passive"
        [[ "$AMASS_AGGRESSIVE" == "true" ]] && cmd="amass enum -d $DOMAIN -active -brute"
        eval $cmd 2>/dev/null | head -30
    else
        echo "Amass not installed"
    fi
    echo "================================================"
}

run_assetfinder() {
    echo -e "${GREEN}[+] Assetfinder${NC}"
    echo "================================================"
    if command_exists assetfinder; then
        assetfinder --subs-only $DOMAIN 2>/dev/null | head -30
    else
        echo "Assetfinder not installed"
    fi
    echo "================================================"
}

run_sublist3r() {
    echo -e "${GREEN}[+] Sublist3r${NC}"
    echo "================================================"
    if command_exists sublist3r; then
        sublist3r -d $DOMAIN -t 10 -v 2>/dev/null | grep -E "\\." | head -30
    else
        echo "Sublist3r not installed"
    fi
    echo "================================================"
}

run_httpx() {
    echo -e "${GREEN}[+] HTTPX${NC}"
    echo "================================================"
    if command_exists httpx; then
        local temp=$(mktemp)
        echo "$DOMAIN" > "$temp"
        httpx -l "$temp" -status-code -title -tech-detect -silent 2>/dev/null | head -20
        rm -f "$temp"
    else
        echo "HTTPX not installed"
    fi
    echo "================================================"
}

run_all_subdomain() {
    echo -e "${PURPLE}[*] Running ALL subdomain tools${NC}"
    echo ""
    run_subfinder
    run_amass
    run_assetfinder
    run_sublist3r
}

run_all() {
    echo -e "${PURPLE}[*] Running ALL modules${NC}"
    echo ""
    run_whois
    run_dnsdumpster
    run_dnsrecon
    run_all_subdomain
    run_httpx
}

# Main
main() {
    DOMAIN=""
    DOMAIN_LIST=""
    OUTPUT_FILE=""
    LOG_FILE=""
    LOG_LEVEL="INFO"
    VERBOSE=false
    QUIET=false
    APPEND=false
    JSON_LOG=false
    RUN_ALL=false
    RUN_WHOIS=false
    RUN_DNSDUMPSTER=false
    RUN_DNSRECON=false
    RUN_SUBFINDER=false
    RUN_AMASS=false
    RUN_ASSETFINDER=false
    RUN_SUBLIST3R=false
    RUN_HTTPX=false
    AMASS_AGGRESSIVE=false
    INSTALL_MODE=false
    SKIP_INSTALL=false
    SUBDOMAIN_OUTPUT=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install)
                INSTALL_MODE=true
                shift
                ;;
            --skip-install)
                SKIP_INSTALL=true
                shift
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -f|--domain-list)
                DOMAIN_LIST="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -l|--log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            --log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --append)
                APPEND=true
                shift
                ;;
            --json-log)
                JSON_LOG=true
                shift
                ;;
            -a|--all)
                RUN_ALL=true
                shift
                ;;
            -w|--whois)
                RUN_WHOIS=true
                shift
                ;;
            -n|--dnsdumpster)
                RUN_DNSDUMPSTER=true
                shift
                ;;
            -r|--dnsrecon)
                RUN_DNSRECON=true
                shift
                ;;
            -s|--subfinder)
                RUN_SUBFINDER=true
                shift
                ;;
            -m|--amass)
                RUN_AMASS=true
                shift
                ;;
            -t|--assetfinder)
                RUN_ASSETFINDER=true
                shift
                ;;
            -u|--sublist3r)
                RUN_SUBLIST3R=true
                shift
                ;;
            -x|--httpx)
                RUN_HTTPX=true
                shift
                ;;
            --subdomain-all)
                RUN_SUBFINDER=true
                RUN_AMASS=true
                RUN_ASSETFINDER=true
                RUN_SUBLIST3R=true
                shift
                ;;
            --subdomain-aggressive)
                AMASS_AGGRESSIVE=true
                RUN_AMASS=true
                shift
                ;;
            --output-subdomains)
                SUBDOMAIN_OUTPUT="$2"
                shift 2
                ;;
            -h|--help)
                show_banner
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done

    show_banner
    
    if [[ "$INSTALL_MODE" == "true" ]]; then
        echo -e "${CYAN}[*] Installation mode activated${NC}"
        echo ""
        check_and_install_dependencies
        echo -e "${GREEN}[+] Installation complete!${NC}"
        echo -e "${YELLOW}[!] Run without --install to start scanning${NC}"
        exit 0
    fi
    
    if [[ -z "$DOMAIN" ]] && [[ -z "$DOMAIN_LIST" ]]; then
        echo -e "${RED}[!] Domain required${NC}"
        show_help
        exit 1
    fi
    
    if [[ "$SKIP_INSTALL" != "true" ]]; then
        check_and_install_dependencies
    fi
    
    if [[ "$RUN_ALL" == "false" ]] && [[ "$RUN_WHOIS" == "false" ]] && [[ "$RUN_DNSDUMPSTER" == "false" ]] && [[ "$RUN_DNSRECON" == "false" ]] && [[ "$RUN_SUBFINDER" == "false" ]] && [[ "$RUN_AMASS" == "false" ]] && [[ "$RUN_ASSETFINDER" == "false" ]] && [[ "$RUN_SUBLIST3R" == "false" ]] && [[ "$RUN_HTTPX" == "false" ]]; then
        RUN_ALL=true
    fi
    
    echo ""
    echo -e "${CYAN}[*] Starting scan for $DOMAIN${NC}"
    echo ""
    
    if [[ "$RUN_ALL" == "true" ]]; then
        run_all
    else
        [[ "$RUN_WHOIS" == "true" ]] && run_whois
        [[ "$RUN_DNSDUMPSTER" == "true" ]] && run_dnsdumpster
        [[ "$RUN_DNSRECON" == "true" ]] && run_dnsrecon
        [[ "$RUN_SUBFINDER" == "true" ]] && run_subfinder
        [[ "$RUN_AMASS" == "true" ]] && run_amass
        [[ "$RUN_ASSETFINDER" == "true" ]] && run_assetfinder
        [[ "$RUN_SUBLIST3R" == "true" ]] && run_sublist3r
        [[ "$RUN_HTTPX" == "true" ]] && run_httpx
    fi
    
    echo ""
    echo -e "${GREEN}[+] Scan completed${NC}"
    echo -e "${RED}[+] it's OUR tool!${NC}"
}

main "$@"
