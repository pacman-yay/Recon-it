#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN=""
USE_AMASS=false
PORT_SCAN=false
TECH_DETECT=false
SCREENSHOT=false
HTML_REPORT=false
OUTPUT_DIR=""
# Install additional tools
install_advanced_tools() {
    echo -e "\n${CYAN}[*] Installing advanced tools...${NC}"
    
    # Nmap for port scanning
    if ! command_exists nmap && [[ "$PORT_SCAN" == "true" ]]; then
        echo -e "${YELLOW}[!] Installing nmap...${NC}"
        sudo apt install nmap -y
    fi
    
    # Naabu for fast port scanning
    if ! command_exists naabu && [[ "$PORT_SCAN" == "true" ]]; then
        echo -e "${YELLOW}[!] Installing naabu...${NC}"
        go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    fi
    
    # Wappalyzer for tech detection
    if ! command_exists wappalyzer && [[ "$TECH_DETECT" == "true" ]]; then
        echo -e "${YELLOW}[!] Installing wappalyzer...${NC}"
        sudo apt install wappalyzer -y
    fi
    
    # Aquatone for screenshots
    if ! command_exists aquatone && [[ "$SCREENSHOT" == "true" ]]; then
        echo -e "${YELLOW}[!] Installing aquatone...${NC}"
        wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
        unzip aquatone_linux_amd64_1.7.0.zip
        sudo mv aquatone /usr/local/bin/
        rm aquatone_linux_amd64_1.7.0.zip
    fi
}

# Port Scanning
run_port_scan() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[5/9] Port Scanning${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    if [[ ! -f "$RESOLVED_DOMAINS" ]] || [[ ! -s "$RESOLVED_DOMAINS" ]]; then
        echo -e "${YELLOW}[!] No resolved domains to scan${NC}"
        return
    fi
    
    echo -e "${CYAN}[*]${NC} Scanning ports for ${GREEN}$DOMAIN${NC}"
    
    # Extract domains
    cut -d',' -f1 "$RESOLVED_DOMAINS" > "$OUTPUT_DIR/scan_targets.txt"
    
    if command_exists naabu; then
        echo -e "${CYAN}[*]${NC} Using Naabu for fast port scanning..."
        (
            naabu -list "$OUTPUT_DIR/scan_targets.txt" -top-ports 100 -silent > "$OUTPUT_DIR/ports.txt"
        ) &
        spinner $! "Port scanning in progress"
        
        if [[ -f "$OUTPUT_DIR/ports.txt" ]] && [[ -s "$OUTPUT_DIR/ports.txt" ]]; then
            echo -e "\n${GREEN}[+] Open Ports Found:${NC}"
            echo "================================================"
            cat "$OUTPUT_DIR/ports.txt"
            echo "================================================"
            echo "[+] Port scan saved to: $OUTPUT_DIR/ports.txt"
        fi
    elif command_exists nmap; then
        echo -e "${CYAN}[*]${NC} Using Nmap for port scanning..."
        (
            nmap -iL "$OUTPUT_DIR/scan_targets.txt" -T4 -F > "$OUTPUT_DIR/ports.txt"
        ) &
        spinner $! "Port scanning in progress"
        
        if [[ -f "$OUTPUT_DIR/ports.txt" ]] && [[ -s "$OUTPUT_DIR/ports.txt" ]]; then
            echo -e "\n${GREEN}[+] Open Ports Found:${NC}"
            echo "================================================"
            cat "$OUTPUT_DIR/ports.txt"
            echo "================================================"
            echo "[+] Port scan saved to: $OUTPUT_DIR/ports.txt"
        fi
    else
        echo -e "${YELLOW}[!] No port scanner installed${NC}"
        echo -e "${YELLOW}[!] Install with: sudo apt install nmap -y${NC}"
    fi
}

# Technology Detection
run_tech_detect() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[6/9] Technology Detection${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    if [[ ! -f "$RESOLVED_DOMAINS" ]] || [[ ! -s "$RESOLVED_DOMAINS" ]]; then
        echo -e "${YELLOW}[!] No resolved domains to analyze${NC}"
        return
    fi
    
    echo -e "${CYAN}[*]${NC} Detecting technologies for ${GREEN}$DOMAIN${NC}"
    
    cut -d',' -f1 "$RESOLVED_DOMAINS" > "$OUTPUT_DIR/tech_targets.txt"
    
    if command_exists httpx; then
        echo -e "${CYAN}[*]${NC} Using HTTPX for tech detection..."
        (
            httpx -l "$OUTPUT_DIR/tech_targets.txt" -tech-detect -silent > "$OUTPUT_DIR/technologies.txt"
        ) &
        spinner $! "Technology detection in progress"
        
        if [[ -f "$OUTPUT_DIR/technologies.txt" ]] && [[ -s "$OUTPUT_DIR/technologies.txt" ]]; then
            echo -e "\n${GREEN}[+] Technologies Detected:${NC}"
            echo "================================================"
            cat "$OUTPUT_DIR/technologies.txt"
            echo "================================================"
            echo "[+] Technologies saved to: $OUTPUT_DIR/technologies.txt"
        fi
    elif command_exists wappalyzer; then
        echo -e "${CYAN}[*]${NC} Using Wappalyzer for tech detection..."
        (
            while read -r target; do
                wappalyzer "http://$target" 2>/dev/null >> "$OUTPUT_DIR/technologies.txt"
            done < "$OUTPUT_DIR/tech_targets.txt"
        ) &
        spinner $! "Technology detection in progress"
    else
        echo -e "${YELLOW}[!] No tech detection tool installed${NC}"
    fi
}

# Screenshots
run_screenshots() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[7/9] Screenshots${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    if [[ ! -f "$LIVE_DOMAINS" ]] || [[ ! -s "$LIVE_DOMAINS" ]]; then
        echo -e "${YELLOW}[!] No live domains to screenshot${NC}"
        return
    fi
    
    echo -e "${CYAN}[*]${NC} Taking screenshots for ${GREEN}$DOMAIN${NC}"
    
    # Create screenshot directory
    mkdir -p "$OUTPUT_DIR/screenshots"
    
    # Extract domains from live.txt
    cut -d' ' -f1 "$LIVE_DOMAINS" | cut -d'[' -f1 > "$OUTPUT_DIR/screenshot_targets.txt"
    
    if command_exists aquatone; then
        echo -e "${CYAN}[*]${NC} Using Aquatone for screenshots..."
        (
            cat "$OUTPUT_DIR/screenshot_targets.txt" | aquatone -out "$OUTPUT_DIR/screenshots/" -silent
        ) &
        spinner $! "Taking screenshots"
        
        echo -e "\n${GREEN}[+] Screenshots saved to: $OUTPUT_DIR/screenshots/${NC}"
    elif command_exists cutycapt; then
        echo -e "${CYAN}[*]${NC} Using CutyCapt for screenshots..."
        while read -r domain; do
            cutycapt --url="http://$domain" --out="$OUTPUT_DIR/screenshots/${domain}.png"
        done < "$OUTPUT_DIR/screenshot_targets.txt"
    else
        echo -e "${YELLOW}[!] No screenshot tool installed${NC}"
        echo -e "${YELLOW}[!] Install Aquatone: https://github.com/michenriksen/aquatone${NC}"
    fi
}

# Generate HTML Report
generate_html_report() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[8/9] Generating HTML Report${NC} ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────┘${NC}"
    
    local html_file="$OUTPUT_DIR/report.html"
    
    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>recon-it Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #d32f2f; }
        h2 { color: #1976d2; border-bottom: 2px solid #1976d2; padding-bottom: 10px; }
        .section { margin: 20px 0; padding: 15px; background: #fafafa; border-radius: 5px; border-left: 4px solid #1976d2; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat { background: white; padding: 15px; border-radius: 5px; text-align: center; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .stat-number { font-size: 24px; font-weight: bold; color: #1976d2; }
        .stat-label { color: #666; font-size: 12px; text-transform: uppercase; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th { background: #1976d2; color: white; padding: 10px; text-align: left; }
        td { padding: 8px 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 11px; }
        .badge-green { background: #4caf50; color: white; }
        .badge-red { background: #f44336; color: white; }
        .badge-yellow { background: #ff9800; color: white; }
        .footer { text-align: center; margin-top: 30px; color: #999; font-size: 12px; }
    </style>
</head>
<body>
<div class="container">
    <h1>🔍 recon-it Scan Report</h1>
    <p><strong>Domain:</strong> DOMAIN_PLACEHOLDER</p>
    <p><strong>Date:</strong> DATE_PLACEHOLDER</p>
    <p><strong>Tool:</strong> recon-it v5.0 | <em>it's OUR tool</em></p>
    
    <div class="stats">
        <div class="stat">
            <div class="stat-number">TOTAL_PLACEHOLDER</div>
            <div class="stat-label">Total Subdomains</div>
        </div>
        <div class="stat">
            <div class="stat-number">RESOLVED_PLACEHOLDER</div>
            <div class="stat-label">Resolved</div>
        </div>
        <div class="stat">
            <div class="stat-number">LIVE_PLACEHOLDER</div>
            <div class="stat-label">Live (HTTP 200)</div>
        </div>
        <div class="stat">
            <div class="stat-number">PORTS_PLACEHOLDER</div>
            <div class="stat-label">Open Ports</div>
        </div>
    </div>
    
    <h2>📋 Subdomains Found</h2>
    <div class="section">
        <table>
            <tr><th>Subdomain</th><th>IP</th><th>Status</th></tr>
            SUBDOMAINS_PLACEHOLDER
        </table>
    </div>
    
    <h2>🖥️ Live Domains</h2>
    <div class="section">
        <table>
            <tr><th>Domain</th><th>Status</th><th>Title</th><th>Tech</th></tr>
            LIVE_PLACEHOLDER
        </table>
    </div>
    
    <h2>📡 Open Ports</h2>
    <div class="section">
        <pre style="background: #222; color: #0f0; padding: 15px; border-radius: 5px; overflow-x: auto;">
        PORTS_PLACEHOLDER
        </pre>
    </div>
    
    <div class="footer">
        Generated by recon-it | it's OUR tool
    </div>
</div>
</body>
</html>
EOF
    
    # Replace placeholders with actual data
    local total_subs=$(wc -l < "$ALL_SUBDOMAINS" 2>/dev/null || echo "0")
    local resolved_count=$(wc -l < "$RESOLVED_DOMAINS" 2>/dev/null || echo "0")
    local live_count=$(wc -l < "$LIVE_DOMAINS" 2>/dev/null || echo "0")
    local port_count=$(wc -l < "$OUTPUT_DIR/ports.txt" 2>/dev/null || echo "0")
    
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" "$html_file"
    sed -i "s/DATE_PLACEHOLDER/$(date)/g" "$html_file"
    sed -i "s/TOTAL_PLACEHOLDER/$total_subs/g" "$html_file"
    sed -i "s/RESOLVED_PLACEHOLDER/$resolved_count/g" "$html_file"
    sed -i "s/LIVE_PLACEHOLDER/$live_count/g" "$html_file"
    sed -i "s/PORTS_PLACEHOLDER/$port_count/g" "$html_file"
    
    # Add subdomains table
    local subdomains_html=""
    if [[ -f "$RESOLVED_DOMAINS" ]]; then
        while IFS=',' read -r domain ip; do
            status="✅ Resolved"
            color="badge-green"
            subdomains_html+="<tr><td>$domain</td><td>$ip</td><td><span class=\"badge $color\">$status</span></td></tr>\n"
        done < "$RESOLVED_DOMAINS"
    fi
    if [[ -f "$UNRESOLVED_DOMAINS" ]]; then
        while read -r domain; do
            status="❌ Unresolved"
            color="badge-red"
            subdomains_html+="<tr><td>$domain</td><td>-</td><td><span class=\"badge $color\">$status</span></td></tr>\n"
        done < "$UNRESOLVED_DOMAINS"
    fi
    sed -i "s|SUBDOMAINS_PLACEHOLDER|$subdomains_html|g" "$html_file"
    
    # Add live domains
    local live_html=""
    if [[ -f "$LIVE_DOMAINS" ]]; then
        while read -r line; do
            local domain=$(echo "$line" | cut -d'[' -f1 | xargs)
            local status=$(echo "$line" | grep -oP '\[[0-9]+\]' | head -1)
            local title=$(echo "$line" | grep -oP 'title="[^"]*"' | cut -d'"' -f2)
            live_html+="<tr><td>$domain</td><td>$status</td><td>$title</td><td>-</td></tr>\n"
        done < "$LIVE_DOMAINS"
    fi
    sed -i "s|LIVE_PLACEHOLDER|$live_html|g" "$html_file"
    
    # Add ports
    if [[ -f "$OUTPUT_DIR/ports.txt" ]]; then
        local ports_html=$(cat "$OUTPUT_DIR/ports.txt")
        sed -i "s|PORTS_PLACEHOLDER|$ports_html|g" "$html_file"
    else
        sed -i "s|PORTS_PLACEHOLDER|No ports scanned|g" "$html_file"
    fi
    
    echo -e "\n${GREEN}[+] HTML Report generated: $html_file${NC}"
    echo -e "${CYAN}[*] Open in browser: firefox $html_file${NC}"
}

# Help menu
show_help() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./recon-it.sh [OPTIONS] -d <domain>"
    echo ""
    echo -e "${YELLOW}Basic Options:${NC}"
    echo "  --install                   Auto-install all tools"
    echo "  -d, --domain <domain>       Target domain"
    echo "  --amass                     Enable Amass (deeper enumeration)"
    echo "  -h, --help                  Show this help"
    echo ""
    echo -e "${YELLOW}Advanced Options:${NC}"
    echo "  --ports                     Enable port scanning"
    echo "  --tech-detect               Enable technology detection"
    echo "  --screenshot                Take screenshots of live domains"
    echo "  --html-report               Generate HTML report"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  # Basic scan"
    echo "  ./recon-it.sh -d example.com"
    echo ""
    echo "  # Full scan with all features"
    echo "  ./recon-it.sh -d example.com --amass --ports --tech-detect --screenshot --html-report"
    echo ""
    echo "  # Install tools"
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
            --ports)
                PORT_SCAN=true
                shift
                ;;
            --tech-detect)
                TECH_DETECT=true
                shift
                ;;
            --screenshot)
                SCREENSHOT=true
                shift
                ;;
            --html-report)
                HTML_REPORT=true
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
    
    if [[ "$INSTALL_MODE" == "true" ]]; then
        install_all_tools
        install_advanced_tools
        echo -e "${GREEN}[+] All tools installed!${NC}"
        exit 0
    fi
    
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}[!] Domain required${NC}"
        show_help
        exit 1
    fi
    
    # Initialize output
    init_output
    
    # Run phases
    phase1_basic_info
    phase2_subdomain_enum
    phase3_filter_resolve
    phase4_http_probe
    
    # Advanced features
    [[ "$PORT_SCAN" == "true" ]] && run_port_scan
    [[ "$TECH_DETECT" == "true" ]] && run_tech_detect
    [[ "$SCREENSHOT" == "true" ]] && run_screenshots
    [[ "$HTML_REPORT" == "true" ]] && generate_html_report
    
    generate_report
    
    echo -e "\n${GREEN}[+] Scan completed at $(date)${NC}"
    echo -e "${RED}[+] it's OUR tool!${NC}"
}

main "$@"
