#!/bin/bash

# recon-it - Unified Reconnaissance Tool
# Slogan: "it's OUR tool"
# Version: 4.1 - Optional Amass

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
OUTPUT_DIR=""
RAW_SUBDOMAINS=""
ALL_SUBDOMAINS=""
RESOLVED_DOMAINS=""
UNRESOLVED_DOMAINS=""
LIVE_DOMAINS=""
DEAD_DOMAINS=""

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
    echo "    ║           ║       recon-it v4.1                ║           ║"
    echo "    ║           ║       it's OUR tool                ║           ║"
    echo "    ║           ╚══════════════════════════════════════╝           ║"
    echo "    ║                                                              ║"
    echo "    ║     Phase 1: WHOIS → DNS → DNSDumpster                     ║"
    echo "    ║     Phase 2: Subdomain Enumeration (Fast)                  ║"
    echo "    ║     Phase 3: Filter & Resolve                              ║"
    echo "    ║     Phase 4: HTTP Probing                                  ║"
    echo "    ║                                                              ║"
    echo "    ║     Optional: --amass for deeper enumeration              ║"
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
    
    echo "# recon-it v4.1 - Scan Results" > "$OUTPUT_DIR/README.txt"
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
    fi
}

# PHASE 2: Subdomain Enumeration (Fast)
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
        echo -e "${RED}[!] Subfinder not installed${NC}"
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
        echo -e "${RED}[!] Sublist3r not installed${NC}"
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
        echo -e "${RED}[!] Assetfinder not installed${NC}"
    fi
    
    # Optional: Amass (only if flag is set)
    if [[ "$USE_AMASS" == "true" ]]; then
        echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC} ${CYAN}[4/4] Amass (Optional)${NC} ${YELLOW}│${NC}"
        echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
        echo -e "${CYAN}[*]${NC} Running Amass for ${GREEN}$DOMAIN${NC}"
        
        if command_exists amass; then
            echo -e "${CYAN}[*]${NC} Amass is scanning... (timeout: 180s) - This may take a while"
            (
                timeout 180 amass enum -d "$DOMAIN" -passive 2>/dev/null | tee -a "$RAW_SUBDOMAINS" > /dev/null
            ) &
            spinner $! "Amass enumerating subdomains"
            
            local count=$(grep -v "^#" "$RAW_SUBDOMAINS" | grep -v "^$" | wc -l)
            echo -e "${GREEN}[+] Amass found additional subdomains. Total: $count${NC}"
        else
            echo -e "${RED}[!] Amass not installed${NC}"
            echo -e "${YELLOW}[!] Install with: sudo apt install amass -y${NC}"
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
        echo "recon-it v4.1 - Scan Summary"
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
        echo "--- Quick Stats ---"
        echo "Success Rate: $(awk "BEGIN {printf \"%.1f%%\", $(wc -l < $RESOLVED_DOMAINS)*100/$(wc -l < $ALL_SUBDOMAINS)}")"
        echo "Live Rate: $(awk "BEGIN {printf \"%.1f%%\", $(wc -l < $LIVE_DOMAINS)*100/$(wc -l < $RESOLVED_DOMAINS)}")"
        echo ""
        echo "========================================"
    } | tee "$OUTPUT_DIR/SUMMARY.txt"
    
    echo -e "\n${GREEN}[+] Summary saved to: $OUTPUT_DIR/SUMMARY.txt${NC}"
}

# Check dependencies
check_dependencies() {
    local missing=()
    for tool in whois dig curl; do
        if ! command -v $tool &> /dev/null; then
            missing+=($tool)
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[!] Missing required tools: ${missing[*]}${NC}"
        echo -e "${YELLOW}[!] Install with: sudo apt install ${missing[*]} -y${NC}"
        exit 1
    fi
}

# Help
show_help() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./recon-it.sh [OPTIONS] -d <domain>"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -d, --domain <domain>       Target domain"
    echo "  --amass                     Enable Amass (slower but deeper)"
    echo "  -h, --help                  Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
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
    
    while [[ $# -gt 0 ]]; do
        case $1 in
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
    
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}[!] Domain required${NC}"
        show_help
        exit 1
    fi
    
    show_banner
    check_dependencies
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
