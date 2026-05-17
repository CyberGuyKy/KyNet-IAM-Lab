# ============================================
# KyNet.local - User Creation Script
# Author: Kyle Hughes
# Description: Bulk creates department users
#              across all KyNet OUs
# ============================================

$domain = "DC=KyNet,DC=local"
$password = ConvertTo-SecureString "KyNet@User2024!" -AsPlainText -Force

# --- HR Department ---
$hrUsers = @(
    @{Name="Sarah Mitchell"; Username="s.mitchell"; Title="HR Manager"},
    @{Name="James Carter";   Username="j.carter";   Title="HR Specialist"},
    @{Name="Linda Torres";   Username="l.torres";   Title="HR Coordinator"}
)
foreach ($user in $hrUsers) {
    New-ADUser `
        -Name $user.Name `
        -SamAccountName $user.Username `
        -UserPrincipalName "$($user.Username)@KyNet.local" `
        -Path "OU=HR,OU=KyNet_Users,$domain" `
        -Title $user.Title `
        -Department "HR" `
        -AccountPassword $password `
        -Enabled $true
    Write-Host "Created: $($user.Name)" -ForegroundColor Green
}

# --- Finance Department ---
$financeUsers = @(
    @{Name="Robert Chen";    Username="r.chen";    Title="Finance Manager"},
    @{Name="Amanda Price";   Username="a.price";   Title="Financial Analyst"},
    @{Name="David Nguyen";   Username="d.nguyen";  Title="Accountant"}
)
foreach ($user in $financeUsers) {
    New-ADUser `
        -Name $user.Name `
        -SamAccountName $user.Username `
        -UserPrincipalName "$($user.Username)@KyNet.local" `
        -Path "OU=Finance,OU=KyNet_Users,$domain" `
        -Title $user.Title `
        -Department "Finance" `
        -AccountPassword $password `
        -Enabled $true
    Write-Host "Created: $($user.Name)" -ForegroundColor Green
}

# --- Engineering Department ---
$engUsers = @(
    @{Name="Marcus Johnson"; Username="m.johnson"; Title="Lead Engineer"},
    @{Name="Priya Patel";    Username="p.patel";   Title="Systems Engineer"},
    @{Name="Tyler Brooks";   Username="t.brooks";  Title="Junior Developer"}
)
foreach ($user in $engUsers) {
    New-ADUser `
        -Name $user.Name `
        -SamAccountName $user.Username `
        -UserPrincipalName "$($user.Username)@KyNet.local" `
        -Path "OU=Engineering,OU=KyNet_Users,$domain" `
        -Title $user.Title `
        -Department "Engineering" `
        -AccountPassword $password `
        -Enabled $true
    Write-Host "Created: $($user.Name)" -ForegroundColor Green
}

# --- IT Admin Department ---
$itUsers = @(
    @{Name="Kyle Admin";     Username="kyle.admin";  Title="IT Administrator"},
    @{Name="Rachel Stone";   Username="r.stone";     Title="Systems Administrator"},
    @{Name="Omar Hassan";    Username="o.hassan";    Title="Security Analyst"}
)
foreach ($user in $itUsers) {
    New-ADUser `
        -Name $user.Name `
        -SamAccountName $user.Username `
        -UserPrincipalName "$($user.Username)@KyNet.local" `
        -Path "OU=IT_Admin,OU=KyNet_Users,$domain" `
        -Title $user.Title `
        -Department "IT_Admin" `
        -AccountPassword $password `
        -Enabled $true
    Write-Host "Created: $($user.Name)" -ForegroundColor Green
}

Write-Host "`nAll users created successfully." -ForegroundColor Cyan
