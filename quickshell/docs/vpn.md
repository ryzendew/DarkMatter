# VPN Integration Guide for Linux Network Management

## Table of Contents
1. [Overview](#overview)
2. [How VPNs Work in Linux](#how-vpns-work-in-linux)
3. [VPN Protocols Supported](#vpn-protocols-supported)
4. [NetworkManager Integration](#networkmanager-integration)
5. [Current Implementation](#current-implementation)
6. [Enhancing VPN Functionality](#enhancing-vpn-functionality)
7. [Technical Implementation Details](#technical-implementation-details)
8. [VPN Configuration Methods](#vpn-configuration-methods)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## Overview

Virtual Private Networks (VPNs) create secure, encrypted tunnels between your device and a remote server, protecting your internet traffic and masking your IP address. On Linux, VPNs are primarily managed through NetworkManager, which provides both command-line (`nmcli`) and D-Bus interfaces for VPN management.

## How VPNs Work in Linux

### Core Concepts

1. **Tunneling**: VPNs create a virtual network interface that routes traffic through an encrypted tunnel
2. **Encryption**: All data is encrypted before transmission, ensuring privacy
3. **Authentication**: VPNs use various authentication methods (certificates, passwords, keys)
4. **Routing**: NetworkManager handles routing tables to direct traffic through the VPN

### NetworkManager Architecture

NetworkManager is the standard network management daemon on most Linux distributions. It:
- Manages network connections (wired, wireless, VPN)
- Provides D-Bus API for applications
- Supports plugins for different VPN protocols
- Handles connection state and configuration persistence

## VPN Protocols Supported

### 1. OpenVPN
- **Status**: Most widely supported
- **Plugin**: `network-manager-openvpn`
- **Config Format**: `.ovpn` files
- **Features**: 
  - Certificate-based authentication
  - Username/password authentication
  - Custom encryption settings
  - Support for complex network topologies

### 2. WireGuard
- **Status**: Modern, high-performance protocol
- **Plugin**: Native NetworkManager support (since NM 1.20+)
- **Config Format**: Native NetworkManager or `wg-quick` format
- **Features**:
  - Simple configuration
  - Fast performance
  - Modern cryptography
  - Built into Linux kernel (5.6+)

### 3. IKEv2/IPsec
- **Status**: Enterprise-grade protocol
- **Plugin**: `NetworkManager-strongswan` or `NetworkManager-libreswan`
- **Config Format**: NetworkManager native
- **Features**:
  - Strong security
  - Mobile-friendly (auto-reconnect)
  - Certificate or EAP authentication

### 4. L2TP/IPsec
- **Status**: Legacy but still used
- **Plugin**: `network-manager-l2tp`
- **Config Format**: NetworkManager native
- **Features**:
  - Widely compatible
  - Pre-shared key or certificate authentication

### 5. PPTP
- **Status**: Deprecated (insecure)
- **Plugin**: `network-manager-pptp`
- **Note**: Not recommended for security reasons

### 6. Cisco AnyConnect / OpenConnect
- **Status**: Enterprise VPN support
- **Plugin**: `network-manager-openconnect`
- **Features**: Supports Cisco AnyConnect, Juniper, Palo Alto, etc.

## NetworkManager Integration

### D-Bus Interface

NetworkManager exposes VPN functionality through D-Bus:

```
org.freedesktop.NetworkManager
├── /org/freedesktop/NetworkManager
│   ├── ActiveConnection
│   ├── Connection
│   └── Settings
```

### Key D-Bus Methods

- `org.freedesktop.NetworkManager.AddConnection()` - Add new VPN connection
- `org.freedesktop.NetworkManager.ActivateConnection()` - Connect VPN
- `org.freedesktop.NetworkManager.DeactivateConnection()` - Disconnect VPN
- `org.freedesktop.NetworkManager.GetAllConnections()` - List all connections

### nmcli Commands

NetworkManager's command-line interface provides VPN management:

```bash
# List all VPN connections
nmcli connection show type vpn wireguard

# Show VPN connection details
nmcli connection show "VPN Name"

# Connect to VPN
nmcli connection up "VPN Name"
nmcli connection up uuid <uuid>

# Disconnect VPN
nmcli connection down "VPN Name"
nmcli connection down uuid <uuid>

# Add new OpenVPN connection
nmcli connection add type vpn vpn-type openvpn con-name "MyVPN" \
  vpn.data "remote=server.example.com, username=user" \
  vpn.secrets "password=secret"

# Add new WireGuard connection
nmcli connection add type wireguard con-name "MyWireGuard" \
  wireguard.private-key "..." \
  ipv4.method auto

# Import OpenVPN config file
nmcli connection import type openvpn file /path/to/config.ovpn

# Monitor VPN state changes
gdbus monitor --system --dest org.freedesktop.NetworkManager
```

## Current Implementation

### VpnService.qml

The current `VpnService.qml` provides:

**Properties:**
- `available`: Boolean indicating if VPN service is available
- `profiles`: Array of VPN profiles `[{name, uuid, type, serviceType}]`
- `activeConnections`: Array of active VPN connections
- `connected`: Boolean indicating if any VPN is connected
- `isBusy`: Boolean indicating if operation is in progress

**Functions:**
- `listProfiles()`: Refresh list of VPN profiles
- `refreshActive()`: Refresh active VPN connections
- `connect(uuidOrName)`: Connect to VPN
- `disconnect(uuidOrName)`: Disconnect VPN
- `toggle(uuid)`: Toggle VPN connection
- `disconnectAllActive()`: Disconnect all active VPNs

**Monitoring:**
- Uses `gdbus monitor` to watch NetworkManager D-Bus events
- Automatically refreshes on connection state changes

### NetworkTab.qml Integration

Current VPN section in NetworkTab:
- Lists all VPN profiles
- Shows connection status
- Provides Connect/Disconnect buttons
- Shows VPN type and service type
- Edit button for each profile

## Enhancing VPN Functionality

### 1. Add VPN Connection Wizard

Create a modal/dialog to add new VPN connections:

**Features to implement:**
- VPN type selection (OpenVPN, WireGuard, IKEv2, etc.)
- Import `.ovpn` file option
- Manual configuration form
- Credential input (with secure storage)
- Connection testing

**Implementation approach:**
```qml
// New VPN connection modal
ConnectionAddModal {
    vpnTypes: ["OpenVPN", "WireGuard", "IKEv2", "L2TP"]
    onImportFile: (filePath) => {
        // Use nmcli connection import
    }
    onManualConfig: (config) => {
        // Use nmcli connection add with config
    }
}
```

### 2. Enhanced VPN Status Display

**Additional information to show:**
- Connection duration
- Data transferred (bytes up/down)
- Server location/IP
- Connection quality/strength
- Current IP address (via VPN)
- DNS servers in use

**Implementation:**
```bash
# Get connection statistics
nmcli connection show "VPN Name" | grep -E "IP4|IP6|GENERAL"

# Get active connection details
nmcli -t -f NAME,UUID,DEVICE,STATE connection show --active

# Get VPN-specific info
nmcli -g vpn.data connection show "VPN Name"
```

### 3. VPN Profile Management

**Features:**
- Edit existing VPN profiles
- Delete VPN profiles
- Duplicate/clone profiles
- Export VPN configuration
- Set as default/auto-connect

**Commands:**
```bash
# Edit connection
nmcli connection edit "VPN Name"

# Delete connection
nmcli connection delete "VPN Name"

# Modify connection
nmcli connection modify "VPN Name" vpn.data "key=value"

# Set auto-connect
nmcli connection modify "VPN Name" connection.autoconnect yes
```

### 4. Advanced VPN Features

**Kill Switch:**
- Block all traffic if VPN disconnects
- Implement using iptables rules
- Monitor VPN state and apply firewall rules

**Split Tunneling:**
- Route only specific traffic through VPN
- Configure routing tables
- Use NetworkManager's routing configuration

**Multi-VPN Support:**
- Allow multiple VPNs simultaneously
- Manage VPN priority/routing
- Current implementation supports this via `singleActive: false`

**Connection Quality Monitoring:**
- Ping VPN server
- Monitor latency
- Track connection stability

### 5. WireGuard-Specific Features

WireGuard has unique configuration needs:

**Key Management:**
- Generate key pairs
- Display public key for server configuration
- Import existing keys

**Peer Configuration:**
- Add/remove peers
- Configure allowed IPs
- Set endpoint addresses

**Commands:**
```bash
# Generate WireGuard keys
wg genkey | tee privatekey | wg pubkey > publickey

# Show WireGuard interface
wg show

# Add WireGuard connection
nmcli connection add type wireguard con-name "WG1" \
  wireguard.private-key "$(cat privatekey)" \
  wireguard.peers "[{public-key=...,endpoint=server:51820,allowed-ips=0.0.0.0/0}]" \
  ipv4.method auto
```

### 6. OpenVPN-Specific Features

**Configuration Import:**
- Parse `.ovpn` files
- Extract server, port, protocol
- Handle certificate files
- Parse custom options

**Advanced Options:**
- Compression settings
- Cipher selection
- TLS version
- Custom routes

**Commands:**
```bash
# Import OpenVPN config
nmcli connection import type openvpn file config.ovpn

# Show OpenVPN-specific settings
nmcli -g vpn.data connection show "OpenVPN-Name"
```

## Technical Implementation Details

### Detecting VPN Types

```bash
# List VPN connections with service type
nmcli -t -f NAME,UUID,TYPE connection show | \
  while IFS=: read -r name uuid type; do
    case "$type" in
      vpn)
        svc=$(nmcli -g vpn.service-type connection show uuid "$uuid" 2>/dev/null)
        echo "$name:$uuid:$type:$svc"
        ;;
      wireguard)
        echo "$name:$uuid:$type:"
        ;;
    esac
  done
```

### Monitoring VPN State

**D-Bus Monitoring:**
```bash
gdbus monitor --system --dest org.freedesktop.NetworkManager
```

**Watch for events:**
- `ActiveConnection` - New connection activated
- `PropertiesChanged` - Connection properties changed
- `StateChanged` - Connection state changed

**Connection States:**
- `0` - Unknown
- `1` - Activating
- `2` - Activated
- `3` - Deactivating
- `4` - Deactivated

### Getting Connection Details

```bash
# Get all connection properties
nmcli -t connection show "VPN Name"

# Get specific VPN data
nmcli -g vpn.data connection show "VPN Name"
nmcli -g vpn.secrets connection show "VPN Name"

# Get active connection info
nmcli -t -f NAME,UUID,TYPE,DEVICE,STATE connection show --active
```

### Error Handling

**Common VPN Errors:**
- Authentication failures
- Network unreachable
- Certificate validation errors
- Timeout errors
- Configuration errors

**Error Detection:**
```bash
# Check nmcli exit codes
# 0 = success
# 1 = unknown error
# 2 = invalid user input
# 3 = timeout
# 4 = connection activation failed
# 5 = connection deactivation failed
# 6 = disconnecting device failed
# 7 = connection deletion failed
# 8 = network manager not running
# 9 = connection not found
# 10 = connection not active
# 11 = connection already active
# 12 = connection type not supported
```

## VPN Configuration Methods

### Method 1: Import Configuration File

**OpenVPN (.ovpn):**
```bash
nmcli connection import type openvpn file /path/to/config.ovpn
```

**WireGuard:**
```bash
# WireGuard configs are typically added manually via nmcli
# or through NetworkManager GUI
```

### Method 2: Manual Configuration via nmcli

**OpenVPN:**
```bash
nmcli connection add type vpn \
  vpn-type openvpn \
  con-name "MyOpenVPN" \
  vpn.data "remote=server.example.com, port=1194, proto=udp, username=user" \
  vpn.secrets "password=secret" \
  ipv4.method auto
```

**WireGuard:**
```bash
nmcli connection add type wireguard \
  con-name "MyWireGuard" \
  wireguard.private-key "$(wg genkey)" \
  wireguard.peers "[{public-key=...,endpoint=server:51820,allowed-ips=0.0.0.0/0}]" \
  ipv4.method auto \
  ipv4.addresses "10.0.0.2/24"
```

**IKEv2:**
```bash
nmcli connection add type vpn \
  vpn-type ikev2 \
  con-name "MyIKEv2" \
  vpn.data "address=server.example.com, certificate=/path/to/cert.pem" \
  vpn.secrets "password=secret" \
  ipv4.method auto
```

### Method 3: D-Bus API

**Using gdbus or qdbus:**
```bash
# Add connection via D-Bus
gdbus call --system \
  --dest org.freedesktop.NetworkManager \
  --object-path /org/freedesktop/NetworkManager/Settings \
  --method org.freedesktop.NetworkManager.Settings.AddConnection \
  '<connection>...</connection>'
```

### Method 4: Configuration Files

NetworkManager stores connections in:
- `/etc/NetworkManager/system-connections/` (system-wide)
- `~/.config/NetworkManager/connections/` (user-specific, if enabled)

**Format:** INI-style files with UUID as filename

## Best Practices

### Security

1. **Credential Storage:**
   - Use NetworkManager's secret storage (uses system keyring)
   - Never store passwords in plain text
   - Use certificate-based authentication when possible

2. **Connection Validation:**
   - Verify server certificates
   - Use strong encryption (AES-256)
   - Disable weak protocols (PPTP)

3. **Access Control:**
   - Require appropriate permissions for VPN management
   - Validate user input before passing to nmcli
   - Sanitize file paths for imports

### User Experience

1. **Status Feedback:**
   - Show clear connection states
   - Display error messages clearly
   - Provide loading indicators during operations

2. **Error Handling:**
   - Parse nmcli error messages
   - Provide actionable error messages
   - Log errors for debugging

3. **Performance:**
   - Cache VPN profile list
   - Use efficient D-Bus monitoring
   - Avoid blocking UI during operations

### Code Organization

1. **Service Layer:**
   - Keep VPN logic in VpnService
   - Separate UI from business logic
   - Use signals for state changes

2. **Error Recovery:**
   - Implement retry logic for transient failures
   - Handle network timeouts gracefully
   - Provide fallback mechanisms

## Troubleshooting

### Common Issues

**1. VPN profiles not showing:**
```bash
# Check if NetworkManager is running
systemctl status NetworkManager

# Check if VPN plugins are installed
dpkg -l | grep network-manager

# Refresh connections
nmcli connection reload
```

**2. Cannot connect to VPN:**
```bash
# Check VPN service status
nmcli connection show "VPN Name"

# Check logs
journalctl -u NetworkManager -f

# Test connection manually
nmcli connection up "VPN Name" --verbose
```

**3. VPN connects but no internet:**
```bash
# Check routing
ip route show

# Check DNS
nmcli -g ipv4.dns connection show "VPN Name"

# Verify VPN gateway
ip addr show
```

**4. WireGuard not working:**
```bash
# Check kernel module
lsmod | grep wireguard

# Check WireGuard status
wg show

# Verify configuration
nmcli connection show "WireGuard-Name"
```

### Debugging Commands

```bash
# Enable NetworkManager debug logging
nmcli general logging level DEBUG domains ALL

# Monitor D-Bus events
gdbus monitor --system --dest org.freedesktop.NetworkManager

# Check connection details
nmcli -t connection show "VPN Name"

# Test connection with verbose output
nmcli connection up "VPN Name" --verbose

# View NetworkManager logs
journalctl -u NetworkManager --since "1 hour ago"
```

## Implementation Roadmap

### Phase 1: Enhanced Profile Management
- [ ] Add VPN connection wizard
- [ ] Import .ovpn file support
- [ ] Edit VPN profiles
- [ ] Delete VPN profiles
- [ ] Export VPN configuration

### Phase 2: Advanced Features
- [ ] Connection statistics (duration, data transfer)
- [ ] Server information display
- [ ] Connection quality monitoring
- [ ] Auto-connect configuration
- [ ] Connection priority management

### Phase 3: Protocol-Specific Features
- [ ] WireGuard key generation
- [ ] OpenVPN advanced options
- [ ] IKEv2 certificate management
- [ ] Split tunneling configuration

### Phase 4: Security Features
- [ ] Kill switch implementation
- [ ] DNS leak protection
- [ ] Connection validation
- [ ] Security audit logging

## References

- NetworkManager Documentation: https://networkmanager.dev/
- nmcli Manual: `man nmcli`
- NetworkManager D-Bus API: https://developer.gnome.org/NetworkManager/stable/spec.html
- WireGuard Documentation: https://www.wireguard.com/
- OpenVPN Documentation: https://openvpn.net/community-resources/

## Example Code Snippets

### Adding OpenVPN Connection

```javascript
function addOpenVPNConnection(name, server, port, username, password) {
    const cmd = [
        "nmcli", "connection", "add",
        "type", "vpn",
        "vpn-type", "openvpn",
        "con-name", name,
        "vpn.data", `remote=${server},port=${port},proto=udp,username=${username}`,
        "vpn.secrets", `password=${password}`,
        "ipv4.method", "auto"
    ];
    // Execute command via Process
}
```

### Adding WireGuard Connection

```javascript
function addWireGuardConnection(name, privateKey, publicKey, endpoint, allowedIPs) {
    const peerConfig = JSON.stringify([{
        "public-key": publicKey,
        "endpoint": endpoint,
        "allowed-ips": allowedIPs
    }]);
    
    const cmd = [
        "nmcli", "connection", "add",
        "type", "wireguard",
        "con-name", name,
        "wireguard.private-key", privateKey,
        "wireguard.peers", peerConfig,
        "ipv4.method", "auto"
    ];
    // Execute command via Process
}
```

### Monitoring VPN State

```javascript
Process {
    id: vpnMonitor
    command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.NetworkManager"]
    running: true
    
    stdout: SplitParser {
        splitMarker: "\n"
        onRead: line => {
            if (line.includes("ActiveConnection") || 
                line.includes("StateChanged") ||
                line.includes("PropertiesChanged")) {
                VpnService.refreshAll()
            }
        }
    }
}
```

---

This document provides a comprehensive guide for implementing and enhancing VPN functionality in the Network tab. Use it as a reference for adding new features and troubleshooting issues.

