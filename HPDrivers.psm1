function Get-HPDrivers {

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
        Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.6.9.exe" -OutFile "C:\Temp\hpcmsl.exe"
        Start-Process -FilePath "C:\Temp\hpcmsl.exe" -Wait -ArgumentList "/VERYSILENT"
        Start-Sleep -Seconds 5

        # check available drivers
        if (!$NoPrompt) {
            if ($ShowSoftware) { Get-SoftpaqList -Category BIOS, Diagnostic, Dock, Driver, Software, Utility | Select-Object -Property id, name, version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple | Export-Csv -Path "C:\Temp\SpList.csv" } # all
            else { Get-SoftpaqList -Category BIOS, Driver | Select-Object -Property id, name, version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple | Export-Csv -Path "C:\Temp\SpList.csv" } # default
        }
        if ($NoPrompt) {
            if ($ShowSoftware) { Get-SoftpaqList -Category BIOS, Diagnostic, Dock, Driver, Software, Utility | Export-Csv -Path "C:\Temp\SpList.csv" } # all
            else { Get-SoftpaqList -Category BIOS, Driver | Export-Csv -Path "C:\Temp\SpList.csv" } # default
        }

        $SpList = Import-Csv -Path "C:\Temp\SpList.csv"
        $SpList | Select-Object -Property id, name, version, Size, ReleaseDate | Format-Table -AutoSize

        # create path
        $Model = (Get-CimInstance -ClassName win32_ComputerSystem).Model
        if (!(Test-Path -Path "C:\Temp\$Model")) {
            New-Item -ItemType Directory -Path "C:\Temp\$Model" -Force
        }
        Set-Location -Path "C:\Temp\$Model"

        # download and install selected drivers
        Write-Host "`nThe script will install the following drivers. Please wait..`n" -ForegroundColor White -BackgroundColor DarkGreen
        foreach ($Number in $SpList.id) {
            Get-Softpaq -Number $Number -Overwrite no -Action silentinstall -ErrorAction SilentlyContinue
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