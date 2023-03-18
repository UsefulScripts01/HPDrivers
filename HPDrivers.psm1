function Get-HPDrivers {

    param(
        [Parameter(Mandatory = $false)] [string]$DriversAndSoftware,
        [Parameter(Mandatory = $false)] [string]$BIOS,
        [Parameter(Mandatory = $false)] [string]$DeleteInstallationFiles,
        [Parameter(Mandatory = $false)] [string]$UninstallHPCMSL
    )

    # if machine manufacturer is HP
    $Bios = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    if (($Bios -match "HP") -or ($Bios -match "Hewlett-Packard")) {

        $ProgressPreference = "SilentlyContinue"
        $ConfirmPreference = "None"

        # create path
        $Model = (Get-CimInstance -ClassName win32_ComputerSystem).Model
        if (!(Test-Path -Path "C:\Temp\$Model")) {
            New-Item -ItemType Directory -Path "C:\Temp\$Model" -Force
        }
        Set-Location -Path "C:\Temp\$Model"

        # install HPCMSL
        if (!(Get-CimInstance -ClassName Win32_InstalledWin32Program).Name -contains 'HP Client Management Script Library') {
            Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.6.8.exe" -OutFile "C:\Temp\hpcmsl.exe" -Verbose
            Start-Process -FilePath "C:\Temp\hpcmsl.exe" -Wait -ArgumentList "/VERYSILENT"
        }
    
        # check available drivers
        if ($DriversAndSoftware) { $DriverList = Get-SoftpaqList -Category BIOS, Diagnostic, Dock, Driver, Software, Utility | Select-Object -Property id, name, version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple } # all
        elseif ($BIOS) { $DriverList = Get-SoftpaqList -Category BIOS | Select-Object -Property id, name, version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple }
        else { $DriverList = Get-SoftpaqList -Category BIOS, Driver | Select-Object -Property id, name, version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple } # default

        Write-Host "`n"
        Write-Host " Tool will install the selected drivers. This may take 10-15 minutes. Please wait.. " -BackgroundColor DarkGreen
        Write-Host "`n"
        # download and install selected drivers
        foreach ($Number in $DriverList.id) {
            Get-Softpaq -Number $Number -Overwrite no -Action silentinstall -ErrorAction SilentlyContinue
        }

        if ($DriverList) {
            Write-Host "`n"
            Write-Host " The following drivers have been installed: " -ForegroundColor White -BackgroundColor DarkGreen
            $DriverList | Format-Table -AutoSize
        }

        # remove installation files
        if ($DeleteInstallationFiles -and (Test-Path -Path "C:\Temp\$Model")) {
            Set-Location -Path $HOME
            Remove-Item -Path "C:\Temp\$Model" -Recurse -Force -Verbose
        }

        # uninstall HP Client Management Script Library
        if ($UninstallHPCMSL -and ((Get-CimInstance -ClassName Win32_InstalledWin32Program).Name -contains 'HP Client Management Script Library')) {
            Start-Process -FilePath "C:\Program Files\WindowsPowerShell\HP.CMSL.UninstallerData\unins000.exe" -Wait -ArgumentList "/VERYSILENT"
        }
        
        # disable BitLocker pin for one restart (BIOS update)
        if ((Get-BitLockerVolume -MountPoint "C:").VolumeStatus -ne "FullyDecrypted") {
            Suspend-BitLocker -MountPoint "C:" -RebootCount 1
        }
        Set-Location -Path $HOME
    }
}
# Get-HPDrivers

Export-ModuleMember -Function Get-HPDrivers