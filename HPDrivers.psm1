

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
            $SpList | Format-Table -AutoSize
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