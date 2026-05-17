# KyNet RBAC Access Matrix

This document defines the Role-Based Access Control model for KyNet Corporation's file share infrastructure.

## Principle of Least Privilege

Every user has access only to the resources required for their job function. No user has write access to shared resources by default. Only IT Admin has cross-departmental access.

---

## File Share Access Matrix

| User | HR Share | Finance Share | Engineering Share | AllStaff Share |
|---|---|---|---|---|
| s.mitchell (HR Manager) | ✅ Read | ❌ Denied | ❌ Denied | ✅ Read |
| j.carter (HR Specialist) | ✅ Read | ❌ Denied | ❌ Denied | ✅ Read |
| l.torres (HR Coordinator) | ✅ Read | ❌ Denied | ❌ Denied | ✅ Read |
| r.chen (Finance Manager) | ❌ Denied | ✅ Read | ❌ Denied | ✅ Read |
| a.price (Financial Analyst) | ❌ Denied | ✅ Read | ❌ Denied | ✅ Read |
| d.nguyen (Accountant) | ❌ Denied | ✅ Read | ❌ Denied | ✅ Read |
| m.johnson (Lead Engineer) | ❌ Denied | ❌ Denied | ✅ Read | ✅ Read |
| p.patel (Systems Engineer) | ❌ Denied | ❌ Denied | ✅ Read | ✅ Read |
| t.brooks (Junior Developer) | ❌ Denied | ❌ Denied | ✅ Read | ✅ Read |
| kyle.admin (IT Administrator) | ✅ Full Control | ✅ Full Control | ✅ Full Control | ✅ Full Control |
| r.stone (Systems Administrator) | ✅ Full Control | ✅ Full Control | ✅ Full Control | ✅ Full Control |
| o.hassan (Security Analyst) | ✅ Full Control | ✅ Full Control | ✅ Full Control | ✅ Full Control |

---

## Group Membership Matrix

| User | GRP_HR | GRP_Finance | GRP_Engineering | GRP_IT_Admin | GRP_AllStaff |
|---|---|---|---|---|---|
| s.mitchell | ✅ | — | — | — | ✅ |
| j.carter | ✅ | — | — | — | ✅ |
| l.torres | ✅ | — | — | — | ✅ |
| r.chen | — | ✅ | — | — | ✅ |
| a.price | — | ✅ | — | — | ✅ |
| d.nguyen | — | ✅ | — | — | ✅ |
| m.johnson | — | — | ✅ | — | ✅ |
| p.patel | — | — | ✅ | — | ✅ |
| t.brooks | — | — | ✅ | — | ✅ |
| kyle.admin | — | — | — | ✅ | ✅ |
| r.stone | — | — | — | ✅ | ✅ |
| o.hassan | — | — | — | ✅ | ✅ |

---

## NTFS Permission Implementation

Permissions are applied at two layers:

### Layer 1 — SMB Share Permissions
```
GRP_IT_Admin — Full Control
GRP_[Department] — Read
```

### Layer 2 — NTFS Permissions
```
BUILTIN\Administrators — Full Control
KYNET\Domain Admins — Full Control
KYNET\GRP_IT_Admin — Full Control
KYNET\GRP_[Department] — Read and Execute
NT AUTHORITY\SYSTEM — Full Control
```

Inheritance is disabled on all department folders. Permissions are explicitly defined — nothing is inherited from the parent `C:\KyNetShares` directory.

---

## Verification Testing

RBAC was verified by logging into WS01 as users from each department and testing access to all four shares:

**Test 1 — Sarah Mitchell (HR)**
- HR Share: ✅ HR_Policies.txt visible
- Finance Share: ❌ Access Denied
- Engineering Share: ❌ Access Denied
- AllStaff Share: ✅ Welcome.txt visible

**Test 2 — Marcus Johnson (Engineering)**
- HR Share: ❌ Access Denied
- Finance Share: ❌ Access Denied
- Engineering Share: ✅ System_Architecture.txt visible
- AllStaff Share: ✅ Welcome.txt visible

**Test 3 — Kyle Admin (IT Admin)**
- HR Share: ✅ Full Access
- Finance Share: ✅ Full Access
- Engineering Share: ✅ Full Access
- AllStaff Share: ✅ Full Access

All access controls confirmed working as designed.
