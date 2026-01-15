#!/bin/bash

# ==============================================================================
# Default Configuration
# ==============================================================================
CHECK_INTERVAL=20
CONFIG_DIR=""

# ==============================================================================
# Functions
# ==============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

usage() {
    echo "Usage: $0 [--zone /path/to/zones/]"
    echo "  --zone: Directory containing .conf files for each zone."
    echo "          Default: <script_dir>/zones/"
    exit 1
}

update_ip() {
    local ZONE=$1
    local TOKEN=$2
    
    # Check basic connectivity before trying to update
    if ping -6 -c 1 -W 1 update6.dedyn.io >/dev/null 2>&1; then
        log "[$ZONE] Connectivity OK. Sending update..."
        
        # deSEC Update API
        response=$(curl -s -w "%{http_code}" \
            -H "Authorization: Token $TOKEN" \
            "https://update6.dedyn.io/?hostname=$ZONE")
        
        http_code=${response: -3}
        
        if [[ "$http_code" =~ 20[01] ]]; then
            log "[$ZONE] Success: Address updated (HTTP $http_code)."
            return 0
        else
            log "[$ZONE] Error: Update failed (HTTP $http_code). Response: ${response:0:-3}"
            return 1
        fi
    else
        log "[$ZONE] Error: Connection to deSEC failed."
        return 1
    fi
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --zone) CONFIG_DIR="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# Default path if not specified
if [ -z "$CONFIG_DIR" ]; then
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    CONFIG_DIR="$SCRIPT_DIR/zones"
fi

if [ ! -d "$CONFIG_DIR" ]; then
    log "Error: Configuration directory not found: $CONFIG_DIR"
    exit 1
fi

# ==============================================================================
# Main Execution
# ==============================================================================

log "Starting deSEC multi-zone script. Config dir: $CONFIG_DIR"

# State management for IP per interface (simplified for multi-zone)
declare -A previous_ips

while true; do
  for zone_conf in "$CONFIG_DIR"/*.conf; do
    [ -e "$zone_conf" ] || { log "No .conf files found in $CONFIG_DIR"; break; }
    
    # Load zone configuration
    ZONE_NAME=$(basename "$zone_conf" .conf)
    INTERFACE=""
    TOKEN=""
    
    source "$zone_conf"
    
    # Validation
    if [ -z "$TOKEN" ] || [ -z "$INTERFACE" ]; then
        log "[$ZONE_NAME] Skip: Missing TOKEN or INTERFACE in $zone_conf"
        continue
    fi

    # Extracts the dynamic IPv6 address from the interface
    current_ip=$(ip -6 addr show dev "$INTERFACE" dynamic 2>/dev/null | awk '/inet6/ {print $2; exit}')
    
    if [ -n "$current_ip" ]; then
        # Check if IP changed for THIS interface
        if [ "$current_ip" != "${previous_ips[$INTERFACE]}" ]; then
            log "[$ZONE_NAME] IP change detected on $INTERFACE ($current_ip). Updating..."
            if update_ip "$ZONE_NAME" "$TOKEN"; then
                previous_ips[$INTERFACE]="$current_ip"
            fi
        fi
    else
        log "[$ZONE_NAME] Warning: No valid IP found on interface $INTERFACE."
    fi
  done
  
  sleep "$CHECK_INTERVAL"
done
