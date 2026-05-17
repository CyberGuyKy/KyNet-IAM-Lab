# ============================================
# KyNet.local - Bulk Password Reset Script
# Author: Kyle Hughes
# Description: Reset passwords for all users
#              in a group, OU, or entire domain
# Usage: Run on DC-01 as Domain Administrator
# ============================================

# --- Option 1: Reset all users in a specific GROUP ---
function Reset-GroupPasswords {
    param(
        [string]$GroupName,
        [string]$TempPassword = "TempPass@2024!"
    )

    $securePassword = ConvertTo-SecureString $TempPassword -AsPlainText -Force

    Write-Host "Resetting passwords for members of: $GroupName" -ForegroundColor Yellow

    Get-ADGroupMember -Identity $GroupName | ForEach-Object {
        Set-ADAccountPassword -Identity $_.SamAccountName -Reset -NewPassword $securePassword
        Set-ADUser -Identity $_.SamAccountName -ChangePasswordAtLogon $true
        Write-Host "  Reset: $($_.Name)" -ForegroundColor Green
    }

    Write-Host "`nGroup password reset complete." -ForegroundColor Cyan
}

# --- Option 2: Reset all users in a specific OU ---
function Reset-OUPasswords {
    param(
        [string]$OUPath,
        [string]$TempPassword = "TempPass@2024!"
    )

    $securePassword = ConvertTo-SecureString $TempPassword -AsPlainText -Force

    Write-Host "Resetting passwords in OU: $OUPath" -ForegroundColor Yellow

    Get-ADUser -Filter * -SearchBase $OUPath | ForEach-Object {
        Set-ADAccountPassword -Identity $_.SamAccountName -Reset -NewPassword $securePassword
        Set-ADUser -Identity $_.SamAccountName -ChangePasswordAtLogon $true
        Write-Host "  Reset: $($_.Name)" -ForegroundColor Green
    }

    Write-Host "`nOU password reset complete." -ForegroundColor Cyan
}

# --- Option 3: Secure interactive reset (no plain text in script) ---
function Reset-SingleUserSecure {
    $username = Read-Host "Enter username"
    $newPassword = Read-Host "Enter new password" -AsSecureString
    Set-ADAccountPassword -Identity $username -Reset -NewPassword $newPassword
    Set-ADUser -Identity $username -ChangePasswordAtLogon $true
    Write-Host "Password reset complete for $username" -ForegroundColor Green
}

# --- Example usage ---
# Reset-GroupPasswords -GroupName "GRP_HR"
# Reset-OUPasswords -OUPath "OU=Finance,OU=KyNet_Users,DC=KyNet,DC=local"
# Reset-SingleUserSecure
