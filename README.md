# deSEC Dynamic DNS Client (Multi-Zone)

A lightweight Bash script to update deSEC dynamic DNS records (IPv6) for multiple zones. This script monitors your network interfaces for IP changes and automatically updates your deSEC records when a new dynamic IP is assigned.

## Features

- **Multi-Zone Support**: Manage multiple domains/hostnames easily.
- **Independent Configuration**: Each zone has its own configuration file.
- **IP Change Detection**: Tracks IP history per interface to minimize unnecessary API calls.
- **Systemd Integration**: Includes a service template for background operation.
- **Clean & Simple**: Native Bash with minimal dependencies (`curl`, `iproute2`).

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Docmine17/desec.git
   cd desec
   ```

2. **Set up permissions**:
   ```bash
   chmod +x desec.sh
   ```

## Configuration

The script looks for `.conf` files in the `zones/` directory by default.

1. **Create the zones directory**:
   ```bash
   mkdir -p zones
   ```

2. **Add a configuration for each zone**:
   Create a file inside `zones/` (e.g., `myhome.dedyn.io.conf`):
   ```bash
   TOKEN="your_desec_token_here"
   INTERFACE="eth0"
   ```
   *Replace `eth0` with your actual network interface (use `ip addr` to find it).*

## Usage

### Run Manually
```bash
./desec.sh
```

### Specifying a Custom Config Directory
```bash
./desec.sh --zone /path/to/your/configs/
```

## Running as a Service (Systemd)

To keep the script running in the background:

1. **Edit the service file**:
   Open `desec-dns.service` and update `ExecStart` with the absolute path to your script:
   ```ini
   ExecStart=/bin/bash /home/youruser/scripts/desec/desec.sh
   ```

2. **Install the service**:
   ```bash
   sudo cp desec-dns.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable desec-dns.service
   sudo systemctl start desec-dns.service
   ```

3. **Check status**:
   ```bash
   sudo systemctl status desec-dns.service
   ```

## License

MIT License
