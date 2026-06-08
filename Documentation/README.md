# BarmBuzz AD Build — COM5411
**Shabaan Ali Nisar**

This repo is the PowerShell automation for building the BarmBuzz Active Directory lab. It turns a Windows Server 2025 VM into a domain controller for barnbuzz.local, creates the OUs, users, groups, one GPO and saves evidence files after the build.

what it does
The build creates the domain barnbuzz.local and installs AD DS and DNS. It creates Bolton, Derby and Nottingham OUs. It creates users and puts them into groups. It links the lock screen policy to Bolton only. It also saves evidence files so you can check that it worked.

software used
I used Windows Server 2025 and PowerShell 5.1 or newer. The DSC config uses PSDesiredStateConfiguration, ActiveDirectoryDsc version 6.6.0 and GPRegistryPolicyDsc version 1.3.1. Pester is used for validation and the server uses the AD and GPO cmdlets from RSAT.

how it works
Run_BuildMain.ps1 is the main script. It prepares the network, compiles the DSC configuration, applies it, creates the GPO and then saves the evidence. The main config is in StudentConfig.ps1 and the environment data is in AllNodes.psd1. There are helper scripts in Helpers and prereq scripts in Prereqs.

repo layout
Run_BuildMain.ps1 is the entry point
StudentConfig.ps1 contains the main DSC configuration
AllNodes.psd1 contains the build data
Scripts/Helpers has evidence collection helpers
Scripts/Prereqs has network and LCM setup
Tests/Pester has the validation tests
Evidence contains the output files

how to run it
You need Windows Server 2025, PowerShell 5.1 or newer and administrator rights. Clone the repo, change into the folder and run Run_BuildMain.ps1.

after the build
Check the domain with Get-ADDomain. Verify the OUs with Get-ADOrganizationalUnit. Check users with Get-ADUser and check the policy with Get-GPO and gpresult. Run the tests with Invoke-Pester .\Tests\Pester\BarmBuzz.Tests.ps1.

why one domain
Derby and Nottingham are OUs, not separate domains. That keeps the lab much simpler and avoids extra domain controllers and trust relationships. It still lets me apply different policies to different OUs.

references

Microsoft, 2024. Desired State Configuration (DSC) overview. Available at: https://learn.microsoft.com/en-us/powershell/scripting/dsc/overview [Accessed 8 June 2026].
Microsoft, 2024. Group Policy PowerShell cmdlets. Available at: https://learn.microsoft.com/en-us/powershell/module/grouppolicy/ [Accessed 8 June 2026].
Microsoft, 2024. Windows Server 2025 overview. Available at: https://learn.microsoft.com/en-us/windows-server/ [Accessed 8 June 2026].
TechTarget, 2023. What is Active Directory? Available at: https://www.techtarget.com/searchwindowsserver/definition/Active-Directory [Accessed 8 June 2026].
Petri.com, 2022. How to install Active Directory Domain Services on Windows Server. Available at: https://petri.com/install-active-directory-domain-services-windows-server/ [Accessed 8 June 2026].
PowerShell.org, 2024. DSC tag articles. Available at: https://powershell.org/tag/dsc/ [Accessed 8 June 2026].
Redgate, 2019. Using PowerShell and Group Policy. Available at: https://www.red-gate.com/simple-talk/sysadmin/powershell/using-powershell-and-group-policy/ [Accessed 8 June 2026].
YouTube, 2022. NetworkChuck, Active Directory in 10 minutes. Available at: https://www.youtube.com/watch?v=J7cEzIpg24Q [Accessed 8 June 2026].
Pester Team, 2024. Pester documentation. Available at: https://pester.dev [Accessed 8 June 2026].

