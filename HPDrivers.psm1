

function Get-HPDrivers {
    <#
    .SYNOPSIS
        Update all HP device drivers with a single command - Get-HPDrivers.

    .DESCRIPTION
        The HPDrivers module uses HP CMSL to download and install softpaqs that match the operating system version and hardware configuration.

    .PARAMETER NoPrompt
         Install all drivers and update BIOS

    .PARAMETER ShowSoftware
        Show additional HP software in the driver list

    .PARAMETER DeleteInstallationFiles
        Delete the HP SoftPaq installation files stored in C:\Temp

    .PARAMETER UninstallHPCMSL
         Uninstall HP CMSL at the end of installation process

    .PARAMETER SuspendBL
        Suspend BitLocker protection for one restart

    .LINK
        https://github.com/UsefulScripts01/HPDrivers

    .LINK
        https://www.powershellgallery.com/packages/HPDrivers

    .EXAMPLE
        Get-HPDrivers -NoPrompt
        Simple, just download and install all drivers.
    
    .EXAMPLE
        Get-HPDrivers -DeleteInstallationFiles -SuspendBL
        Show all available drivers and additional software. Do not keep installation files. Suspend BitLocker pin for next reboot.
    #>

    param(
        [Parameter(Mandatory = $false)] [switch]$NoPrompt,
        [Parameter(Mandatory = $false)] [switch]$ShowSoftware,
        [Parameter(Mandatory = $false)] [switch]$DeleteInstallationFiles,
        [Parameter(Mandatory = $false)] [switch]$UninstallHPCMSL,
        [Parameter(Mandatory = $false)] [switch]$SuspendBL
    )

    # if machine manufacturer is HP
    $Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    if (($Manufacturer -match "HP") -or ($Manufacturer -match "Hewlett-Packard")) {

        # install HPCMSL
        if (!(Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\HP.Softpaq\HP.Softpaq.psm1")) {
            Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.6.9.exe" -OutFile "C:\Temp\hpcmsl.exe"
            Start-Process -FilePath "C:\Temp\hpcmsl.exe" -Wait -ArgumentList "/VERYSILENT"
            Start-Sleep -Seconds 5
        }

        # create path
        $Model = (Get-CimInstance -ClassName win32_ComputerSystem).Model
        if (!(Test-Path -Path "C:\Temp\$Model")) {
            New-Item -ItemType Directory -Path "C:\Temp\$Model" -Force
        }
        Set-Location -Path "C:\Temp\$Model"

        # check available drivers
        if (!$NoPrompt) {
            if ($ShowSoftware) { $SpList = Get-SoftpaqList -Category BIOS, Diagnostic, Dock, Driver, Software, Utility | Select-Object -Property id, Name, Version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple } # all
            else { $SpList = Get-SoftpaqList -Category BIOS, Driver | Select-Object -Property id, Name, Version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple } # default
        }
        if ($NoPrompt) {
            if ($ShowSoftware) { $SpList = Get-SoftpaqList -Category BIOS, Diagnostic, Dock, Driver, Software, Utility } # all
            else { $SpList = Get-SoftpaqList -Category BIOS, Driver } # default
        }

        if ($SpList) {
            Write-Host "`nThe script will install the following drivers. Please wait..`n" -ForegroundColor White -BackgroundColor DarkGreen
            $SpList | Select-Object -Property id, Name, Version, Size, ReleaseDate | Format-Table -AutoSize
        }

        # download and install selected drivers
        foreach ($Number in $SpList.id) {
            try {
                Get-Softpaq -Number $Number -Action silentinstall
                $Info = Get-SoftpaqMetadata -Number $Number | Out-SoftpaqField -Field Title
                $Info += ' - INSTALLED'
                Write-Host $Info -ForegroundColor Green
            }
            catch {
                $Info = Get-SoftpaqMetadata -Number $Number | Out-SoftpaqField -Field Title
                $Info += ' - FAILED!'
                Write-Host $Info -ForegroundColor Red
            }
        }

        # remove installation files
        if ($DeleteInstallationFiles -and (Test-Path -Path "C:\Temp\$Model")) {
            Set-Location -Path $HOME
            Remove-Item -Path "C:\Temp\$Model" -Recurse -Force
        }

        # uninstall HP Client Management Script Library
        if ($UninstallHPCMSL -and ((Get-CimInstance -ClassName Win32_InstalledWin32Program).Name -contains 'HP Client Management Script Library')) {
            Start-Process -FilePath "C:\Program Files\WindowsPowerShell\HP.CMSL.UninstallerData\unins000.exe" -Wait -ArgumentList "/VERYSILENT"
        }

        # disable BitLocker pin for one restart (BIOS update)
        if ($SuspendBL -and ((Get-BitLockerVolume -MountPoint "C:").VolumeStatus -ne "FullyDecrypted")) {
            Suspend-BitLocker -MountPoint "C:" -RebootCount 1
        }
        Set-Location -Path $HOME
    }
}
Export-ModuleMember -Function Get-HPDrivers

# SIG # Begin signature block
# MIIFlAYJKoZIhvcNAQcCoIIFhTCCBYECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUy/+1XteWBoqWBQv4N9xPSNUD
# ogWgggMiMIIDHjCCAgagAwIBAgIQG4j6Fy1vN4RI51iOsN6jXzANBgkqhkiG9w0B
# AQsFADAnMSUwIwYDVQQDDBxQb3dlclNoZWxsIENvZGUgU2lnbmluZyBDZXJ0MB4X
# DTIzMDUxODEzMjYwNloXDTI0MDUxODEzNDYwNlowJzElMCMGA1UEAwwcUG93ZXJT
# aGVsbCBDb2RlIFNpZ25pbmcgQ2VydDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAKQChTghyjwpBN5/Uxk1PBfkuA2H31sDNny5h3O4HRcznu0RWuAS9RvP
# E9zD78ho7ETGofbO8ftUlIbQcXUqTc/XOePZNLkLbmpSKtjZY0IWgff7wtVr2GsO
# 4G7EnPIlGX7iYUFUttQZB2dKf55AaAQOG1/IpztXUn6weTqgHa5Ik/l6QZkTZVsW
# Eu6CWHeaxQiv46TDnS+fxIFCW6CxuMXMWpHTjI97deArxU4tjzNaZzx9VplIViee
# v3KmInT8+nGzms0NmOmbQ7qktB+dYLDIDVhv8vJ0OYjOzeQOSmWfSu6T9HCPAr3w
# 52q7g9N1bAeS+o8Fv/j+RPWK6ohfARkCAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeA
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBQqbAcEYwWRrmtnMjKtAPHM
# G19ffjANBgkqhkiG9w0BAQsFAAOCAQEACGHaVrK20Yaoyn7Ka1wWwFT9p7MNhJkP
# 0es5WJzr19KnfI1kZZyhBtHJFpdQ+oKUDYGF+VNqkRmTWa10egalpNjiACMfq3TI
# crcG7aj3XswdOxUhG0kuTOz06BJQgPu9Lai9GpOOulOyKkWcEE1GslPGxLm3iKAw
# HpgUHWMOWHi4MHGd8XAZRpU03QxWDFupJ1zqXrqRpU+83ZZfJVnv9E4kk1yJVC+c
# z0zfA4yXn4/m1cE0ujGPVDnRPiVQXUTEIasmh/+RrzKQU4ni3K/FpGyb03dEiTM0
# wQj6ojZ8nDVkWGfNsTTCQUNawAy/w+fqJ8/s/LD/H37zmtptI+QvbzGCAdwwggHY
# AgEBMDswJzElMCMGA1UEAwwcUG93ZXJTaGVsbCBDb2RlIFNpZ25pbmcgQ2VydAIQ
# G4j6Fy1vN4RI51iOsN6jXzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUo/CEy8vkodYtnFF8EeG7
# lKTwuOswDQYJKoZIhvcNAQEBBQAEggEAR0jnausa4jW0UJqa57Yjzp5yPiGREaZp
# /DLS0VndLMV3m0LSfIV0VW5kUT8ghP1cEaTTHZDFgIVw540i6yZCmPFYU5QcaUVh
# +gKNhfYSkaDVFCjhF87eU/8feCIhFVOzHbhtqdnhuFADLYdupTE1xSBEQgCIlnHP
# Iw8Eai+tZ++Y/gTAETL8l1WfWylF/I/5+VT2s3r1C6fiuCEvl/gRY+80kvfoKquI
# IsY1eI8HtHBIx7nX2MKks8twEDSjmRdmuej2pfvX15rfGreBx6emYlhUx2prE5HT
# DcNABy6Mv+8fpN4JLugIDhszXX/3OJ0TaQWAKR6b9PlYPna3Pd8Pmw==
# SIG # End signature block
