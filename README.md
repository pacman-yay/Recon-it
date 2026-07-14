# recon-it

**Unified Reconnaissance Tool** | it's OUR tool

## Installation

### Quick Install

```bash
git clone https://github.com/yourusername/recon-it.git
cd recon-it
chmod +x recon-it.sh
./recon-it.sh --install
```

### Manual Install

```bash
# Make executable
chmod +x recon-it.sh

# Install dependencies
./recon-it.sh --install
```

## Usage

```bash
./recon-it.sh [OPTIONS] -d <domain>
```

## Options

### Target Options

| Flag | Description |
|---|---|
| `-d, --domain` | Target domain |
| `-f, --domain-list` | File with list of domains |

### Module Options

| Flag | Tool | Description |
|---|---|---|
| `-a, --all` | All tools | Run everything |
| `-w, --whois` | WHOIS | Domain registration info |
| `-n, --dnsdumpster` | DNSDumpster | DNS enumeration via API |
| `-r, --dnsrecon` | DNSRecon | DNS records enumeration |
| `-s, --subfinder` | Subfinder | Passive subdomain discovery |
| `-m, --amass` | Amass | OWASP subdomain enumeration |
| `-t, --assetfinder` | Assetfinder | Fast subdomain discovery |
| `-u, --sublist3r` | Sublist3r | Subdomain brute-force |
| `-x, --httpx` | HTTPX | HTTP probing and tech detection |

### Subdomain Options

| Flag | Description |
|---|---|
| `--subdomain-all` | Run all subdomain tools |
| `--subdomain-aggressive` | Aggressive Amass (active+brute) |
| `--output-subdomains` | Save subdomains to file |

### Installation Options

| Flag | Description |
|---|---|
| `--install` | Auto-install missing tools |
| `--skip-install` | Skip all installation prompts |

### Logging Options

| Flag | Description |
|---|---|
| `-o, --output` | Output file |
| `-l, --log-file` | Log file |
| `--log-level` | DEBUG, INFO, WARNING, ERROR |
| `-v, --verbose` | Verbose output |
| `-q, --quiet` | Quiet mode |
| `--json-log` | JSON format logs |
| `--append` | Append to output file |

### Performance Options

| Flag | Description |
|---|---|
| `--threads` | Number of threads (default: 10) |
| `--timeout` | Timeout in seconds (default: 30) |

### Other

| Flag | Description |
|---|---|
| `-h, --help` | Show help |

## Examples

### Basic Usage

```bash
# Full reconnaissance
./recon-it.sh -d example.com -a

# Subdomain enumeration only
./recon-it.sh -d example.com --subdomain-all

# Specific tools
./recon-it.sh -d example.com -m -t -u -s

# WHOIS + HTTPX only
./recon-it.sh -d example.com -w -x
```

### Advanced Usage

```bash
# Aggressive subdomain scan
./recon-it.sh -d example.com -m --subdomain-aggressive -v

# Save subdomains to file
./recon-it.sh -d example.com -m -t -u --output-subdomains subs.txt

# Batch scan multiple domains
./recon-it.sh -f domains.txt -a --threads 10 -l scan.log

# Full recon with all logging
./recon-it.sh -d example.com -a -o output.txt -l scan.log --json-log --output-subdomains subs.txt
```

### Installation

```bash
# Auto-install all missing tools
./recon-it.sh --install

# Run scan without install prompts
./recon-it.sh -d example.com -a --skip-install
```

## Modes

| Mode | Command | Description |
|---|---|---|
| Single Domain | `-d example.com` | Scan one domain |
| Batch | `-f domains.txt` | Scan multiple domains |
| Full Auto | `-a` | Run all modules |
| Subdomain All | `--subdomain-all` | All subdomain tools |
| Aggressive | `--subdomain-aggressive` | Active subdomain enumeration |
| Install | `--install` | Install missing tools |

## Tools Included

| Tool | Purpose | Installation |
|---|---|---|
| WHOIS | Domain registration info | `apt install whois` |
| DNSDumpster | DNS enumeration | Uses API (no install) |
| DNSRecon | DNS records | `pip install dnsrecon` |
| Subfinder | Passive subdomains | GitHub |
| Amass | Subdomain enumeration | `apt install amass` or Go install |
| Assetfinder | Fast subdomains | `go install` |
| Sublist3r | Subdomain brute-force | git clone + setup.py |
| HTTPX | HTTP probing | GitHub |

## Logging Examples

### Log Levels

```bash
# Debug - everything
./recon-it.sh -d example.com -a --log-level DEBUG -v

# Info only (default)
./recon-it.sh -d example.com -a

# Warnings and errors only
./recon-it.sh -d example.com -a --log-level WARNING

# Errors only
./recon-it.sh -d example.com -a --log-level ERROR

# Quiet mode (no console output)
./recon-it.sh -d example.com -a -q
```

### Output Formats

```bash
# Regular text output
./recon-it.sh -d example.com -a -o results.txt

# JSON logs
./recon-it.sh -d example.com -a --json-log

# Append to existing file
./recon-it.sh -d example.com -a -o results.txt --append
```

## Dependencies

### Required

- whois
- dig / host (dnsutils)
- curl

### Optional (auto-installed)

- dnsrecon
- subfinder
- amass
- assetfinder
- sublist3r
- httpx

## License

MIT License

## Contributing

Pull requests welcome. For major changes, please open an issue first.

## Author

Your Name

## Support

- Issues: GitHub Issues
- Documentation: `./recon-it.sh -h`

---

**Remember:** Use responsibly. Only scan domains you own or have permission to test.
