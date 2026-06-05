@{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true

            DomainName       = 'barmbuzz.corp'
            DomainNetbios    = 'BARMBUZZ'
            SafeModePassword = 'superw1n_user'

            OUs = @(
                @{ Name = 'Bolton';     Path = 'DC=barmbuzz,DC=corp' }
                @{ Name = 'Derby';      Path = 'DC=barmbuzz,DC=corp' }
                @{ Name = 'Nottingham'; Path = 'OU=Derby,DC=barmbuzz,DC=corp' }
            )

            Users = @(
                @{ Name = 'Asia.Muhammed'; GivenName = 'Asia';  Surname = 'Muhammed'; OU = 'OU=Bolton,DC=barmbuzz,DC=corp' }
                @{ Name = 'Aria.Hussian';  GivenName = 'Aria';  Surname = 'Hussian';  OU = 'OU=Derby,DC=barmbuzz,DC=corp' }
                @{ Name = 'Amira.Perez';   GivenName = 'Amira'; Surname = 'Perez';    OU = 'OU=Nottingham,OU=Derby,DC=barmbuzz,DC=corp' }
            )

            Groups = @(
                @{ Name = 'Bolton-Users'; OU = 'OU=Bolton,DC=barmbuzz,DC=corp'; Members = @('Asia.Muhammed') }
                @{ Name = 'Derby-Users';  OU = 'OU=Derby,DC=barmbuzz,DC=corp';  Members = @('Aria.Hussian','Amira.Perez') }
            )
        }
    )
}
