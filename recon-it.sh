#!/bin/bash

# recon-it - Unified Reconnaissance Tool
# Slogan: "it's OUR tool"
# Version: 2.1

# Auto-fix permissions if needed
if [[ ! -x "$0" ]]; then
    echo -e "\033[0;33m[!] Script is not executable. Fixing permissions...\033[0m"
    chmod +x "$0"
    echo -e "\033[0;32m[+] Permissions fixed. Please run the script again.\033[0m"
    exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables for logging
LOG_FILE=""
LOG_LEVEL="INFO"
VERBOSE=false
QUIET=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check if running with proper permissions
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}[!] Note: Running without root privileges. Some WHOIS lookups might be limited.${NC}"
        echo -e "${YELLOW}[!] To run as root: sudo ./recon-it.sh [options]${NC}"
    fi
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
    echo "    ║              ██╗████████╗                                 ║"
    echo "    ║              ██║╚══██╔══╝                                 ║"
    echo "    ║              ██║   ██║                                    ║"
    echo "    ║              ██║   ██║                                    ║"
    echo "    ║              ██║   ██║                                    ║"
    echo "    ║              ╚═╝   ╚═╝                                    ║"
    echo "    ║                                                              ║"
    echo "    ║           ╔══════════════════════════════════════╗           ║"
    echo "    ║           ║       recon-it v2.1                ║           ║"
    echo "    ║           ║       it's OUR tool                ║           ║"
    echo "    ║           ╚══════════════════════════════════════╝           ║"
    echo "    ║                                                              ║"
    echo "    ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging functions
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Console output based on verbosity and quiet mode
    if [[ "$QUIET" != "true" ]]; then
        case $level in
            "ERROR")
                echo -e "${RED}[ERROR] $message${NC}" >&2
                ;;
            "WARNING")
                echo -e "${YELLOW}[WARNING] $message${NC}"
                ;;
            "INFO")
                if [[ "$VERBOSE" == "true" ]] || [[ "$LOG_LEVEL" == "INFO" ]]; then
                    echo -e "${GREEN}[INFO] $message${NC}"
                fi
                ;;
            "DEBUG")
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -e "${CYAN}[DEBUG] $message${NC}"
                fi
                ;;
            "SUCCESS")
                echo -e "${GREEN}[SUCCESS] $message${NC}"
                ;;
            *)
                echo "$message"
                ;;
        esac
    fi
    
    # Write to log file if specified
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

log_info() {
    log_message "INFO" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_warning() {
    log_message "WARNING" "$1"
}

log_debug() {
    log_message "DEBUG" "$1"
}

log_success() {
    log_message "SUCCESS" "$1"
}

# Help menu
show_help() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./recon-it.sh [OPTIONS] -d <domain>"
    echo ""
    echo -e "${YELLOW}Target Options:${NC}"
    echo "  -d, --domain <domain>       Target domain (required)"
    echo "  -f, --domain-list <file>    File containing list of domains"
    echo ""
    echo -e "${YELLOW}Module Options:${NC}"
    echo "  -a, --all                   Run all reconnaissance modules"
    echo "  -w, --whois                 Run WHOIS lookup"
    echo "  -n, --dnsdumpster           Run DNSDumpster lookup"
    echo "  -r, --dnsrecon              Run DNSRecon"
    echo "  -s, --subfinder             Run Subfinder"
    echo "  -x, --httpx                 Run HTTPX probe"
    echo ""
    echo -e "${YELLOW}Logging Options:${NC}"
    echo "  -o, --output <file>         Output file for results (overwrites)"
    echo "  -l, --log-file <file>       Log file path (default: recon-it_TIMESTAMP.log)"
    echo "  --log-level <level>         Log level: DEBUG, INFO, WARNING, ERROR (default: INFO)"
    echo "  -v, --verbose               Enable verbose output"
    echo "  -q, --quiet                 Suppress all output except errors"
    echo "  --append                    Append to output file instead of overwriting"
    echo "  --json-log                  Generate JSON format logs"
    echo ""
    echo -e "${YELLOW}Other Options:${NC}"
    echo "  -t, --threads <num>         Number of threads for concurrent scans"
    echo "  --timeout <seconds>         Timeout for each module (default: 30)"
    echo "  --config <file>             Use custom config file"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./recon-it.sh -d example.com -a"
    echo "  ./recon-it.sh -d example.com -w -n -s -v"
    echo "  ./recon-it.sh -d example.com -a -o results.txt --log-level DEBUG"
    echo "  ./recon-it.sh -f domains.txt -a --threads 10 -l scan.log"
    echo "  ./recon-it.sh -d example.com --log-file custom.log --json-log"
    echo ""
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "  chmod +x recon-it.sh  # Make executable"
    echo "  ./recon-it.sh -d pngtree.com -a  # Run full scan"
}

# Initialize logging
init_logging() {
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE="recon-it_${DOMAIN:-multi}_${TIMESTAMP}.log"
    fi
    
    # Create log directory if it doesn't exist
    local log_dir=$(dirname "$LOG_FILE")
    if [[ "$log_dir" != "." ]] && [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
    
    # Initialize log file
    echo "========================================" > "$LOG_FILE"
    echo "recon-it v2.1 - Log File" >> "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "Target: ${DOMAIN:-Multiple Domains}" >> "$LOG_FILE"
    echo "Log Level: $LOG_LEVEL" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Generate JSON log entry
log_json() {
    local level=$1
    local message=$2
    local module=$3
    local timestamp=$(date -Iseconds)
    
    if [[ "$JSON_LOG" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"module\":\"${module:-general}\",\"message\":\"$message\"}" >> "${LOG_FILE}.json"
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    local missing_deps=()
    
    # Check for required tools
    for tool in whois dig host curl; do
        if ! command -v $tool &> /dev/null; then
            missing_deps+=($tool)
            log_debug "Missing dependency: $tool"
        fi
    done
    
    # Check for optional tools
    if [[ "$RUN_ALL" == "true" ]] || [[ "$RUN_DNSRECON" == "true" ]]; then
        if ! command -v dnsrecon &> /dev/null; then
            log_warning "dnsrecon not found. Install with: pip install dnsrecon"
        fi
    fi
    
    if [[ "$RUN_ALL" == "true" ]] || [[ "$RUN_SUBFINDER" == "true" ]]; then
        if ! command -v subfinder &> /dev/null; then
            log_warning "subfinder not found. Install from: https://github.com/projectdiscovery/subfinder"
        fi
    fi
    
    if [[ "$RUN_ALL" == "true" ]] || [[ "$RUN_HTTPX" == "true" ]]; then
        if ! command -v httpx &> /dev/null; then
            log_warning "httpx not found. Install from: https://github.com/projectdiscovery/httpx"
        fi
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install them first."
        log_info "Installation commands:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                whois)
                    echo "  sudo apt-get install whois -y  # Debian/Ubuntu"
                    echo "  sudo yum install whois -y      # RHEL/CentOS"
                    ;;
                dig|host)
                    echo "  sudo apt-get install dnsutils -y  # Debian/Ubuntu"
                    echo "  sudo yum install bind-utils -y    # RHEL/CentOS"
                    ;;
                curl)
                    echo "  sudo apt-get install curl -y  # Debian/Ubuntu"
                    echo "  sudo yum install curl -y      # RHEL/CentOS"
                    ;;
            esac
        done
        exit 1
    fi
    
    log_success "Dependency check completed"
}

# WHOIS Lookup
run_whois() {
    log_info "Starting WHOIS lookup for $DOMAIN"
    echo -e "${GREEN}[+] Running WHOIS lookup for $DOMAIN...${NC}"
    echo "================================================"
    
    if command -v whois &> /dev/null; then
        local result=$(whois "$DOMAIN" 2>/dev/null | head -50)
        if [[ -n "$result" ]]; then
            echo "$result"
            log_debug "WHOIS lookup completed for $DOMAIN"
            log_json "INFO" "WHOIS lookup completed" "whois"
        else
            log_warning "WHOIS lookup returned no results for $DOMAIN"
            echo "No WHOIS information available for $DOMAIN"
        fi
    else
        log_error "whois command not found"
        echo -e "${RED}[!] whois command not found${NC}"
    fi
    echo "================================================"
}

# DNSDumpster (via API)
run_dnsdumpster() {
    log_info "Starting DNSDumpster lookup for $DOMAIN"
    echo -e "${GREEN}[+] Running DNSDumpster lookup for $DOMAIN...${NC}"
    echo "================================================"
    
    local csrf_token=$(curl -s -c cookies.txt "https://dnsdumpster.com" | grep -oP 'csrfmiddlewaretoken" value="\K[^"]+' 2>/dev/null)
    
    if [[ -n "$csrf_token" ]]; then
        local result=$(curl -s -b cookies.txt -X POST \
            -H "Referer: https://dnsdumpster.com" \
            -H "X-CSRFToken: $csrf_token" \
            -d "csrfmiddlewaretoken=$csrf_token&targetip=$DOMAIN" \
            "https://dnsdumpster.com" | \
            grep -oP '<td class="col-md-4">\K[^<]+' 2>/dev/null | head -20)
        if [[ -n "$result" ]]; then
            echo "$result"
            log_debug "DNSDumpster lookup completed"
            log_json "INFO" "DNSDumpster lookup completed" "dnsdumpster"
        else
            log_warning "DNSDumpster returned no results"
        fi
        rm -f cookies.txt
    else
        log_warning "DNSDumpster API not available, using fallback"
        echo "DNSDumpster API not available. Using fallback DNS tools:"
        dig "$DOMAIN" ANY 2>/dev/null | head -20
    fi
    echo "================================================"
}

# DNSRecon
run_dnsrecon() {
    log_info "Starting DNSRecon for $DOMAIN"
    echo -e "${GREEN}[+] Running DNSRecon for $DOMAIN...${NC}"
    echo "================================================"
    
    if command -v dnsrecon &> /dev/null; then
        local result=$(dnsrecon -d "$DOMAIN" -t std 2>/dev/null | head -30)
        if [[ -n "$result" ]]; then
            echo "$result"
            log_debug "DNSRecon completed"
            log_json "INFO" "DNSRecon completed" "dnsrecon"
        else
            log_warning "DNSRecon returned no results"
        fi
    else
        log_warning "dnsrecon not installed, using fallback"
        echo -e "${YELLOW}[!] dnsrecon not installed${NC}"
        echo "Using alternative DNS enumeration:"
        echo "NS Records:"
        dig "$DOMAIN" NS 2>/dev/null | grep -E "^$DOMAIN" | head -10
        echo -e "\nMX Records:"
        dig "$DOMAIN" MX 2>/dev/null | grep -E "^$DOMAIN" | head -10
    fi
    echo "================================================"
}

# Subfinder
run_subfinder() {
    log_info "Starting Subfinder for $DOMAIN"
    echo -e "${GREEN}[+] Running Subfinder for $DOMAIN...${NC}"
    echo "================================================"
    
    if command -v subfinder &> /dev/null; then
        local result=$(subfinder -d "$DOMAIN" -silent 2>/dev/null | head -30)
        if [[ -n "$result" ]]; then
            echo "$result"
            local sub_count=$(echo "$result" | wc -l)
            log_debug "Subfinder found $sub_count subdomains"
            log_json "INFO" "Subfinder found $sub_count subdomains" "subfinder"
        else
            log_warning "Subfinder found no subdomains"
        fi
    else
        log_warning "subfinder not installed, using fallback"
        echo -e "${YELLOW}[!] subfinder not installed${NC}"
        echo "Using alternative subdomain discovery:"
        for sub in www mail ftp dev test staging admin api blog shop; do
            host "$sub.$DOMAIN" 2>/dev/null | grep "has address" | head -1
        done
    fi
    echo "================================================"
}

# HTTPX
run_httpx() {
    log_info "Starting HTTPX probe for $DOMAIN"
    echo -e "${GREEN}[+] Running HTTPX probe for $DOMAIN...${NC}"
    echo "================================================"
    
    if command -v httpx &> /dev/null; then
        local temp_file=$(mktemp)
        echo "$DOMAIN" > "$temp_file"
        
        for sub in www mail ftp dev test staging admin api blog shop; do
            echo "$sub.$DOMAIN" >> "$temp_file" 2>/dev/null
        done
        
        local result=$(httpx -l "$temp_file" -status-code -title -tech-detect -silent 2>/dev/null | head -20)
        if [[ -n "$result" ]]; then
            echo "$result"
            log_debug "HTTPX probe completed"
            log_json "INFO" "HTTPX probe completed" "httpx"
        else
            log_warning "HTTPX probe returned no results"
        fi
        rm -f "$temp_file"
    else
        log_warning "httpx not installed, using fallback"
        echo -e "${YELLOW}[!] httpx not installed${NC}"
        echo "Using alternative HTTP probing:"
        for protocol in http https; do
            curl -s -o /dev/null -w "$protocol://$DOMAIN - Status: %{http_code}\n" "$protocol://$DOMAIN" 2>/dev/null
        done
    fi
    echo "================================================"
}

# Process domain list
process_domain_list() {
    local domain_file=$1
    if [[ ! -f "$domain_file" ]]; then
        log_error "Domain list file not found: $domain_file"
        exit 1
    fi
    
    log_info "Processing domain list from: $domain_file"
    local total_domains=$(wc -l < "$domain_file")
    log_info "Total domains to scan: $total_domains"
    
    local counter=0
    while IFS= read -r domain; do
        [[ -z "$domain" ]] && continue
        ((counter++))
        log_info "Processing domain $counter/$total_domains: $domain"
        DOMAIN="$domain"
        
        # Run selected modules for each domain
        if [[ "$RUN_ALL" == "true" ]]; then
            run_all
        else
            [[ "$RUN_WHOIS" == "true" ]] && run_whois
            [[ "$RUN_DNSDUMPSTER" == "true" ]] && run_dnsdumpster
            [[ "$RUN_DNSRECON" == "true" ]] && run_dnsrecon
            [[ "$RUN_SUBFINDER" == "true" ]] && run_subfinder
            [[ "$RUN_HTTPX" == "true" ]] && run_httpx
        fi
        
        echo "----------------------------------------" >> "$LOG_FILE"
    done < "$domain_file"
    
    log_success "Completed scanning all $total_domains domains"
}

# Run all modules
run_all() {
    log_info "Running ALL reconnaissance modules for $DOMAIN"
    echo -e "${PURPLE}[*] Running ALL reconnaissance modules for $DOMAIN${NC}"
    echo ""
    run_whois
    run_dnsdumpster
    run_dnsrecon
    run_subfinder
    run_httpx
    log_success "All modules completed for $DOMAIN"
}

# Main execution
main() {
    # Default values
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
    RUN_HTTPX=false
    THREADS=1
    TIMEOUT=30
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
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
            -x|--httpx)
                RUN_HTTPX=true
                shift
                ;;
            -t|--threads)
                THREADS="$2"
                shift 2
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --config)
                CONFIG_FILE="$2"
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
    
    # Check if domain or domain list is provided
    if [[ -z "$DOMAIN" ]] && [[ -z "$DOMAIN_LIST" ]]; then
        echo -e "${RED}[!] Domain or domain list is required${NC}"
        show_help
        exit 1
    fi
    
    # Validate domain format if single domain
    if [[ -n "$DOMAIN" ]] && ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}[!] Invalid domain format: $DOMAIN${NC}"
        exit 1
    fi
    
    # Show banner
    show_banner
    
    # Check permissions
    check_permissions
    
    # Initialize logging
    if [[ -n "$DOMAIN" ]]; then
        init_logging
    elif [[ -n "$DOMAIN_LIST" ]]; then
        init_logging
    fi
    
    # Log startup information
    log_info "recon-it v2.1 started"
    log_info "Log level: $LOG_LEVEL"
    log_info "Verbose: $VERBOSE"
    log_info "Quiet: $QUIET"
    
    # Check dependencies
    check_dependencies
    
    # Setup output redirection
    if [[ -n "$OUTPUT_FILE" ]]; then
        if [[ "$APPEND" == "true" ]]; then
            exec >> "$OUTPUT_FILE" 2>&1
            log_info "Appending output to: $OUTPUT_FILE"
        else
            exec > >(tee "$OUTPUT_FILE") 2>&1
            log_info "Writing output to: $OUTPUT_FILE"
        fi
    fi
    
    # Check if no specific modules are selected, run all
    if [[ "$RUN_ALL" == "false" ]] && [[ "$RUN_WHOIS" == "false" ]] && [[ "$RUN_DNSDUMPSTER" == "false" ]] && [[ "$RUN_DNSRECON" == "false" ]] && [[ "$RUN_SUBFINDER" == "false" ]] && [[ "$RUN_HTTPX" == "false" ]]; then
        RUN_ALL=true
        log_info "No modules specified, running all modules"
    fi
    
    # Start reconnaissance
    echo ""
    log_info "Starting reconnaissance"
    
    if [[ -n "$DOMAIN" ]]; then
        # Single domain mode
        log_info "Target: $DOMAIN"
        
        if [[ "$RUN_ALL" == "true" ]]; then
            run_all
        else
            [[ "$RUN_WHOIS" == "true" ]] && run_whois
            [[ "$RUN_DNSDUMPSTER" == "true" ]] && run_dnsdumpster
            [[ "$RUN_DNSRECON" == "true" ]] && run_dnsrecon
            [[ "$RUN_SUBFINDER" == "true" ]] && run_subfinder
            [[ "$RUN_HTTPX" == "true" ]] && run_httpx
        fi
    elif [[ -n "$DOMAIN_LIST" ]]; then
        # Domain list mode
        log_info "Target: Multiple domains from $DOMAIN_LIST"
        process_domain_list "$DOMAIN_LIST"
    fi
    
    # Completion
    echo ""
    log_success "Reconnaissance completed at $(date)"
    log_success "Results saved to: $LOG_FILE"
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        log_success "Output saved to: $OUTPUT_FILE"
    fi
    
    if [[ "$JSON_LOG" == "true" ]]; then
        log_success "JSON log saved to: ${LOG_FILE}.json"
    fi
    
    echo -e "${RED}[+] it's OUR tool!${NC}"
}

# Run main function with all arguments
main "$@"