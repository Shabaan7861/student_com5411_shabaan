#Requires -Modules PSDesiredStateConfiguration

# barmbuzz build - com5411 referral
# shabaan

Configuration StudentBaseline {

    param (
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$ConfigurationData
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName GPRegistryPolicyDsc

    # lab passwords - dont change these or it breaks
    $AdminCred = New-Object System.Management.Automation.PSCredential(
        'Administrator',
        (ConvertTo-SecureString ($ConfigurationData.AllNodes | Where-Object NodeName -eq 'localhost' | Select-Object -ExpandProperty SafeModePassword) -AsPlainText -Force)
    )
    $UserPass = ConvertTo-SecureString 'notlob2k26' -AsPlainText -Force

    $LocalNode = $ConfigurationData.AllNodes | Where-Object NodeName -eq 'localhost' | Select-Object -First 1
    if (-not $LocalNode) { throw 'ConfigurationData must include NodeName = "localhost".' }

    $DomainName  = $LocalNode.DomainName
    $DomainNetBios = $LocalNode.DomainNetbios

    Node $LocalNode.NodeName {

        # putting AD DS on so the server can act as a domain controller
        WindowsFeature ADDomainServices {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature DNSServer {
            Name      = 'DNS'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDomainServices'
        }

        # rsat so i can run things like Get-ADUser from the terminal
        WindowsFeature RSATADTools {
            Name      = 'RSAT-AD-Tools'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDomainServices'
        }

        WindowsFeature GPMCFeature {
            Name      = 'GPMC'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDomainServices'
        }

        # sets up barmbuzz.corp as the domain and makes this server the DC
        ADDomain BarmBuzzCorp {
            DomainName                    = $DomainName
            DomainNetBiosName             = $DomainNetBios
            Credential                    = $AdminCred
            SafemodeAdministratorPassword = $AdminCred
            DependsOn                     = '[WindowsFeature]ADDomainServices'
        }

        # this waits for AD to fully load before doing anything else
        # without it the OU creation was just failing straight away
        WaitForADDomain WaitForDomain {
            DomainName = $DomainName
            DependsOn  = '[ADDomain]BarmBuzzCorp'
        }

        # OUs

        ADOrganizationalUnit OU_Bolton {
            Name      = 'Bolton'
            Path      = 'DC=barmbuzz,DC=corp'
            Ensure    = 'Present'
            ProtectedFromAccidentalDeletion = $true
            DependsOn = '[WaitForADDomain]WaitForDomain'
        }

        ADOrganizationalUnit OU_Derby {
            Name      = 'Derby'
            Path      = 'DC=barmbuzz,DC=corp'
            Ensure    = 'Present'
            ProtectedFromAccidentalDeletion = $true
            DependsOn = '[WaitForADDomain]WaitForDomain'
        }

        # nottingham sits inside derby not at domain level
        ADOrganizationalUnit OU_Nottingham {
            Name      = 'Nottingham'
            Path      = 'OU=Derby,DC=barmbuzz,DC=corp'
            Ensure    = 'Present'
            ProtectedFromAccidentalDeletion = $true
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }

        # groups

        ADGroup BoltonUsers {
            GroupName        = 'Bolton-Users'
            GroupScope       = 'Global'
            Category         = 'Security'
            Path             = 'OU=Bolton,DC=barmbuzz,DC=corp'
            Ensure           = 'Present'
            Description      = 'bolton workers'
            MembersToInclude = @('Asia.Muhammed')
            DependsOn        = '[ADOrganizationalUnit]OU_Bolton'
        }

        ADGroup DerbyUsers {
            GroupName        = 'Derby-Users'
            GroupScope       = 'Global'
            Category         = 'Security'
            Path             = 'OU=Derby,DC=barmbuzz,DC=corp'
            Ensure           = 'Present'
            Description      = 'derby and nottingham workers'
            MembersToInclude = @('Aria.Hussian', 'Amira.Perez')
            DependsOn        = '[ADOrganizationalUnit]OU_Derby'
        }

        # users

        ADUser asia_muhammed {
            UserName             = 'Asia.Muhammed'
            GivenName            = 'Asia'
            Surname              = 'Muhammed'
            DisplayName          = 'Asia Muhammed'
            UserPrincipalName    = 'Asia.Muhammed@barmbuzz.corp'
            Path                 = 'OU=Bolton,DC=barmbuzz,DC=corp'
            Password             = (New-Object System.Management.Automation.PSCredential('dummy', $UserPass))
            Ensure               = 'Present'
            PasswordNeverExpires = $true
            Enabled              = $true
            DependsOn            = '[ADOrganizationalUnit]OU_Bolton'
        }

        ADUser aria_hussian {
            UserName             = 'Aria.Hussian'
            GivenName            = 'Aria'
            Surname              = 'Hussian'
            DisplayName          = 'Aria Hussian'
            UserPrincipalName    = 'Aria.Hussian@barmbuzz.corp'
            Path                 = 'OU=Derby,DC=barmbuzz,DC=corp'
            Password             = (New-Object System.Management.Automation.PSCredential('dummy', $UserPass))
            Ensure               = 'Present'
            PasswordNeverExpires = $true
            Enabled              = $true
            DependsOn            = '[ADOrganizationalUnit]OU_Derby'
        }

        ADUser amira_perez {
            UserName             = 'Amira.Perez'
            GivenName            = 'Amira'
            Surname              = 'Perez'
            DisplayName          = 'Amira Perez'
            UserPrincipalName    = 'Amira.Perez@barmbuzz.corp'
            Path                 = 'OU=Nottingham,OU=Derby,DC=barmbuzz,DC=corp'
            Password             = (New-Object System.Management.Automation.PSCredential('dummy', $UserPass))
            Ensure               = 'Present'
            PasswordNeverExpires = $true
            Enabled              = $true
            DependsOn            = '[ADOrganizationalUnit]OU_Nottingham'
        }

    }
}


# this runs after the dsc build to create the gpo and save all the evidence
function Run-PostBuild {
    param(
        [string]$EvidenceRoot = ".\Evidence"
    )

    New-Item -ItemType Directory -Path "$EvidenceRoot\GPO" -Force | Out-Null
    New-Item -ItemType Directory -Path "$EvidenceRoot\Health" -Force | Out-Null
    New-Item -ItemType Directory -Path "$EvidenceRoot\Validation" -Force | Out-Null

    $gponame = 'BarmBuzz-Lockdown'

    if (-not (Get-GPO -Name $gponame -ErrorAction SilentlyContinue)) {
        New-GPO -Name $gponame -Comment 'locks screen after 10 mins, stops people getting into unattended machines' | Out-Null
        Write-Host "gpo created" -ForegroundColor Green
    } else {
        Write-Host "gpo already exists, skipping" -ForegroundColor Gray
    }

    # these 3 registry values are what actually makes the screen lock kick in
    Set-GPRegistryValue -Name $gponame `
        -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
        -ValueName 'ScreenSaveTimeOut' -Type String -Value '600'

    Set-GPRegistryValue -Name $gponame `
        -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
        -ValueName 'ScreenSaveActive' -Type String -Value '1'

    Set-GPRegistryValue -Name $gponame `
        -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
        -ValueName 'ScreenSaverIsSecure' -Type String -Value '1'

    # linking to bolton OU only, brief says not to link at domain level
    try {
        New-GPLink -Name $gponame -Target 'OU=Bolton,DC=barmbuzz,DC=corp' -LinkEnabled Yes -ErrorAction Stop
        Write-Host "gpo linked to bolton" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like '*already*') {
            Write-Host "already linked" -ForegroundColor Gray
        } else {
            Write-Warning $_.Exception.Message
        }
    }

    # saving evidence
    dcdiag /q | Out-File "$EvidenceRoot\Health\dcdiag.txt" -Encoding UTF8
    Get-Service -Name 'ADWS','DNS','Netlogon','KDC' | Select-Object Name,Status | Out-File "$EvidenceRoot\Health\services.txt" -Encoding UTF8
    Resolve-DnsName barmbuzz.corp -ErrorAction SilentlyContinue | Out-File "$EvidenceRoot\Health\dns_lookup.txt" -Encoding UTF8
    Get-ADDomain | Select-Object DNSRoot,DomainMode,Forest | Out-File "$EvidenceRoot\Health\addomain.txt" -Encoding UTF8
    Get-ADDomainController -Filter * | Select-Object HostName,Domain,IsGlobalCatalog | Out-File "$EvidenceRoot\Health\addc.txt" -Encoding UTF8
    Get-ADOrganizationalUnit -Filter * | Select-Object Name,DistinguishedName | Out-File "$EvidenceRoot\Health\ous.txt" -Encoding UTF8
    Get-ADUser -Filter * | Select-Object Name,UserPrincipalName,Enabled | Out-File "$EvidenceRoot\Health\users.txt" -Encoding UTF8
    Get-ADGroup -Filter * | Select-Object Name,GroupScope,GroupCategory | Out-File "$EvidenceRoot\Health\groups.txt" -Encoding UTF8
    Get-ADGroupMember 'Bolton-Users' | Select-Object Name,ObjectClass | Out-File "$EvidenceRoot\Health\bolton_members.txt" -Encoding UTF8
    Get-ADGroupMember 'Derby-Users' | Select-Object Name,ObjectClass | Out-File "$EvidenceRoot\Health\derby_members.txt" -Encoding UTF8
    Get-GPO -All | Select-Object DisplayName,GpoStatus,CreationTime | Out-File "$EvidenceRoot\GPO\gpo_list.txt" -Encoding UTF8
    Get-GPInheritance -Target 'OU=Bolton,DC=barmbuzz,DC=corp' | Out-File "$EvidenceRoot\GPO\bolton_gpo_inheritance.txt" -Encoding UTF8
    gpresult /r | Out-File "$EvidenceRoot\GPO\gpresult.txt" -Encoding UTF8

    Write-Host "done" -ForegroundColor Green
}
