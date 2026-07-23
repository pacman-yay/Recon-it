#!/bin/bash

# recon-it - Unified Reconnaissance Tool
# it's OUR tool

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables
DOMAIN=""
USE_AMASS=false
PORT_SCAN=false
TECH_DETECT=false
SCREENSHOT=false
HTML_REPORT=false
OUTPUT_DIR=""

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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
    printf "\r${GREEN}[✓]${NC} %s - Done!    \n" "$message"
}

# Install tools
install_all_tools() {
    echo "[*] Installing tools..."
    sudo apt update -qq
    sudo apt install whois dnsutils curl unzip git -y -qq
    sudo apt install subfinder amass httpx dnsrecon -y -qq
    go install github.com/tomnomnom/assetfinder@latest 2>/dev/null
    echo "[+] Installation complete!"
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
    
    echo "[+] Output: $OUTPUT_DIR"
}

# PHASE 1: Basic Info
phase1_basic_info() {
    echo -e "\n${CYAN}[1/4] Basic Info${NC}"
    
    # WHOIS
    (
        whois "$DOMAIN" 2>/dev/null | head -50 > "$OUTPUT_DIR/whois.txt"
    ) &
    spinner $! "WHOIS lookup"
    
    # DNSRecon
    if command_exists dnsrecon; then
        (
            timeout 60 dnsrecon -d "$DOMAIN" -t std 2>&1 > "$OUTPUT_DIR/dnsrecon.txt"
        ) &
        spinner $! "DNSRecon"
    fi
    
    # DNSDumpster
    (
        token=$(curl -s -c /tmp/cookies.txt "https://dnsdumpster.com" 2>/dev/null | grep -oP 'csrfmiddlewaretoken" value="\K[^"]+' | head -1)
        if [[ -n "$token" ]]; then
            curl -s -b /tmp/cookies.txt -X POST -H "Referer: https://dnsdumpster.com" -H "X-CSRFToken: $token" -d "csrfmiddlewaretoken=$token&targetip=$DOMAIN" "https://dnsdumpster.com" > "$OUTPUT_DIR/dnsdumpster.txt" 2>/dev/null
            rm -f /tmp/cookies.txt
        fi
    ) &
    spinner $! "DNSDumpster"
}

# PHASE 2: Subdomain Enumeration
phase2_subdomain_enum() {
    echo -e "\n${CYAN}[2/4] Subdomain Enumeration${NC}"
    
    echo "# Raw Subdomains" > "$RAW_SUBDOMAINS"
    
    # Subfinder
    if command_exists subfinder; then
        (
            timeout 120 subfinder -d "$DOMAIN" -silent 2>/dev/null | tee -a "$RAW_SUBDOMAINS" > /dev/null
        ) &
        spinner $! "Subfinder"
    fi
    
    # Sublist3r
    if command_exists sublist3r; then
        (
            timeout 120 sublist3r -d $DOMAIN -t 10 2>/dev/null | grep -E "\\." | grep -v "Enumerating\|Searching\|Total" | tee -a "$RAW_SUBDOMAINS" > /dev/null
        ) &
        spinner $! "Sublist3r"
    fi
    
    # Assetfinder
    if command_exists assetfinder; then
        (
            assetfinder --subs-only $DOMAIN 2>/dev/null | tee -a "$RAW_SUBDOMAINS" > /dev/null
        ) &
        spinner $! "Assetfinder"
    fi
    
    # Amass (optional)
    if [[ "$USE_AMASS" == "true" ]] && command_exists amass; then
        (
            timeout 180 amass enum -d "$DOMAIN" -passive 2>/dev/null | tee -a "$RAW_SUBDOMAINS" > /dev/null
        ) &
        spinner $! "Amass"
    fi
}

# PHASE 3: Filter & Resolve
phase3_filter_resolve() {
    echo -e "\n${CYAN}[3/4] Filter & Resolve${NC}"
    
    grep -v "^#" "$RAW_SUBDOMAINS" | grep -v "^$" | sort -u > "$ALL_SUBDOMAINS"
    local total=$(wc -l < "$ALL_SUBDOMAINS")
    echo "[+] Unique subdomains: $total"
    
    if [[ $total -eq 0 ]]; then
        echo "[!] No subdomains found"
        return
    fi
    
    > "$RESOLVED_DOMAINS"
    > "$UNRESOLVED_DOMAINS"
    
    local resolved=0
    local unresolved=0
    
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
    done < "$ALL_SUBDOMAINS"
    
    echo "[+] Resolved: $resolved | Unresolved: $unresolved"
}

# PHASE 4: HTTP Probing
phase4_http_probe() {
    echo -e "\n${CYAN}[4/4] HTTP Probing${NC}"
    
    if [[ ! -f "$RESOLVED_DOMAINS" ]] || [[ ! -s "$RESOLVED_DOMAINS" ]]; then
        echo "[!] No resolved domains to probe"
        return
    fi
    
    cut -d',' -f1 "$RESOLVED_DOMAINS" > "$OUTPUT_DIR/resolved_domains_only.txt"
    
    if command_exists httpx; then
        (
            httpx -l "$OUTPUT_DIR/resolved_domains_only.txt" -status-code -title -tech-detect -silent 2>/dev/null | grep -E "\[200\]" > "$LIVE_DOMAINS"
        ) &
        spinner $! "HTTPX (live)"
        
        (
            httpx -l "$OUTPUT_DIR/resolved_domains_only.txt" -status-code -title -tech-detect -silent 2>/dev/null > "$DEAD_DOMAINS"
        ) &
        spinner $! "HTTPX (all)"
        
        echo "[+] Live: $(wc -l < $LIVE_DOMAINS 2>/dev/null || echo 0)"
    fi
}

# Port Scanning
run_port_scan() {
    echo -e "\n${CYAN}[5/6] Port Scan${NC}"
    
    if [[ ! -f "$RESOLVED_DOMAINS" ]] || [[ ! -s "$RESOLVED_DOMAINS" ]]; then
        echo "[!] No resolved domains to scan"
        return
    fi
    
    cut -d',' -f1 "$RESOLVED_DOMAINS" > "$OUTPUT_DIR/scan_targets.txt"
    
    if command_exists naabu; then
        (
            naabu -list "$OUTPUT_DIR/scan_targets.txt" -top-ports 100 -silent > "$OUTPUT_DIR/ports.txt"
        ) &
        spinner $! "Naabu port scan"
    elif command_exists nmap; then
        (
            nmap -iL "$OUTPUT_DIR/scan_targets.txt" -T4 -F > "$OUTPUT_DIR/ports.txt"
        ) &
        spinner $! "Nmap port scan"
    fi
}

# Technology Detection
run_tech_detect() {
    echo -e "\n${CYAN}[6/6] Tech Detection${NC}"
    
    if [[ ! -f "$LIVE_DOMAINS" ]] || [[ ! -s "$LIVE_DOMAINS" ]]; then
        echo "[!] No live domains to analyze"
        return
    fi
    
    cut -d' ' -f1 "$LIVE_DOMAINS" | cut -d'[' -f1 > "$OUTPUT_DIR/tech_targets.txt"
    
    if command_exists httpx; then
        (
            httpx -l "$OUTPUT_DIR/tech_targets.txt" -tech-detect -silent > "$OUTPUT_DIR/technologies.txt"
        ) &
        spinner $! "Tech detection"
    fi
}

# Screenshots
run_screenshots() {
    echo -e "\n${CYAN}[7/8] Screenshots${NC}"
    
    if [[ ! -f "$LIVE_DOMAINS" ]] || [[ ! -s "$LIVE_DOMAINS" ]]; then
        echo "[!] No live domains to screenshot"
        return
    fi
    
    mkdir -p "$OUTPUT_DIR/screenshots"
    cut -d' ' -f1 "$LIVE_DOMAINS" | cut -d'[' -f1 > "$OUTPUT_DIR/screenshot_targets.txt"
    
    if command_exists aquatone; then
        (
            cat "$OUTPUT_DIR/screenshot_targets.txt" | aquatone -out "$OUTPUT_DIR/screenshots/" -silent
        ) &
        spinner $! "Aquatone screenshots"
    fi
}

# HTML Report
generate_html_report() {
    echo -e "\n${CYAN}[8/8] HTML Report${NC}"
    
    local html_file="$OUTPUT_DIR/report.html"
    
    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>recon-it Report - DOMAIN_PLACEHOLDER</title>
<style>
body{font-family:Arial;margin:20px;background:#f5f5f5}
.container{max-width:1200px;margin:0 auto;background:#fff;padding:20px;border-radius:10px}
h1{color:#d32f2f}
h2{color:#1976d2;border-bottom:2px solid #1976d2;padding-bottom:10px}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:15px;margin:20px 0}
.stat{background:#fafafa;padding:15px;border-radius:5px;text-align:center}
.stat-number{font-size:24px;font-weight:bold;color:#1976d2}
.stat-label{color:#666;font-size:12px;text-transform:uppercase}
table{width:100%;border-collapse:collapse;margin:10px 0}
th{background:#1976d2;color:#fff;padding:10px;text-align:left}
td{padding:8px 10px;border-bottom:1px solid #ddd}
tr:hover{background:#f5f5f5}
.footer{text-align:center;margin-top:30px;color:#999;font-size:12px}
</style>
</head>
<body>
<div class="container">
<h1>recon-it Report</h1>
<p><strong>Domain:</strong> DOMAIN_PLACEHOLDER</p>
<p><strong>Date:</strong> DATE_PLACEHOLDER</p>
<div class="stats">
<div class="stat"><div class="stat-number">TOTAL_PLACEHOLDER</div><div class="stat-label">Total Subdomains</div></div>
<div class="stat"><div class="stat-number">RESOLVED_PLACEHOLDER</div><div class="stat-label">Resolved</div></div>
<div class="stat"><div class="stat-number">LIVE_PLACEHOLDER</div><div class="stat-label">Live (200 OK)</div></div>
</div>
<h2>Subdomains</h2>
<table><tr><th>Domain</th><th>IP</th><th>Status</th></tr>
SUBDOMAINS_PLACEHOLDER
</table>
<h2>Live Domains</h2>
<table><tr><th>Domain</th><th>Status</th><th>Title</th></tr>
LIVE_PLACEHOLDER
</table>
<div class="footer">Generated by recon-it | it's OUR tool</div>
</div>
</body>
</html>
EOF
    
    # Replace placeholders
    local total=$(wc -l < "$ALL_SUBDOMAINS" 2>/dev/null || echo 0)
    local resolved=$(wc -l < "$RESOLVED_DOMAINS" 2>/dev/null || echo 0)
    local live=$(wc -l < "$LIVE_DOMAINS" 2>/dev/null || echo 0)
    
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" "$html_file"
    sed -i "s/DATE_PLACEHOLDER/$(date)/g" "$html_file"
    sed -i "s/TOTAL_PLACEHOLDER/$total/g" "$html_file"
    sed -i "s/RESOLVED_PLACEHOLDER/$resolved/g" "$html_file"
    sed -i "s/LIVE_PLACEHOLDER/$live/g" "$html_file"
    
    # Subdomains table
    local subs=""
    if [[ -f "$RESOLVED_DOMAINS" ]]; then
        while IFS=',' read -r domain ip; do
            subs+="<tr><td>$domain</td><td>$ip</td><td>✅ Resolved</td></tr>\n"
        done < "$RESOLVED_DOMAINS"
    fi
    if [[ -f "$UNRESOLVED_DOMAINS" ]]; then
        while read -r domain; do
            subs+="<tr><td>$domain</td><td>-</td><td>❌ Unresolved</td></tr>\n"
        done < "$UNRESOLVED_DOMAINS"
    fi
    sed -i "s|SUBDOMAINS_PLACEHOLDER|$subs|g" "$html_file"
    
    # Live domains
    local live_html=""
    if [[ -f "$LIVE_DOMAINS" ]]; then
        while read -r line; do
            domain=$(echo "$line" | cut -d'[' -f1 | xargs)
            status=$(echo "$line" | grep -oP '\[[0-9]+\]' | head -1)
            title=$(echo "$line" | grep -oP 'title="[^"]*"' | cut -d'"' -f2)
            live_html+="<tr><td>$domain</td><td>$status</td><td>$title</td></tr>\n"
        done < "$LIVE_DOMAINS"
    fi
    sed -i "s|LIVE_PLACEHOLDER|$live_html|g" "$html_file"
    
    echo "[+] Report: $html_file"
}

# Generate summary
generate_report() {
    echo -e "\n${CYAN}Summary${NC}"
    echo "========================================"
    echo "Domain: $DOMAIN"
    echo "Output: $OUTPUT_DIR"
    echo "Subdomains: $(wc -l < $ALL_SUBDOMAINS 2>/dev/null || echo 0)"
    echo "Resolved: $(wc -l < $RESOLVED_DOMAINS 2>/dev/null || echo 0)"
    echo "Live: $(wc -l < $LIVE_DOMAINS 2>/dev/null || echo 0)"
    echo "========================================"
}

# Help
show_help() {
    echo "Usage: ./recon-it.sh [OPTIONS] -d <domain>"
    echo ""
    echo "Options:"
    echo "  --install        Install all tools"
    echo "  -d, --domain     Target domain"
    echo "  --amass          Enable Amass"
    echo "  --ports          Port scanning"
    echo "  --tech-detect    Technology detection"
    echo "  --screenshot     Screenshots"
    echo "  --html-report    HTML report"
    echo ""
    echo "Examples:"
    echo "  ./recon-it.sh -d example.com"
    echo "  ./recon-it.sh -d example.com --amass --ports --html-report"
    echo "  ./recon-it.sh --install"
}

# Main
main() {
    DOMAIN=""
    USE_AMASS=false
    PORT_SCAN=false
    TECH_DETECT=false
    SCREENSHOT=false
    HTML_REPORT=false
    INSTALL_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install) INSTALL_MODE=true; shift ;;
            -d|--domain) DOMAIN="$2"; shift 2 ;;
            --amass) USE_AMASS=true; shift ;;
            --ports) PORT_SCAN=true; shift ;;
            --tech-detect) TECH_DETECT=true; shift ;;
            --screenshot) SCREENSHOT=true; shift ;;
            --html-report) HTML_REPORT=true; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) echo "Unknown: $1"; show_help; exit 1 ;;
        esac
    done
    
    if [[ "$INSTALL_MODE" == "true" ]]; then
        install_all_tools
        exit 0
    fi
    
    if [[ -z "$DOMAIN" ]]; then
        echo "Domain required"
        show_help
        exit 1
    fi
    
    init_output
    phase1_basic_info
    phase2_subdomain_enum
    phase3_filter_resolve
    phase4_http_probe
    
    [[ "$PORT_SCAN" == "true" ]] && run_port_scan
    [[ "$TECH_DETECT" == "true" ]] && run_tech_detect
    [[ "$SCREENSHOT" == "true" ]] && run_screenshots
    [[ "$HTML_REPORT" == "true" ]] && generate_html_report
    
    generate_report
    echo -e "\n${GREEN}[+] it's OUR tool!${NC}"
}

main "$@"
