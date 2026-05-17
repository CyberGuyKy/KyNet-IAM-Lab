# KyNet Lab — Troubleshooting Log

This document records every significant issue encountered during the build and how it was resolved. Real IAM engineering involves systematic diagnosis and problem solving — this log demonstrates that process.

---

## Issue 1 — OU Typo Causing User Creation Failure

**Phase:** Active Directory Setup  
**Error:** `New-ADUser: Directory object not found`

**Root Cause:**  
The IT_Admin OU was created with a typo — `IT_Admim` (m instead of n). The user creation script couldn't find the path `OU=IT_Admin,OU=KyNet_Users,DC=KyNet,DC=local`.

**Diagnosis:**  
Ran `Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName` and spotted the typo in the output.

**Fix:**  
```powershell
Get-ADOrganizationalUnit -Filter {Name -eq "IT_Admim"} | Rename-ADObject -NewName "IT_Admin"
```

**Lesson:** Always verify OU structure before running bulk scripts. Use `Get-ADOrganizationalUnit` to confirm exact names.

---

## Issue 2 — Keycloak LDAP Sync Returning 0 Users

**Phase:** Keycloak LDAP Federation  
**Error:** "Sync of users finished successfully. 0 users added."

**Root Cause:**  
The Users DN was set to `OU=KyNet_Users,DC=KyNet,DC=local` but Search Scope was set to **One Level**, which only looks directly inside the OU — not into sub-OUs (HR, Finance, Engineering, IT_Admin).

**Fix:**  
Changed Search Scope from **One Level** to **Subtree** in the LDAP federation settings. This tells Keycloak to search the OU and all nested OUs beneath it.

**Result:** 12 users added on next sync.

---

## Issue 3 — Keycloak Realm Created With Trailing Space

**Phase:** Keycloak Configuration  
**Error:** Login URL showing `%20` — e.g., `http://192.168.56.40:8080/realms/KyNet%20/`

**Root Cause:**  
When creating the KyNet realm a trailing space was accidentally added, resulting in a realm named `KyNet ` instead of `KyNet`. Keycloak URL-encoded the space as `%20`.

**Attempted Fix:**  
Keycloak does not allow renaming realms after creation.

**Resolution:**  
Deleted the realm entirely and rebuilt from scratch — LDAP federation, mappers, client, and MFA flow all reconfigured. The rebuild took approximately 15 minutes.

**Lesson:** Keycloak realm names are permanent. Copy/paste rather than typing to avoid whitespace errors.

---

## Issue 4 — Wazuh Indexer Failing on Ubuntu Server

**Phase:** Wazuh SIEM Installation  
**Error:** `java.lang.InternalError: platform encoding not initialized`

**Root Cause:**  
Ubuntu Server minimal install doesn't configure system locale by default. The Wazuh indexer (OpenSearch) runs on Java and requires the system locale to be properly initialized before it can start.

**Fix:**  
```bash
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

**Additional Complication:**  
An attempt to add locale variables to the systemd service file corrupted the ExecStart path, causing a `status=203/EXEC` error. The binary `/usr/share/wazuh-indexer/bin/systemd-entrypoint` was missing entirely from the partial install.

**Resolution:**  
Fully removed the broken install and reinstalled cleanly:
```bash
sudo apt-get remove --purge wazuh-indexer -y
sudo rm -rf /usr/share/wazuh-indexer /etc/wazuh-indexer /var/lib/wazuh-indexer
sudo reboot
# Reinstall with locale now configured
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh && sudo bash ./wazuh-install.sh -a
```

---

## Issue 5 — MS01 Network Adapters in Wrong Order

**Phase:** Member Server Setup  
**Error:** No internet access on MS01, Wazuh agent couldn't download from packages.wazuh.com

**Root Cause:**  
During VM creation MS01's Adapter 1 was configured as Host-Only instead of NAT. When the static IP `192.168.56.20` was set, it went on the wrong adapter. After swapping adapters in VirtualBox the static IP conflicted with the new NAT adapter.

**Diagnosis Steps:**  
1. `Get-NetIPAddress` — confirmed both adapters showing 192.168.56.x addresses
2. VirtualBox settings review — confirmed Adapter 1 was Host-Only
3. Changed Adapter 1 to NAT in VirtualBox
4. Ran `Remove-NetIPAddress` and `Set-NetIPInterface -Dhcp Enabled` to fix the NAT adapter
5. Re-applied static IP to Ethernet 2 (Host-Only)

**Lesson:** Always verify VirtualBox adapter order before starting OS configuration. NAT should always be Adapter 1.

---

## Issue 6 — Entra Cloud Sync Agent Timeout

**Phase:** Hybrid Identity — Microsoft Entra Cloud Sync  
**Error:** `HybridIdentityServiceAgentTimeout`

**Root Cause:**  
The provisioning agent requires outbound connectivity to `servicebus.windows.net` for its persistent communication channel with Microsoft's cloud. This endpoint was blocked at the ISP level.

**Diagnosis Steps:**  
1. Verified agent service was Running: `Get-Service AADConnectProvisioningAgent`
2. Tested Microsoft endpoints: `Test-NetConnection -ComputerName "servicebus.windows.net" -Port 443` — **FAILED**
3. Switched DC-01 from NAT to Bridged Adapter — still failed
4. Tested from host machine directly — still failed
5. Tested from phone hotspot — still failed
6. Confirmed ISP-level block affecting both home network and mobile carrier

**Result:**  
Configuration is fully correct — agent registered, scoping filter configured, password hash sync enabled. The sync itself was blocked by a network-level restriction outside the lab environment.

**Documentation Value:**  
This demonstrates systematic network troubleshooting methodology — ruling out VM configuration, VirtualBox NAT, home router settings, and confirming ISP-level restriction through multiple test paths.

---

## Issue 7 — WS01 Domain Join Access Denied via PowerShell

**Phase:** Workstation Setup  
**Error:** `Add-Computer: Access is denied`

**Root Cause:**  
Unknown — credentials were correct and network was working. PowerShell domain join was consistently denied.

**Fix:**  
Used the GUI method instead:  
Start → System → Advanced System Settings → Computer Name → Change → Domain → `KyNet.local`

GUI domain join succeeded immediately with the same credentials.

**Lesson:** When PowerShell throws access denied for domain join with correct credentials, the GUI method bypasses whatever is causing the denial and is a valid alternative approach.
