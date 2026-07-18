# SRV-SQL-AMC — Security Hardening

**Server:** `SRV-SQL-AMC` (`10.200.8.5`)  
**Applied:** 2026-07-07 (updated 2026-07-18 — SQL VPN access)  
**Exposure:** Not internet-routable (private IP). Main risk = lateral movement on LAN.

---

## srv-sql-amc — all IPs

| Network | IP | Route | Use |
|---------|-----|-------|-----|
| **Tailscale** | `100.94.5.108` | Primary VPN | `DB_SERVER` default |
| **ZeroTier** | `10.147.18.192` | Alternative VPN | Plan B if Tailscale fails |
| **LAN** | `10.200.8.5` | On-premises only | Local admin / batch on site |

**Instance:** `Saint\efficacis3` (dynamic port **49751**)

---

## SQL Server access (VPN)

| Port | Protocol | Purpose | Allowed from |
|------|----------|---------|--------------|
| **49751** | TCP | SQL Server instance (`efficacis3`) | Tailscale `100.64.0.0/10`, ZeroTier `10.147.18.0/24`, admin `10.200.8.167` |
| **1434** | UDP | SQL Server Browser (resolves `\efficacis3`) | Same as above |

### Firewall rule names (SQL)

- `SecAllow-SQL-TCP49751-Tailscale`
- `SecAllow-SQL-TCP49751-ZeroTier`
- `SecAllow-SQL-TCP49751-AdminLAN`
- `SecAllow-SQL-UDP1434-Tailscale`
- `SecAllow-SQL-UDP1434-ZeroTier`
- `SecAllow-SQL-UDP1434-AdminLAN`

### Connection strings (plan B)

```text
# Primary (Tailscale)
DB_SERVER=100.94.5.108,49751

# Fallback (ZeroTier)
DB_SERVER=10.147.18.192,49751

# Named instance (requires UDP 1434)
DB_SERVER=100.94.5.108\efficacis3
DB_SERVER=10.147.18.192\efficacis3
```

### Verify SQL ports

```powershell
Test-NetConnection 100.94.5.108 -Port 49751
Test-NetConnection 10.147.18.192 -Port 49751
```

---

## Open ports (admin services — hardened)

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
| `10.200.8.5` | Ethernet0 (LAN) |
| `10.147.18.192` | Ethernet 2 (ZeroTier) |
| `100.94.5.108` | Tailscale |

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
