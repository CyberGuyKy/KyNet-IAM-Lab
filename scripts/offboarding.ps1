# ============================================
# KyNet.local - User Offboarding Script
# Author: Kyle Hughes
# Description: Complete user offboarding workflow
#              Disable, strip access, document
# ============================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

$leavingUser = $Username
$date = Get-Date -Format "yyyy-MM-dd"

Write-Host "`nStarting offboarding for: $leavingUser" -ForegroundColor Yellow

# Step 1 - Verify user exists
try {
    $user = Get-ADUser -Identity $leavingUser -Properties *
    Write-Host "User found: $($user.Name)" -ForegroundColor Green
} catch {
    Write-Host "User not found: $leavingUser" -ForegroundColor Red
    exit
}

# Step 2 - Disable the account immediately
Disable-ADAccount -Identity $leavingUser
Write-Host "Step 1: Account disabled" -ForegroundColor Green

# Step 3 - Reset password to prevent unauthorized access
$randomPassword = ConvertTo-SecureString ([System.Web.Security.Membership]::GeneratePassword(16,4)) -AsPlainText -Force
Set-ADAccountPassword -Identity $leavingUser -Reset -NewPassword $randomPassword
Write-Host "Step 2: Password reset" -ForegroundColor Green

# Step 4 - Remove from all groups except Domain Users
$groups = Get-ADPrincipalGroupMembership -Identity $leavingUser |
    Where-Object {$_.Name -ne "Domain Users"}
foreach ($group in $groups) {
    Remove-ADGroupMember -Identity $group -Members $leavingUser -Confirm:$false
    Write-Host "  Removed from: $($group.Name)" -ForegroundColor Yellow
}
Write-Host "Step 3: Group memberships removed" -ForegroundColor Green

# Step 5 - Move to disabled OU
Move-ADObject -Identity $user.DistinguishedName `
    -TargetPath "OU=KyNet_Admins,DC=KyNet,DC=local"
Write-Host "Step 4: Account moved to disabled OU" -ForegroundColor Green

# Step 6 - Add offboarding description
Set-ADUser -Identity $leavingUser `
    -Description "DISABLED - Offboarded $date - Pending deletion after 90-day retention"
Write-Host "Step 5: Description updated with offboarding date" -ForegroundColor Green

Write-Host "`nOffboarding complete for $($user.Name)" -ForegroundColor Cyan
Write-Host "Account will be eligible for deletion after: $((Get-Date).AddDays(90).ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
