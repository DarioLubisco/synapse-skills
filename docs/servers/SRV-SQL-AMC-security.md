# SRV-SQL-AMC — Security Hardening

**Server:** `SRV-SQL-AMC` (`10.200.8.5`)  
**Applied:** 2026-07-07  
**Network:** Internal LAN `10.200.8.0/24` + ZeroTier `10.147.18.192`  
**Exposure:** Not internet-routable (private IP). Main risk = lateral movement on LAN.

---

## Open ports (before hardening)

| Port | Service | Risk |
|------|---------|------|
| 22 | SSH (OpenSSH for Windows 9.5) | Medium |
| 135 | MSRPC | Medium |
| 139 | NetBIOS | High |
| 445 | SMB | High |
| 3389 | RDP | Medium |

---

## Trusted IPs (firewall allow list)

Inbound access on ports **22, 135, 139, 445, 3389** is allowed **only** from:

| IP | Role |
|----|------|
| `10.200.8.167` | Admin PC (DARIO-DESKTOP / Ethernet) |
| `10.147.18.4` | External server (ZeroTier) |

All other hosts on **`10.200.8.0/24`** are **blocked** on those ports.

### Firewall rule names

**Allow rules:**
- `SecAllow-Port22-From-10-200-8-167`
- `SecAllow-Port135-From-10-200-8-167`
- `SecAllow-Port139-From-10-200-8-167`
- `SecAllow-Port445-From-10-200-8-167`
- `SecAllow-Port3389-From-10-200-8-167`
- `SecAllow-Port22-From-10-147-18-4`
- `SecAllow-Port135-From-10-147-18-4`
- `SecAllow-Port139-From-10-147-18-4`
- `SecAllow-Port445-From-10-147-18-4`
- `SecAllow-Port3389-From-10-147-18-4`

**Block rules:**
- `SecBlock-Port22-From-LAN`
- `SecBlock-Port135-From-LAN`
- `SecBlock-Port139-From-LAN`
- `SecBlock-Port445-From-LAN`
- `SecBlock-Port3389-From-LAN`

### Add another trusted IP

```powershell
$ip = '10.147.18.X'
$ports = @(22, 135, 139, 445, 3389)
foreach ($port in $ports) {
  New-NetFirewallRule -DisplayName "SecAllow-Port$port-From-$($ip.Replace('.','-'))" `
    -Direction Inbound -Protocol TCP -LocalPort $port `
    -RemoteAddress $ip -Action Allow -Profile Any
}
```

---

## SMB hardening

| Setting | Before | After |
|---------|--------|-------|
| SMB1 | Disabled | Disabled |
| Require security signature | Off | **On** |
| Encrypt data | Off | **On** |

### Shares

| Share | Path | ACL (after) |
|-------|------|-------------|
| `SQL` | `C:\Saint\SQL` | `Administrators` Full, `Authenticated Users` Change |
| `ADMIN$`, `C$`, `E$`, `F$`, `IPC$` | Default admin shares | Unchanged |

**Removed:** `Everyone` Full on `SQL` share.

---

## SSH

- **Service:** `sshd` — Running, Automatic
- **Decision:** Kept enabled (used for remote admin)
- **Restriction:** IP-scoped via firewall rules above
- **Password auth:** Still enabled (default `sshd_config`)
- **Recommended next step:** Set up key-based auth, then set `PasswordAuthentication no`

---

## Server network interfaces

| IP | Interface |
|----|-----------|
| `10.200.8.5` | Ethernet (LAN) |
| `10.147.18.192` | ZeroTier |
| `10.252.1.12` | (secondary) |
| `169.254.83.107` | Link-local |

---

## Verification commands

From a **trusted** IP (admin PC):

```powershell
Test-NetConnection 10.200.8.5 -Port 22
Test-NetConnection 10.200.8.5 -Port 3389
Test-NetConnection 10.200.8.5 -Port 445
```

From an **untrusted** LAN host (should fail after rules):

```powershell
22,135,139,445,3389 | ForEach-Object {
  [PSCustomObject]@{
    Port = $_
    Open = (Test-NetConnection 10.200.8.5 -Port $_ -WarningAction SilentlyContinue).TcpTestSucceeded
  }
}
```

---

## Pending recommendations

1. Rotate `administrator` password (used in prior remote sessions).
2. Migrate SSH to key-only authentication.
3. Test `SQL` share access from apps that depend on it.
4. Confirm no edge NAT/port-forward to this host on the router/firewall.
5. Consider dedicated server VLAN with ACLs at switch level.

---

## Rollback (emergency)

```powershell
# Remove security rules
Get-NetFirewallRule -DisplayName 'Sec*' | Remove-NetFirewallRule

# Revert SMB signing/encryption (if needed)
Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
Set-SmbServerConfiguration -EncryptData $false -Force

# Restore SQL share Everyone access (not recommended)
Grant-SmbShareAccess -Name SQL -AccountName Everyone -AccessRight Full -Force
```
