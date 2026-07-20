#!/bin/bash

# recon-it - Unified Reconnaissance Tool
# Slogan: "it's OUR tool"
# Version: 3.5

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
SKIP_INSTALL=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Spinner animation
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

# Banner
show_banner() {
    echo -e "${RED}"
    echo "    ╔═════════════════════════════════════════════════════════════╗"
    echo "    ║                                                             ║"
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
    echo "    ║                                                             ║"
    echo "    ║           ╔══════════════════════════════════════╗          ║"
    echo "    ║           ║       recon-it v3.5                  ║          ║"
    echo "    ║           ║       it's OUR tool                  ║          ║"
    echo "    ║           ╚══════════════════════════════════════╝          ║"
    echo "    ║                                                             ║"
    echo "    ║     Amass | Assetfinder | Sublist3r | Subfinder             ║"
    echo "    ║     DNSRecon | DNSDumpster | HTTPX | WHOIS                  ║"
    echo "    ║                                                             ║"
    echo "    ╚═════════════════════════════════════════════════════════════╝"
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

# Install functions (simplified for space)
install_subfinder() { 
    if command_exists subfinder; then
        echo -e "${GREEN}[+] Subfinder already installed${NC}"
        return 0
    fi
    echo -e "${YELLOW}[!] Subfinder not found.${NC}"
    if prompt_yes_no "Install Subfinder?"; then
        sudo apt install subfinder -y 2>/dev/null || \
        wget -q https://github.com/projectdiscovery/subfinder/releases/download/v2.6.6/subfinder_2.6.6_linux_amd64.zip && \
        unzip -q subfinder_2.6.6_linux_amd64.zip && sudo mv subfinder /usr/local/bin/ && rm subfinder_2.6.6_linux_amd64.zip
        return 0
    fi
    return 1
}

install_httpx() {
    if command_exists httpx; then
        echo -e "${GREEN}[+] HTTPX already installed${NC}"
        return 0
    fi
    echo -e "${YELLOW}[!] HTTPX not found.${NC}"
    if prompt_yes_no "Install HTTPX?"; then
        sudo apt install httpx -y 2>/dev/null || \
        wget -q https://github.com/projectdiscovery/httpx/releases/download/v1.3.9/httpx_1.3.9_linux_amd64.zip && \
        unzip -q httpx_1.3.9_linux_amd64.zip && sudo mv httpx /usr/local/bin/ && rm httpx_1.3.9_linux_amd64.zip
        return 0
    fi
    return 1
}

install_dnsrecon() {
    if command_exists dnsrecon; then
        echo -e "${GREEN}[+] DNSRecon already installed${NC}"
        return 0
    fi
    echo -e "${YELLOW}[!] DNSRecon not found.${NC}"
    if prompt_yes_no "Install DNSRecon?"; then
        sudo apt install dnsrecon -y 2>/dev/null || sudo pip3 install dnsrecon --break-system-packages
        return 0
    fi
    return 1
}

install_amass() {
    if command_exists amass; then
        echo -e "${GREEN}[+] Amass already installed${NC}"
        return 0
    fi
    echo -e "${YELLOW}[!] Amass not found.${NC}"
    if prompt_yes_no "Install Amass?"; then
        sudo apt install amass -y 2>/dev/null || go install -v github.com/owasp-amass/amass/v4/...@master
        return 0
    fi
    return 1
}

install_assetfinder() {
    if command_exists assetfinder; then
        echo -e "${GREEN}[+] Assetfinder already installed${NC}"
        return 0
    fi
    echo -e "${YELLOW}[!] Assetfinder not found.${NC}"
    if prompt_yes_no "Install Assetfinder?"; then
        go install github.com/tomnomnom/assetfinder@latest
        return 0
    fi
    return 1
}

install_sublist3r() {
    if command_exists sublist3r; then
        echo -e "${GREEN}[+] Sublist3r already installed${NC}"
        return 0
    fi
    echo -e "${YELLOW}[!] Sublist3r not found.${NC}"
    if prompt_yes_no "Install Sublist3r?"; then
        git clone https://github.com/aboul3la/Sublist3r.git /tmp/Sublist3r && \
        cd /tmp/Sublist3r && sudo python3 setup.py install && cd .. && rm -rf /tmp/Sublist3r
        return 0
    fi
    return 1
}

# FIXED: WHOIS
run_whois() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[1/8] WHOIS Lookup${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Querying WHOIS database for ${GREEN}$DOMAIN${NC}"
    
    (
        whois "$DOMAIN" 2>/dev/null | head -50 > /tmp/whois_result.txt
    ) &
    spinner $! "WHOIS lookup in progress"
    
    if [[ -f /tmp/whois_result.txt ]] && [[ -s /tmp/whois_result.txt ]]; then
        echo -e "\n${GREEN}[+] WHOIS Results:${NC}"
        echo "================================================"
        cat /tmp/whois_result.txt
        rm -f /tmp/whois_result.txt
    else
        echo -e "\n${YELLOW}[!] No WHOIS information found${NC}"
    fi
    echo "================================================"
}

# FIXED: DNSDumpster with better fallback
run_dnsdumpster() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[2/8] DNSDumpster${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Querying DNSDumpster for ${GREEN}$DOMAIN${NC}"
    
    (
        token=$(curl -s -c /tmp/cookies.txt -H "User-Agent: Mozilla/5.0" "https://dnsdumpster.com" 2>/dev/null | grep -oP 'csrfmiddlewaretoken" value="\K[^"]+' | head -1)
        if [[ -n "$token" ]]; then
            curl -s -b /tmp/cookies.txt -X POST -H "User-Agent: Mozilla/5.0" -H "Referer: https://dnsdumpster.com" -H "X-CSRFToken: $token" -d "csrfmiddlewaretoken=$token&targetip=$DOMAIN" "https://dnsdumpster.com" > /tmp/dnsdumpster_result.txt 2>/dev/null
            rm -f /tmp/cookies.txt
        fi
    ) &
    spinner $! "DNSDumpster enumeration in progress"
    
    if [[ -f /tmp/dnsdumpster_result.txt ]] && [[ -s /tmp/dnsdumpster_result.txt ]]; then
        echo -e "\n${GREEN}[+] DNSDumpster Results:${NC}"
        echo "================================================"
        grep -oP '<td class="col-md-4">\K[^<]+' /tmp/dnsdumpster_result.txt 2>/dev/null | head -20
        rm -f /tmp/dnsdumpster_result.txt
    else
        echo -e "\n${YELLOW}[!] DNSDumpster API unavailable, using fallback${NC}"
        echo -e "${CYAN}[*] Running DNS enumeration with dig...${NC}"
        echo -e "\n${CYAN}[*] NS Records:${NC}"
        dig "$DOMAIN" NS +short 2>/dev/null | head -5
        echo -e "\n${CYAN}[*] MX Records:${NC}"
        dig "$DOMAIN" MX +short 2>/dev/null | head -5
        echo -e "\n${CYAN}[*] A Records:${NC}"
        dig "$DOMAIN" A +short 2>/dev/null | head -5
    fi
    echo "================================================"
}

# FIXED: DNSRecon with proper output
run_dnsrecon() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[3/8] DNSRecon${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Running DNSRecon for ${GREEN}$DOMAIN${NC}"
    
    if command_exists dnsrecon; then
        (
            timeout 60 dnsrecon -d "$DOMAIN" -t std 2>&1 > /tmp/dnsrecon_result.txt
        ) &
        spinner $! "DNSRecon enumeration in progress"
        
        if [[ -f /tmp/dnsrecon_result.txt ]] && [[ -s /tmp/dnsrecon_result.txt ]]; then
            echo -e "\n${GREEN}[+] DNSRecon Results:${NC}"
            echo "================================================"
            cat /tmp/dnsrecon_result.txt | head -30
            rm -f /tmp/dnsrecon_result.txt
        else
            echo -e "\n${YELLOW}[!] No DNS records found${NC}"
            echo -e "${CYAN}[*] Trying alternative DNS enumeration...${NC}"
            echo -e "\n${CYAN}[*] Zone Transfer attempt:${NC}"
            dig axfr "$DOMAIN" @ns1.telenor.se 2>/dev/null | head -5
            echo -e "\n${CYAN}[*] Common DNS records:${NC}"
            for record in A AAAA MX NS TXT CNAME SOA; do
                result=$(dig "$DOMAIN" $record +short 2>/dev/null | head -1)
                if [[ -n "$result" ]]; then
                    echo "  $record: $result"
                fi
            done
        fi
    else
        echo -e "\n${RED}[!] DNSRecon not installed${NC}"
    fi
    echo "================================================"
}

# FIXED: Subfinder with timeout
run_subfinder() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[4/8] Subfinder${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Discovering subdomains for ${GREEN}$DOMAIN${NC}"
    
    if command_exists subfinder; then
        echo -e "${CYAN}[*]${NC} Subfinder is scanning... (timeout: 60s)"
        
        (
            timeout 60 subfinder -d "$DOMAIN" -silent 2>/dev/null > /tmp/subfinder_result.txt
        ) &
        spinner $! "Subfinder scanning for subdomains"
        
        if [[ -f /tmp/subfinder_result.txt ]] && [[ -s /tmp/subfinder_result.txt ]]; then
            local count=$(wc -l < /tmp/subfinder_result.txt)
            echo -e "\n${GREEN}[+] Subfinder found $count subdomains:${NC}"
            echo "================================================"
            cat /tmp/subfinder_result.txt | head -30
            rm -f /tmp/subfinder_result.txt
        else
            echo -e "\n${YELLOW}[!] No subdomains found or timeout occurred${NC}"
            echo -e "${CYAN}[*] Trying fallback enumeration...${NC}"
            for sub in www mail ftp dev test staging admin api blog shop; do
                result=$(dig "$sub.$DOMAIN" A +short 2>/dev/null | head -1)
                if [[ -n "$result" ]]; then
                    echo "  $sub.$DOMAIN - $result"
                fi
            done
        fi
    else
        echo -e "\n${RED}[!] Subfinder not installed${NC}"
    fi
    echo "================================================"
}

# FIXED: Amass with timeout
run_amass() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[5/8] Amass${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Running Amass enumeration for ${GREEN}$DOMAIN${NC}"
    
    if command_exists amass; then
        local cmd="amass enum -d $DOMAIN -passive"
        [[ "$AMASS_AGGRESSIVE" == "true" ]] && cmd="amass enum -d $DOMAIN -active -brute"
        
        echo -e "${CYAN}[*]${NC} Amass is scanning... (timeout: 120s)"
        
        (
            timeout 120 eval $cmd 2>/dev/null > /tmp/amass_result.txt
        ) &
        spinner $! "Amass enumerating subdomains"
        
        if [[ -f /tmp/amass_result.txt ]] && [[ -s /tmp/amass_result.txt ]]; then
            local count=$(wc -l < /tmp/amass_result.txt)
            echo -e "\n${GREEN}[+] Amass found $count subdomains:${NC}"
            echo "================================================"
            cat /tmp/amass_result.txt | head -30
            rm -f /tmp/amass_result.txt
        else
            echo -e "\n${YELLOW}[!] No subdomains found or timeout occurred${NC}"
        fi
    else
        echo -e "\n${RED}[!] Amass not installed${NC}"
    fi
    echo "================================================"
}

# FIXED: Assetfinder with timeout
run_assetfinder() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[6/8] Assetfinder${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Running Assetfinder for ${GREEN}$DOMAIN${NC}"
    
    if command_exists assetfinder; then
        echo -e "${CYAN}[*]${NC} Assetfinder is scanning... (fast)"
        
        (
            timeout 30 assetfinder --subs-only $DOMAIN 2>/dev/null > /tmp/assetfinder_result.txt
        ) &
        spinner $! "Assetfinder discovering subdomains"
        
        if [[ -f /tmp/assetfinder_result.txt ]] && [[ -s /tmp/assetfinder_result.txt ]]; then
            local count=$(wc -l < /tmp/assetfinder_result.txt)
            echo -e "\n${GREEN}[+] Assetfinder found $count subdomains:${NC}"
            echo "================================================"
            cat /tmp/assetfinder_result.txt | head -30
            rm -f /tmp/assetfinder_result.txt
        else
            echo -e "\n${YELLOW}[!] No subdomains found${NC}"
        fi
    else
        echo -e "\n${RED}[!] Assetfinder not installed${NC}"
    fi
    echo "================================================"
}

# FIXED: Sublist3r with timeout
run_sublist3r() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[7/8] Sublist3r${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Running Sublist3r for ${GREEN}$DOMAIN${NC}"
    
    if command_exists sublist3r; then
        echo -e "${CYAN}[*]${NC} Sublist3r is scanning... (timeout: 90s)"
        
        (
            timeout 90 sublist3r -d $DOMAIN -t 10 -v 2>/dev/null | grep -E "\\." > /tmp/sublist3r_result.txt
        ) &
        spinner $! "Sublist3r brute-forcing subdomains"
        
        if [[ -f /tmp/sublist3r_result.txt ]] && [[ -s /tmp/sublist3r_result.txt ]]; then
            local count=$(wc -l < /tmp/sublist3r_result.txt)
            echo -e "\n${GREEN}[+] Sublist3r found $count subdomains:${NC}"
            echo "================================================"
            cat /tmp/sublist3r_result.txt | head -30
            rm -f /tmp/sublist3r_result.txt
        else
            echo -e "\n${YELLOW}[!] No subdomains found${NC}"
        fi
    else
        echo -e "\n${RED}[!] Sublist3r not installed${NC}"
    fi
    echo "================================================"
}

# FIXED: HTTPX with timeout
run_httpx() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[8/8] HTTPX${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}[*]${NC} Running HTTPX probe for ${GREEN}$DOMAIN${NC}"
    
    if command_exists httpx; then
        local temp=$(mktemp)
        echo "$DOMAIN" > "$temp"
        for sub in www mail ftp dev test staging admin api blog shop; do
            echo "$sub.$DOMAIN" >> "$temp" 2>/dev/null
        done
        
        echo -e "${CYAN}[*]${NC} HTTPX is probing endpoints... (timeout: 60s)"
        
        (
            timeout 60 httpx -l "$temp" -status-code -title -tech-detect -silent 2>/dev/null > /tmp/httpx_result.txt
        ) &
        spinner $! "HTTPX probing endpoints"
        
        if [[ -f /tmp/httpx_result.txt ]] && [[ -s /tmp/httpx_result.txt ]]; then
            echo -e "\n${GREEN}[+] HTTPX Results:${NC}"
            echo "================================================"
            cat /tmp/httpx_result.txt | head -20
            rm -f /tmp/httpx_result.txt
        else
            echo -e "\n${YELLOW}[!] No HTTP services found${NC}"
        fi
        rm -f "$temp"
    else
        echo -e "\n${RED}[!] HTTPX not installed${NC}"
    fi
    echo "================================================"
}

# Combined functions
run_all_subdomain() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       RUNNING ALL SUBDOMAIN ENUMERATION TOOLS${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    run_subfinder
    run_amass
    run_assetfinder
    run_sublist3r
}

run_all() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       RUNNING COMPLETE RECONNAISSANCE${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    run_whois
    run_dnsdumpster
    run_dnsrecon
    run_all_subdomain
    run_httpx
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
    echo "  ./recon-it.sh -d example.com -m -t -u -s         # Subdomain tools only"
}

# Main dependency check
check_and_install_dependencies() {
    echo -e "${CYAN}[*] Checking dependencies...${NC}"
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

# Main function
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
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}       TARGET: ${GREEN}$DOMAIN${NC}"
    echo -e "${PURPLE}       STARTED: ${GREEN}$(date)${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
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
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}[+] Scan completed at $(date)${NC}"
    echo -e "${RED}[+] it's OUR tool!${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
}

main "$@"
