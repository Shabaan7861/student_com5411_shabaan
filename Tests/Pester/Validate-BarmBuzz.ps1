Describe "BarmBuzz AD Environment" {

    It "Domain exists" {
        (Get-ADDomain).DNSRoot | Should -Be "barnbuzz.local"
    }

    It "Bolton OU exists" {
        (Get-ADOrganizationalUnit -Filter {Name -eq "Bolton"}) | Should -Not -BeNullOrEmpty
    }

    It "Derby OU exists" {
        (Get-ADOrganizationalUnit -Filter {Name -eq "Derby"}) | Should -Not -BeNullOrEmpty
    }

    It "Nottingham OU exists" {
        (Get-ADOrganizationalUnit -Filter {Name -eq "Nottingham"}) | Should -Not -BeNullOrEmpty
    }

    It "Bolton-Users group exists" {
        (Get-ADGroup -Filter {Name -eq "Bolton-Users"}) | Should -Not -BeNullOrEmpty
    }

    It "Derby-Users group exists" {
        (Get-ADGroup -Filter {Name -eq "Derby-Users"}) | Should -Not -BeNullOrEmpty
    }

    It "Asia.Muhammed user exists" {
        (Get-ADUser -Filter {SamAccountName -eq "asia.muhammed"}) | Should -Not -BeNullOrEmpty
    }

    It "Aria.Hussian user exists" {
        (Get-ADUser -Filter {SamAccountName -eq "aria.hussian"}) | Should -Not -BeNullOrEmpty
    }

    It "Amira.Perez user exists" {
        (Get-ADUser -Filter {SamAccountName -eq "amira.perez"}) | Should -Not -BeNullOrEmpty
    }

    It "ScreenLockPolicy GPO exists" {
        (Get-GPO -Name "ScreenLockPolicy" -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}