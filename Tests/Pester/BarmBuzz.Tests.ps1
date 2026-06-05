# pester tests for the barmbuzz build
# run: Invoke-Pester .\Tests\Pester\BarmBuzz.Tests.ps1 -Output Detailed

Describe 'Domain Health Checker' {

    It 'barmbuzz.corp is up' {
        $d = Get-ADDomain -ErrorAction Stop
        $d.DNSRoot | Should -Be 'barmbuzz.corp'
    }

    It 'dns is resolving' {
        $r = Resolve-DnsName 'barmbuzz.corp' -ErrorAction Stop
        $r | Should -Not -BeNullOrEmpty
    }

    It 'ADWS is running' {
        (Get-Service -Name 'ADWS').Status | Should -Be 'Running'
    }

    It 'netlogon is running' {
        (Get-Service -Name 'Netlogon').Status | Should -Be 'Running'
    }

    It 'dns service is running' {
        (Get-Service -Name 'DNS').Status | Should -Be 'Running'
    }
}

Describe 'OU structure' {

    It 'bolton OU is there' {
        (Get-ADOrganizationalUnit -Filter "Name -eq 'Bolton'") | Should -Not -BeNullOrEmpty
    }

    It 'derby OU is there' {
        (Get-ADOrganizationalUnit -Filter "Name -eq 'Derby'") | Should -Not -BeNullOrEmpty
    }

    It 'nottingham is inside derby' {
        $ou = Get-ADOrganizationalUnit -Filter "Name -eq 'Nottingham'"
        $ou | Should -Not -BeNullOrEmpty
        $ou.DistinguishedName | Should -Match 'OU=Derby'
    }
}

Describe 'Active Directory Users and Groups' {

    It 'asia.muhammed is there and enabled' {
        $u = Get-ADUser -Identity 'Asia.Muhammed' -ErrorAction Stop
        $u.Enabled | Should -Be $true
    }

    It 'aria.hussian is there and enabled' {
        $u = Get-ADUser -Identity 'Aria.Hussian' -ErrorAction Stop
        $u.Enabled | Should -Be $true
    }

    It 'amira.perez is there and enabled' {
        $u = Get-ADUser -Identity 'Amira.Perez' -ErrorAction Stop
        $u.Enabled | Should -Be $true
    }

    It 'bolton-users is a security group' {
        $g = Get-ADGroup -Identity 'Bolton-Users' -ErrorAction Stop
        $g.GroupCategory | Should -Be 'Security'
    }

    It 'derby-users is a security group' {
        $g = Get-ADGroup -Identity 'Derby-Users' -ErrorAction Stop
        $g.GroupCategory | Should -Be 'Security'
    }

    It 'bolton-users has asia in it' {
        $members = Get-ADGroupMember -Identity 'Bolton-Users' | Select-Object -ExpandProperty SamAccountName
        $members | Should -Contain 'Asia.Muhammed'
    }

    It 'derby-users has aria and amira in it' {
        $members = Get-ADGroupMember -Identity 'Derby-Users' | Select-Object -ExpandProperty SamAccountName
        $members | Should -Contain 'Aria.Hussian'
        $members | Should -Contain 'Amira.Perez'
    }
}

Describe 'Group Policy' {

    It 'BarmBuzz-Lockdown GPO exists' {
        $gpo = Get-GPO -Name 'BarmBuzz-Lockdown' -ErrorAction Stop
        $gpo | Should -Not -BeNullOrEmpty
    }

    It 'lockdown gpo is linked to bolton' {
        $inh = Get-GPInheritance -Target 'OU=Bolton,DC=barmbuzz,DC=corp'
        $link = $inh.GpoLinks | Where-Object { $_.DisplayName -eq 'BarmBuzz-Lockdown' }
        $link | Should -Not -BeNullOrEmpty
    }
}
