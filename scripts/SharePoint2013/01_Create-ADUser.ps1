<#
.SYNOPSIS
	Create Active Directory User

.DESCRIPTION
	Initial deployment administrative and service accounts in SharePoint 2013

.LINK
	Technet article: http://technet.microsoft.com/en-us/library/ee662513.aspx
#>

$Metadata = @{
	Title = "Create Active Directory User"
	Filename = "Create-ADDefaultUser.ps1"
	Description = "Initial deployment administrative and service accounts in SharePoint 2013"
	Tags = "powershell, sharepoint, 2013, installation"
	Project = "SharePoint 2013 Install"
	Author = "Janik von Rotz"
	AuthorContact = "http://janikvonrotz.ch"
	CreateDate = "2013-05-22"
	LastEditDate = "2013-05-22"
	Version = "1.0.0"
	License = @'
This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}

#--------------------------------------------------#
# settings
#--------------------------------------------------#
$PathToXmlFile = Get-ChildItem -Path $PSconfigs.Path -Filter '*.install.config.xml' -Recurse
[xml]$Config = get-content $PathToXmlFile.FullName

#--------------------------------------------------#
# modules
#--------------------------------------------------#
Import-Module ActiveDirectory
Import-Module LocalAccounts

#--------------------------------------------------#
# main
#--------------------------------------------------#
$ADDefaultUser = $Config.Content.ADDefaultUser
$Global = $Config.Content.Global

$SPUsername = $Global.SPServer.Username
$SPPassword = Read-Host -Prompt "`nEnter password for $SPUsername" -AsSecureString
$SPCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SPUsername, $SPPassword
        
foreach($Account in $ADDefaultUser.Account){

    $samAccountName = $Global.Project.Prefix + "-" + $Account.samAccountName
        
    if($Account.scope -eq "Domain"){

        Write-Host "Adding new domain user: $samAccountName"
        
        New-ADUser  $samAccountName -DisplayName $Account.DisplayName -Enabled $true -path $ADDefaultUser.ParentContainer -AccountPassword (ConvertTo-SecureString -AsPlainText $Account.Password -Force) -ChangePasswordAtLogon $false
    
    }elseif($Account.scope -eq "Local"){
    
        Write-Host "Adding new local user: $samAccountName"
        
        New-LocalUser -Name $samAccountName -Fullname $Account.DisplayName -Password $Account.Password #-Source $Global.SPServer.Name -Credential $SPCredentials
    
    }
}