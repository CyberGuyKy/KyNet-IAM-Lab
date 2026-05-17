# KyNet IAM Lab — Enterprise Identity & Access Management Home Lab

**Built by Kyle Hughes | CompTIA Security+ | IAM Analyst**

---

## Overview

KyNet is a fully functional enterprise Identity and Access Management lab built from scratch in VirtualBox, simulating a real-world hybrid identity environment. This project demonstrates hands-on proficiency with the tools, protocols, and workflows used by IAM professionals in production environments — from on-premises Active Directory administration to cloud identity federation with Microsoft Entra ID.

The lab simulates a fictional four-department organization called **KyNet Corporation**, with realistic user provisioning, role-based access control, group policy enforcement, federated identity, MFA, and security monitoring — all built and documented end to end.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     KyNet Home Lab                          │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │   DC-01      │     │   MS01       │                     │
│  │ Windows      │     │ Windows      │                     │
│  │ Server 2022  │     │ Server 2022  │                     │
│  │              │     │              │                     │
│  │ • Active     │     │ • Dept File  │                     │
│  │   Directory  │     │   Shares     │                     │
│  │ • DNS        │     │ • NTFS RBAC  │                     │
│  │ • GPO        │     │ • Wazuh      │                     │
│  │ • Wazuh      │     │   Agent      │                     │
│  │   Agent      │     └──────────────┘                     │
│  └──────────────┘                                           │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │   UB01       │     │   WS01       │                     │
│  │ Ubuntu       │     │ Windows 11   │                     │
│  │ Server 24.04 │     │ Pro          │                     │
│  │              │     │              │                     │
│  │ • Keycloak   │     │ • Domain     │                     │
│  │   SSO/MFA    │     │   Workstation│                     │
│  │ • Wazuh SIEM │     │ • End-user   │                     │
│  │              │     │   Testing    │                     │
│  └──────────────┘     └──────────────┘                     │
│                                                             │
│         All VMs on internal Host-Only network               │
│              192.168.56.0/24                                │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Microsoft Entra Cloud Sync
                          │ (Hybrid Identity Phase)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Microsoft Entra ID (Cloud)                     │
│                                                             │
│  • Entra ID Free Tenant                                     │
│  • Cloud Sync Agent registered                             │
│  • Hybrid identity configuration                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Technologies Used

| Category | Technology |
|---|---|
| Virtualization | VirtualBox 7.x |
| Directory Services | Active Directory Domain Services (AD DS) |
| Cloud Identity | Microsoft Entra ID (Azure AD) |
| Hybrid Sync | Microsoft Entra Cloud Sync |
| Identity Provider | Keycloak 26.6.1 |
| SIEM | Wazuh 4.14.5 |
| Scripting | PowerShell, Bash |
| OS Platforms | Windows Server 2022, Windows 11, Ubuntu Server 24.04 |
| Protocols | LDAP, OIDC, SAML, TOTP, Kerberos, SMB |
| MFA | Microsoft Authenticator (TOTP) |

---

## Phase 1 — On-Premises IAM Environment

### 1.1 Active Directory Foundation

Built a complete Active Directory domain (`KyNet.local`) on Windows Server 2022 with a structured Organizational Unit hierarchy mirroring a real enterprise:

```
KyNet.local
├── KyNet_Users
│   ├── HR
│   ├── Finance
│   ├── Engineering
│   └── IT_Admin
├── KyNet_Groups
├── KyNet_Computers
└── KyNet_Admins
```

### 1.2 User Provisioning via PowerShell Automation

Provisioned 12 users across 4 departments using PowerShell automation — demonstrating IAM lifecycle management at scale:

```powershell
New-ADUser `
    -Name $user.Name `
    -SamAccountName $user.Username `
    -UserPrincipalName "$($user.Username)@KyNet.local" `
    -Path "OU=HR,OU=KyNet_Users,DC=KyNet,DC=local" `
    -Department "HR" `
    -AccountPassword $password `
    -Enabled $true
```

| Department | Users | Group |
|---|---|---|
| HR | Sarah Mitchell, James Carter, Linda Torres | GRP_HR |
| Finance | Robert Chen, Amanda Price, David Nguyen | GRP_Finance |
| Engineering | Marcus Johnson, Priya Patel, Tyler Brooks | GRP_Engineering |
| IT Admin | Kyle Admin, Rachel Stone, Omar Hassan | GRP_IT_Admin |

All users also members of GRP_AllStaff.

### 1.3 Role-Based Access Control (RBAC)

Configured department file shares on MS01 with NTFS permissions enforcing least privilege by security group membership:

| Share | Authorized Group | Permission |
|---|---|---|
| \\MS01\HR | GRP_HR | Read |
| \\MS01\Finance | GRP_Finance | Read |
| \\MS01\Engineering | GRP_Engineering | Read |
| \\MS01\AllStaff | GRP_AllStaff | Read |
| All shares | GRP_IT_Admin | Full Control |

**RBAC Verified:** Logged in as users from each department and confirmed access controls held — Finance users denied HR share, Engineering users denied Finance share, IT Admin accessed all shares.

### 1.4 Group Policy Objects (GPO)

Created and applied department-specific Group Policy Objects:

| GPO | Applied To | Settings |
|---|---|---|
| KyNet - Login Banner | Domain-wide | Legal warning on all logins |
| KyNet - Finance Security | Finance OU | Screen lock 2 min, USB block |
| KyNet - HR Security | HR OU | Control Panel restricted |
| KyNet - Engineering | Engineering OU | PowerShell execution allowed |
| Default Domain Policy | All users | 12-char min password, 90-day expiry, lockout after 5 attempts |

GPOs verified with `gpresult /r` confirming correct policies following users across workstations.

### 1.5 Help Desk Skills Demonstrated

Demonstrated core AD help desk workflows via both GUI (ADUC/ADAC) and PowerShell:

- Password resets — single user and bulk by group/OU
- Account lockout and unlock
- Enable/disable accounts
- Group membership management
- User onboarding and offboarding automation
- Inactive account reporting
- Account attribute management

---

## Phase 2 — Federated Identity with Keycloak

### 2.1 Keycloak Deployment

Deployed Keycloak 26.6.1 on Ubuntu Server 24.04 as a centralized Identity Provider:

- Installed Java 21 and Keycloak via CLI
- Configured as a systemd service with dedicated service account
- Configured for HTTP on port 8080 with `http-host=0.0.0.0`

### 2.2 LDAP Federation

Connected Keycloak to Active Directory via LDAP federation:

- Configured LDAP provider pointing to DC-01 (`ldap://192.168.56.10`)
- Set search scope to **Subtree** to capture all department sub-OUs
- Configured attribute mappers for email, surname, and department
- Synced all 12 KyNet AD users into the Keycloak KyNet realm

### 2.3 MFA with Microsoft Authenticator

Configured TOTP-based MFA enforced for all users:

- Created custom authentication flow requiring password + OTP
- Applied Configure OTP as required action to all 12 users via kcadm.sh
- Enrolled and tested Microsoft Authenticator end-to-end
- Verified complete authentication flow: AD credentials → Keycloak → TOTP → Access

---

## Phase 3 — SIEM with Wazuh

### 3.1 Wazuh Deployment

Deployed Wazuh 4.14.5 on UB01 using the automated quickstart installer. Troubleshot and resolved a locale initialization issue affecting OpenSearch/Java startup.

### 3.2 Agent Deployment

Deployed Wazuh agents on all three Windows VMs:

| Agent | IP | OS | Status |
|---|---|---|---|
| DC-01 | 192.168.56.10 | Windows Server 2022 | Active |
| MS01 | 192.168.56.20 | Windows Server 2022 | Active |
| WS01 | 192.168.56.30 | Windows 11 | Active |

### 3.3 Security Events Detected

Demonstrated real security event detection across the environment:

**Failed Login Attempts**
- Simulated 5 failed logins for s.mitchell on WS01
- Wazuh captured all 5 events with Event ID 4625
- Account lockout (Event ID 4740) correctly logged on DC-01

**Privileged Group Modification**
- Added s.mitchell to Domain Admins group
- Wazuh immediately detected Event ID 4728 — high severity alert
- Removed user and confirmed cleanup event logged

**File Integrity Monitoring**
- Configured Wazuh to monitor C:\KyNetShares on MS01
- Created, modified, and deleted a test file
- All three events detected in real time:
  - Rule 554 — File added (severity 5)
  - Rule 550 — Integrity checksum changed (severity 7)
  - Rule 553 — File deleted (severity 7)

---

## Phase 4 — Hybrid Identity with Microsoft Entra ID

### 4.1 Entra ID Tenant

Created a Microsoft Entra ID tenant and configured a native Global Administrator account for hybrid identity management.

### 4.2 Microsoft Entra Cloud Sync

Configured Microsoft Entra Cloud Sync to bridge on-premises KyNet.local with Entra ID:

- Installed provisioning agent on DC-01
- Configured AD to Entra ID sync
- Set scoping filter to `OU=KyNet_Users,DC=KyNet,DC=local`
- Enabled password hash sync
- Agent registered and showing Active in Entra portal

**Note on sync completion:** The provisioning agent encountered an ISP-level network restriction blocking `servicebus.windows.net` (Azure Service Bus) — a required endpoint for the agent's persistent cloud communication channel. The issue was systematically diagnosed through:

- VirtualBox NAT vs bridged networking comparison
- Endpoint connectivity testing (`Test-NetConnection`) across multiple network paths
- Agent log analysis identifying the specific failure mode
- ISP-level block confirmed by testing from both home network and mobile hotspot

This represents a realistic enterprise scenario where network infrastructure constraints affect hybrid identity deployments, and mirrors the type of troubleshooting IAM engineers perform in production environments.

---

## Key IAM Concepts Demonstrated

| Concept | Implementation |
|---|---|
| Identity Lifecycle Management | PowerShell provisioning, onboarding/offboarding automation |
| Least Privilege | NTFS RBAC by department group, verified with real user testing |
| Separation of Duties | Dedicated admin accounts, PAW simulation |
| Federation | Keycloak LDAP federation to Active Directory |
| Single Sign-On | Keycloak OIDC client configuration |
| Multi-Factor Authentication | TOTP via Microsoft Authenticator |
| Privileged Access | Domain Admin group monitoring, IT_Admin OU separation |
| Security Monitoring | Wazuh SIEM with FIM, auth monitoring, privilege escalation detection |
| Hybrid Identity | Entra Cloud Sync configuration and agent deployment |
| Compliance Controls | Login banners, password policies, account lockout, audit logging |
| Automation | PowerShell bulk user management, group assignments, reporting |

---

## PowerShell Scripts

All scripts used in this lab are available in the `/scripts` directory:

| Script | Description |
|---|---|
| `user-creation.ps1` | Bulk creates 12 users across 4 department OUs |
| `group-creation.ps1` | Creates 5 security groups in KyNet_Groups OU |
| `group-membership.ps1` | Assigns users to department groups and GRP_AllStaff |
| `rbac-permissions.ps1` | Sets NTFS permissions on department file shares |
| `password-reset-bulk.ps1` | Resets passwords for all users in a group or OU |
| `offboarding.ps1` | Complete user offboarding — disable, remove groups, move, document |
| `inactive-accounts.ps1` | Reports users with no logon activity in 30+ days |

---

## Troubleshooting Log

A detailed log of issues encountered and resolved during the build is documented in `/docs/troubleshooting-log.md`. Key issues include:

- IT_Admin OU typo (`IT_Admim`) causing user creation failures
- Keycloak LDAP sync returning 0 users (Search Scope set to One Level vs Subtree)
- Keycloak realm created with trailing space causing `%20` in all URLs — full rebuild required
- Wazuh indexer failing due to locale not initialized on Ubuntu Server minimal install
- MS01 network adapters in wrong order causing internet connectivity failures
- Entra Cloud Sync agent timeout due to ISP-level Service Bus endpoint restriction

---

## Lab Environment Specifications

| VM | OS | RAM | Storage | Role |
|---|---|---|---|---|
| DC-01 | Windows Server 2022 | 2GB | 60GB | Domain Controller, DNS |
| MS01 | Windows Server 2022 | 2GB | 60GB | Member Server, File Shares |
| UB01 | Ubuntu Server 24.04 LTS | 6GB | 50GB | Keycloak, Wazuh SIEM |
| WS01 | Windows 11 Pro | 2GB | 50GB | End-user Workstation |
| **Host** | Windows 11 | 16GB | — | VirtualBox Host |

---

## Certifications & Education

- **CompTIA Security+** — Active
- **Bachelor of Science, Cybersecurity** — Bellevue University (In Progress)
- **Honor Society Member**
- Pursuing: SC-300 (Microsoft Identity and Access Administrator)

---

## About This Project

This lab was built entirely from scratch over multiple weeks as a self-directed portfolio project to demonstrate practical IAM engineering skills. Every component was configured manually, every issue was diagnosed and resolved through systematic troubleshooting, and every concept was implemented with real tools on real infrastructure.

The goal was not just to make things work — but to understand *why* they work, document the process honestly including failures and fixes, and demonstrate the problem-solving mindset that IAM roles require.

---

*Built with curiosity, persistence, and too many PowerShell sessions. 💻🔐*
