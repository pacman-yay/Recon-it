#!/bin/bash

# recon-it - Unified Reconnaissance Tool
# Slogan: "it's OUR tool"
# Version: 4.2 - Full Auto-Install

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables
DOMAIN=""
USE_AMASS=false
INSTALL_MODE=false
OUTPUT_DIR=""
RAW_SUBDOMAINS=""
ALL_SUBDOMAINS=""
RESOLVED_DOMAINS=""
UNRESOLVED_DOMAINS=""
LIVE_DOMAINS=""
DEAD_DOMAINS=""

# Function: command_exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Install Go
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
    wget -q https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm go1.21.0.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    source ~/.bashrc
    
    if command_exists go; then
        echo -e "${GREEN}[+] Go installed!${NC}"
        return 0
    else
        echo -e "${RED}[-] Go installation failed${NC}"
        return 1
    fi
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
    
    # Try apt first
    if command_exists apt; then
        sudo apt install subfinder -y 2>/dev/null
        if command_exists subfinder; then
            echo -e "${GREEN}[+] Subfinder installed via apt!${NC}"
            return 0
        fi
    fi
    
    # Try Go install
    if command_exists go; then
        go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        sudo cp ~/go/bin/subfinder /usr/local/bin/ 2>/dev/null
        if command_exists subfinder; then
            echo -e "${GREEN}[+] Subfinder installed via Go!${NC}"
            return 0
        fi
    fi
    
    # Download from GitHub
    wget -q https://github.com/projectdiscovery/subfinder/releases/download/v2.6.6/subfinder_2.6.6_linux_amd64.zip
    if [[ -f "subfinder_2.6.6_linux_amd64.zip" ]]; then
        unzip -q subfinder_2.6.6_linux_amd64.zip
        sudo mv subfinder /usr/local/bin/
        rm subfinder_2.6.6_linux_amd64.zip
        sudo chmod +x /usr/local/bin/subfinder
        if command_exists subfinder; then
            echo -e "${GREEN}[+] Subfinder installed from GitHub!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] Subfinder installation failed${NC}"
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
    
    # Try apt first
    if command_exists apt; then
        sudo apt install httpx -y 2>/dev/null
        if command_exists httpx; then
            echo -e "${GREEN}[+] HTTPX installed via apt!${NC}"
            return 0
        fi
    fi
    
    # Try Go install
    if command_exists go; then
        go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
        sudo cp ~/go/bin/httpx /usr/local/bin/ 2>/dev/null
        if command_exists httpx; then
            echo -e "${GREEN}[+] HTTPX installed via Go!${NC}"
            return 0
        fi
    fi
    
    # Download from GitHub
    wget -q https://github.com/projectdiscovery/httpx/releases/download/v1.3.9/httpx_1.3.9_linux_amd64.zip
    if [[ -f "httpx_1.3.9_linux_amd64.zip" ]]; then
        unzip -q httpx_1.3.9_linux_amd64.zip
        sudo mv httpx /usr/local/bin/
        rm httpx_1.3.9_linux_amd64.zip
        sudo chmod +x /usr/local/bin/httpx
        if command_exists httpx; then
            echo -e "${GREEN}[+] HTTPX installed from GitHub!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] HTTPX installation failed${NC}"
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
    
    # Try apt first
    if command_exists apt; then
        sudo apt install dnsrecon -y 2>/dev/null
        if command_exists dnsrecon; then
            echo -e "${GREEN}[+] DNSRecon installed via apt!${NC}"
            return 0
        fi
    fi
    
    # Try pip
    if command_exists pip3; then
        sudo pip3 install dnsrecon --break-system-packages 2>/dev/null
        if command_exists dnsrecon; then
            echo -e "${GREEN}[+] DNSRecon installed via pip!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] DNSRecon installation failed${NC}"
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
    
    # Try apt first
    if command_exists apt; then
        sudo apt install amass -y 2>/dev/null
        if command_exists amass; then
            echo -e "${GREEN}[+] Amass installed via apt!${NC}"
            return 0
        fi
    fi
    
    # Try Go install
    if ! command_exists go; then
        install_go || return 1
    fi
    
    if command_exists go; then
        go install -v github.com/owasp-amass/amass/v4/...@master
        sudo cp ~/go/bin/amass /usr/local/bin/ 2>/dev/null
        if command_exists amass; then
            echo -e "${GREEN}[+] Amass installed via Go!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] Amass installation failed${NC}"
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
    
    if command_exists go; then
        go install github.com/tomnomnom/assetfinder@latest
        sudo cp ~/go/bin/assetfinder /usr/local/bin/ 2>/dev/null
        if command_exists assetfinder; then
            echo -e "${GREEN}[+] Assetfinder installed!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[-] Assetfinder installation failed${NC}"
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
    
    # Install dependencies
    if command_exists pip3; then
        sudo pip3 install requests dnspython --break-system-packages 2>/dev/null
    fi
    
    # Clone and install
    if [[ -d "/tmp/Sublist3r" ]]; then
        rm -rf /tmp/Sublist3r
    fi
    
    git clone https://github.com/aboul3la/Sublist3r.git /tmp/Sublist3r
    cd /tmp/Sublist3r
    sudo python3 setup.py install 2>/dev/null
    cd ..
    rm -rf /tmp/Sublist3r
    
    if command_exists sublist3r; then
        echo -e "${GREEN}[+] Sublist3r installed!${NC}"
        return 0
    else
        echo -e "${RED}[-] Sublist3r installation failed${NC}"
        return 1
    fi
}

# Install all tools
install_all_tools() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       INSTALLING ALL TOOLS${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${CYAN}[*] Installing base packages...${NC}"
    sudo apt update 2>/dev/null
    sudo apt install whois dnsutils curl unzip git -y 2>/dev/null
    
    echo -e "\n${CYAN}[*] Installing Python tools...${NC}"
    if ! command_exists pip3; then
        sudo apt install python3-pip -y 2>/dev/null
    fi
    
    install_subfinder
    install_httpx
    install_dnsrecon
    install_amass
    install_assetfinder
    install_sublist3r
    
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       INSTALLATION COMPLETE${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
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
    echo "    ║              ██╗████████╗                                   ║"
    echo "    ║              ██║╚══██╔══╝                                   ║"
    echo "    ║              ██║   ██║                                      ║"
    echo "    ║              ██║   ██║                                      ║"
    echo "    ║              ██║   ██║                                      ║"
    echo "    ║              ╚═╝   ╚═╝                                      ║"
    echo "    ║                                                              ║"
    echo "    ║           ╔══════════════════════════════════════╗           ║"
    echo "    ║           ║       recon-it v4.2                ║           ║"
    echo "    ║           ║       it's OUR tool                ║           ║"
    echo "    ║           ╚══════════════════════════════════════╝           ║"
    echo "    ║                                                              ║"
    echo "    ║     Phase 1: WHOIS → DNS → DNSDumpster                     ║"
    echo "    ║     Phase 2: Subdomain Enumeration (Fast)                  ║"
    echo "    ║     Phase 3: Filter & Resolve                              ║"
    echo "    ║     Phase 4: HTTP Probing                                  ║"
    echo "    ║                                                              ║"
    echo "    ║     --install  Auto-install all tools                      ║"
    echo "    ║     --amass    Enable Amass (deeper enumeration)           ║"
    echo "    ║                                                              ║"
    echo "    ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Spinner
spinner() {
    local pid=$1
    local message=$2
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        printf "\r${CYAN}[%s]${NC} %s" "${spin:$i:1}" "$message"
        sleep 0.1
    done
    wait $pid
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        printf "\r${GREEN}[✓]${NC} %s - Done!    \n" "$message"
    else
        printf "\r${RED}[✗]${NC} %s - Failed!   \n" "$message"
    fi
    return $exit_code
}

# Initialize output
init_output() {
    OUTPUT_DIR="recon_${DOMAIN}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$OUTPUT_DIR"
    RAW_SUBDOMAINS="$OUTPUT_DIR/raw_subdomains.txt"
    ALL_SUBDOMAINS="$OUTPUT_DIR/all_subdomains.txt"
    RESOLVED_DOMAINS="$OUTPUT_DIR/resolved.txt"
    UNRESOLVED_DOMAINS="$OUTPUT_DIR/unresolved.txt"
    LIVE_DOMAINS="$OUTPUT_DIR/live.txt"
    DEAD_DOMAINS="$OUTPUT_DIR/dead.txt"
    
    echo "# recon-it v4.2 - Scan Results" > "$OUTPUT_DIR/README.txt"
    echo "# Domain: $DOMAIN" >> "$OUTPUT_DIR/README.txt"
    echo "# Started: $(date)" >> "$OUTPUT_DIR/README.txt"
    echo "# Amass: $USE_AMASS" >> "$OUTPUT_DIR/README.txt"
    echo "========================================" >> "$OUTPUT_DIR/README.txt"
    echo "" >> "$OUTPUT_DIR/README.txt"
    
    echo -e "${GREEN}[+] Output directory: $OUTPUT_DIR${NC}"
    echo -e "${GREEN}[+] Results will be saved to:${NC}"
    echo -e "  ${CYAN}→${NC} Raw subdomains: $RAW_SUBDOMAINS"
    echo -e "  ${CYAN}→${NC} All subdomains: $ALL_SUBDOMAINS"
    echo -e "  ${CYAN}→${NC} Resolved: $RESOLVED_DOMAINS"
    echo -e "  ${CYAN}→${NC} Unresolved: $UNRESOLVED_DOMAINS"
    echo -e "  ${CYAN}→${NC} Live: $LIVE_DOMAINS"
    echo -e "  ${CYAN}→${NC} Dead: $DEAD_DOMAINS"
    echo ""
}

# PHASE 1: Basic Info
phase1_basic_info() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       PHASE 1: BASIC INFORMATION${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
    # WHOIS
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[1/3] WHOIS Lookup${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[*]${NC} Querying WHOIS database for ${GREEN}$DOMAIN${NC}"
    
    (
        whois "$DOMAIN" 2>/dev/null | head -50 > "$OUTPUT_DIR/whois.txt"
    ) &
    spinner $! "WHOIS lookup in progress"
    
    if [[ -f "$OUTPUT_DIR/whois.txt" ]] && [[ -s "$OUTPUT_DIR/whois.txt" ]]; then
        echo -e "\n${GREEN}[+] WHOIS Results:${NC}"
        echo "================================================"
        cat "$OUTPUT_DIR/whois.txt"
        echo "================================================"
        echo "[+] WHOIS saved to: $OUTPUT_DIR/whois.txt"
    fi
    
    # DNSRecon
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[2/3] DNSRecon${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[*]${NC} Running DNSRecon for ${GREEN}$DOMAIN${NC}"
    
    if command_exists dnsrecon; then
        (
            timeout 60 dnsrecon -d "$DOMAIN" -t std 2>&1 > "$OUTPUT_DIR/dnsrecon.txt"
        ) &
        spinner $! "DNSRecon enumeration in progress"
        
        if [[ -f "$OUTPUT_DIR/dnsrecon.txt" ]] && [[ -s "$OUTPUT_DIR/dnsrecon.txt" ]]; then
            echo -e "\n${GREEN}[+] DNSRecon Results:${NC}"
            echo "================================================"
            head -30 "$OUTPUT_DIR/dnsrecon.txt"
            echo "================================================"
            echo "[+] DNSRecon saved to: $OUTPUT_DIR/dnsrecon.txt"
        fi
    else
        echo -e "\n${YELLOW}[!] DNSRecon not installed${NC}"
    fi
    
    # DNSDumpster
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[3/3] DNSDumpster${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[*]${NC} Querying DNSDumpster for ${GREEN}$DOMAIN${NC}"
    
    (
        token=$(curl -s -c /tmp/cookies.txt -H "User-Agent: Mozilla/5.0" "https://dnsdumpster.com" 2>/dev/null | grep -oP 'csrfmiddlewaretoken" value="\K[^"]+' | head -1)
        if [[ -n "$token" ]]; then
            curl -s -b /tmp/cookies.txt -X POST -H "User-Agent: Mozilla/5.0" -H "Referer: https://dnsdumpster.com" -H "X-CSRFToken: $token" -d "csrfmiddlewaretoken=$token&targetip=$DOMAIN" "https://dnsdumpster.com" > "$OUTPUT_DIR/dnsdumpster.txt" 2>/dev/null
            rm -f /tmp/cookies.txt
        fi
    ) &
    spinner $! "DNSDumpster enumeration in progress"
    
    if [[ -f "$OUTPUT_DIR/dnsdumpster.txt" ]] && [[ -s "$OUTPUT_DIR/dnsdumpster.txt" ]]; then
        echo -e "\n${GREEN}[+] DNSDumpster Results:${NC}"
        echo "================================================"
        grep -oP '<td class="col-md-4">\K[^<]+' "$OUTPUT_DIR/dnsdumpster.txt" 2>/dev/null | head -20
        echo "================================================"
        echo "[+] DNSDumpster saved to: $OUTPUT_DIR/dnsdumpster.txt"
    else
        echo -e "\n${YELLOW}[!] DNSDumpster API unavailable${NC}"
    fi
}

# PHASE 2: Subdomain Enumeration
phase2_subdomain_enum() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       PHASE 2: SUBDOMAIN ENUMERATION${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
    # Initialize raw subdomains file
    echo "# Raw Subdomains from all tools" > "$RAW_SUBDOMAINS"
    echo "# Domain: $DOMAIN" >> "$RAW_SUBDOMAINS"
    echo "# Generated: $(date)" >> "$RAW_SUBDOMAINS"
    echo "========================================" >> "$RAW_SUBDOMAINS"
    echo "" >> "$RAW_SUBDOMAINS"
    
    # Subfinder
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[1/3] Subfinder${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[*]${NC} Discovering subdomains for ${GREEN}$DOMAIN${NC}"
    
    if command_exists subfinder; then
        echo -e "${CYAN}[*]${NC} Subfinder is scanning... (timeout: 120s)"
        (
            timeout 120 subfinder -d "$DOMAIN" -silent 2>/dev/null | tee -a "$RAW_SUBDOMAINS" > /dev/null
        ) &
        spinner $! "Subfinder scanning for subdomains"
        
        local count=$(grep -v "^#" "$RAW_SUBDOMAINS" | grep -v "^$" | wc -l)
        echo -e "${GREEN}[+] Subfinder found $count subdomains so far${NC}"
    else
        echo -e "\n${RED}[!] Subfinder not installed${NC}"
    fi
    
    # Sublist3r
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[2/3] Sublist3r${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[*]${NC} Running Sublist3r for ${GREEN}$DOMAIN${NC}"
    
    if command_exists sublist3r; then
        echo -e "${CYAN}[*]${NC} Sublist3r is scanning... (timeout: 120s)"
        (
            timeout 120 sublist3r -d $DOMAIN -t 10 2>/dev/null | grep -E "\\." | grep -v "Enumerating\|Searching\|Total" | tee -a "$RAW_SUBDOMAINS" > /dev/null
        ) &
        spinner $! "Sublist3r brute-forcing subdomains"
        
        local count=$(grep -v "^#" "$RAW_SUBDOMAINS" | grep -v "^$" | wc -l)
        echo -e "${GREEN}[+] Sublist3r found additional subdomains. Total: $count${NC}"
    else
        echo -e "\n${RED}[!] Sublist3r not installed${NC}"
    fi
    
    # Assetfinder
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[3/3] Assetfinder${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[*]${NC} Running Assetfinder for ${GREEN}$DOMAIN${NC}"
    
    if command_exists assetfinder; then
        echo -e "${CYAN}[*]${NC} Assetfinder is scanning..."
        (
            assetfinder --subs-only $DOMAIN 2>/dev/null | tee -a "$RAW_SUBDOMAINS" > /dev/null
        ) &
        spinner $! "Assetfinder discovering subdomains"
        
        local count=$(grep -v "^#" "$RAW_SUBDOMAINS" | grep -v "^$" | wc -l)
        echo -e "${GREEN}[+] Assetfinder found additional subdomains. Total: $count${NC}"
    else
        echo -e "\n${RED}[!] Assetfinder not installed${NC}"
    fi
    
    # Optional: Amass
    if [[ "$USE_AMASS" == "true" ]]; then
        echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC} ${CYAN}[4/4] Amass (Optional)${NC} ${YELLOW}│${NC}"
        echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
        echo -e "${CYAN}[*]${NC} Running Amass for ${GREEN}$DOMAIN${NC}"
        
        if command_exists amass; then
            echo -e "${CYAN}[*]${NC} Amass is scanning... (timeout: 180s)"
            (
                timeout 180 amass enum -d "$DOMAIN" -passive 2>/dev/null | tee -a "$RAW_SUBDOMAINS" > /dev/null
            ) &
            spinner $! "Amass enumerating subdomains"
            
            local count=$(grep -v "^#" "$RAW_SUBDOMAINS" | grep -v "^$" | wc -l)
            echo -e "${GREEN}[+] Amass found additional subdomains. Total: $count${NC}"
        else
            echo -e "\n${RED}[!] Amass not installed${NC}"
        fi
    else
        echo -e "\n${YELLOW}[!] Amass skipped (use --amass to enable)${NC}"
    fi
    
    echo -e "\n${GREEN}[+] Raw subdomains saved to: $RAW_SUBDOMAINS${NC}"
}

# PHASE 3: Filter and Resolve
phase3_filter_resolve() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       PHASE 3: FILTER & RESOLVE${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
    # Remove duplicates
    echo -e "\n${CYAN}[*]${NC} Removing duplicate subdomains..."
    
    grep -v "^#" "$RAW_SUBDOMAINS" | \
    grep -v "^$" | \
    sort -u > "$ALL_SUBDOMAINS"
    
    local total=$(wc -l < "$ALL_SUBDOMAINS")
    echo -e "${GREEN}[+] Total unique subdomains: $total${NC}"
    echo -e "${GREEN}[+] Saved to: $ALL_SUBDOMAINS${NC}"
    
    if [[ $total -eq 0 ]]; then
        echo -e "\n${YELLOW}[!] No subdomains found to resolve${NC}"
        return
    fi
    
    # Resolve DNS
    echo -e "\n${CYAN}[*]${NC} Resolving DNS for $total subdomains..."
    echo -e "${CYAN}[*]${NC} This may take a while..."
    
    > "$RESOLVED_DOMAINS"
    > "$UNRESOLVED_DOMAINS"
    
    local resolved=0
    local unresolved=0
    local total_count=$total
    
    while IFS= read -r subdomain; do
        ip=$(dig +short "$subdomain" A 2>/dev/null | head -1)
        if [[ -n "$ip" ]]; then
            echo "$subdomain,$ip" >> "$RESOLVED_DOMAINS"
            ((resolved++))
        else
            ip6=$(dig +short "$subdomain" AAAA 2>/dev/null | head -1)
            if [[ -n "$ip6" ]]; then
                echo "$subdomain,$ip6" >> "$RESOLVED_DOMAINS"
                ((resolved++))
            else
                echo "$subdomain" >> "$UNRESOLVED_DOMAINS"
                ((unresolved++))
            fi
        fi
        
        local processed=$((resolved + unresolved))
        local percentage=$((processed * 100 / total_count))
        printf "\r${CYAN}[*]${NC} Progress: ${GREEN}%3d%%${NC} | Resolved: ${GREEN}%4d${NC} | Unresolved: ${YELLOW}%4d${NC}" "$percentage" "$resolved" "$unresolved"
    done < "$ALL_SUBDOMAINS"
    
    echo ""
    echo -e "\n${GREEN}[+] DNS Resolution Complete!${NC}"
    echo -e "  ${GREEN}✓${NC} Resolved: $resolved (saved to $RESOLVED_DOMAINS)"
    echo -e "  ${RED}✗${NC} Unresolved: $unresolved (saved to $UNRESOLVED_DOMAINS)"
}

# PHASE 4: HTTP Probing
phase4_http_probe() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       PHASE 4: HTTP PROBING${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
    if [[ ! -f "$RESOLVED_DOMAINS" ]] || [[ ! -s "$RESOLVED_DOMAINS" ]]; then
        echo -e "${YELLOW}[!] No resolved domains to probe${NC}"
        return
    fi
    
    cut -d',' -f1 "$RESOLVED_DOMAINS" > "$OUTPUT_DIR/resolved_domains_only.txt"
    local count=$(wc -l < "$OUTPUT_DIR/resolved_domains_only.txt")
    
    echo -e "${CYAN}[*]${NC} Probing $count resolved domains with HTTPX..."
    
    if command_exists httpx; then
        echo -e "\n${CYAN}[*]${NC} Finding live domains (HTTP 200)..."
        (
            httpx -l "$OUTPUT_DIR/resolved_domains_only.txt" \
                  -status-code -title -tech-detect \
                  -silent 2>/dev/null | \
                  grep -E "\[200\]" > "$LIVE_DOMAINS"
        ) &
        spinner $! "HTTPX probing for live domains"
        
        echo -e "\n${CYAN}[*]${NC} Capturing all HTTP responses..."
        (
            httpx -l "$OUTPUT_DIR/resolved_domains_only.txt" \
                  -status-code -title -tech-detect \
                  -silent 2>/dev/null > "$DEAD_DOMAINS"
        ) &
        spinner $! "HTTPX capturing all responses"
        
        local live_count=$(wc -l < "$LIVE_DOMAINS" 2>/dev/null || echo "0")
        local dead_count=$(wc -l < "$DEAD_DOMAINS" 2>/dev/null || echo "0")
        
        echo -e "\n${GREEN}[+] HTTP Probing Complete!${NC}"
        echo -e "  ${GREEN}✓${NC} Live domains (200 OK): $live_count (saved to $LIVE_DOMAINS)"
        echo -e "  ${YELLOW}○${NC} All responses: $dead_count (saved to $DEAD_DOMAINS)"
        
        if [[ $live_count -gt 0 ]]; then
            echo -e "\n${CYAN}[*] Sample of live domains:${NC}"
            head -5 "$LIVE_DOMAINS"
        fi
    else
        echo -e "${RED}[!] HTTPX not installed${NC}"
    fi
}

# Generate Summary
generate_report() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       SCAN SUMMARY${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
    {
        echo "========================================"
        echo "recon-it v4.2 - Scan Summary"
        echo "========================================"
        echo ""
        echo "Domain: $DOMAIN"
        echo "Date: $(date)"
        echo "Output Directory: $OUTPUT_DIR"
        echo "Amass Enabled: $USE_AMASS"
        echo ""
        echo "--- Subdomain Statistics ---"
        echo "Raw subdomains found: $(grep -v "^#" "$RAW_SUBDOMAINS" 2>/dev/null | grep -v "^$" | wc -l)"
        echo "Unique subdomains: $(wc -l < "$ALL_SUBDOMAINS" 2>/dev/null)"
        echo "Resolved domains: $(wc -l < "$RESOLVED_DOMAINS" 2>/dev/null)"
        echo "Unresolved domains: $(wc -l < "$UNRESOLVED_DOMAINS" 2>/dev/null)"
        echo "Live domains (200 OK): $(wc -l < "$LIVE_DOMAINS" 2>/dev/null)"
        echo ""
        echo "--- Files Generated ---"
        echo "1. $RAW_SUBDOMAINS - Raw subdomains"
        echo "2. $ALL_SUBDOMAINS - Unique subdomains"
        echo "3. $RESOLVED_DOMAINS - Resolved domains with IPs"
        echo "4. $UNRESOLVED_DOMAINS - Unresolved domains"
        echo "5. $LIVE_DOMAINS - Live domains (HTTP 200)"
        echo "6. $DEAD_DOMAINS - All HTTP responses"
        echo ""
    } | tee "$OUTPUT_DIR/SUMMARY.txt"
    
    echo -e "\n${GREEN}[+] Summary saved to: $OUTPUT_DIR/SUMMARY.txt${NC}"
}

# Help
show_help() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./recon-it.sh [OPTIONS] -d <domain>"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --install                   Auto-install all missing tools"
    echo "  -d, --domain <domain>       Target domain"
    echo "  --amass                     Enable Amass (slower but deeper)"
    echo "  -h, --help                  Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  # Install all tools first"
    echo "  ./recon-it.sh --install"
    echo ""
    echo "  # Quick scan (without Amass)"
    echo "  ./recon-it.sh -d example.com"
    echo ""
    echo "  # Deep scan (with Amass)"
    echo "  ./recon-it.sh -d example.com --amass"
}

# Main
main() {
    DOMAIN=""
    USE_AMASS=false
    INSTALL_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install)
                INSTALL_MODE=true
                shift
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            --amass)
                USE_AMASS=true
                shift
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
    
    # Handle installation mode
    if [[ "$INSTALL_MODE" == "true" ]]; then
        install_all_tools
        echo -e "${GREEN}[+] Installation complete!${NC}"
        echo -e "${YELLOW}[!] Run without --install to start scanning${NC}"
        exit 0
    fi
    
    # Check if domain provided
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}[!] Domain required${NC}"
        show_help
        exit 1
    fi
    
    init_output
    
    echo -e "${CYAN}[*]${NC} Configuration:"
    echo -e "  ${CYAN}→${NC} Domain: ${GREEN}$DOMAIN${NC}"
    echo -e "  ${CYAN}→${NC} Amass: ${GREEN}$USE_AMASS${NC}"
    echo -e "  ${CYAN}→${NC} Output: ${GREEN}$OUTPUT_DIR${NC}"
    echo ""
    
    phase1_basic_info
    phase2_subdomain_enum
    phase3_filter_resolve
    phase4_http_probe
    generate_report
    
    echo -e "\n${GREEN}[+] Scan completed at $(date)${NC}"
    echo -e "${RED}[+] it's OUR tool!${NC}"
    echo -e "\n${CYAN}[*] Results saved to: $OUTPUT_DIR/${NC}"
    echo -e "${CYAN}[*] View summary: cat $OUTPUT_DIR/SUMMARY.txt${NC}"
}

main "$@"
