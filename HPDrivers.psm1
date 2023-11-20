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

    .PARAMETER Overwrite
        Install the drivers even if the current driver version is the same

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

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [switch]$NoPrompt,
        [Parameter(Mandatory = $false)] [switch]$ShowSoftware,
        [Parameter(Mandatory = $false)] [switch]$DeleteInstallationFiles,
        [Parameter(Mandatory = $false)] [switch]$UninstallHPCMSL,
        [Parameter(Mandatory = $false)] [switch]$Overwrite,
        [Parameter(Mandatory = $false)] [switch]$SuspendBL
    )

    # if machine manufacturer is HP
    $Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    if (($Manufacturer -match "HP") -or ($Manufacturer -match "Hewlett-Packard")) {

        # Obtain the current screen and sleep timeout values
        $DisplayTimeoutDC = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerSettingDataIndex | Where-Object -Property InstanceID -EQ "Microsoft:PowerSettingDataIndex\{381b4222-f694-41f0-9685-ff5bb260df2e}\DC\{3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e}"
        $DisplayTimeoutAC = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerSettingDataIndex | Where-Object -Property InstanceID -EQ "Microsoft:PowerSettingDataIndex\{381b4222-f694-41f0-9685-ff5bb260df2e}\AC\{3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e}"
        $SleepTimeoutDC = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerSettingDataIndex | Where-Object -Property InstanceID -EQ "Microsoft:PowerSettingDataIndex\{381b4222-f694-41f0-9685-ff5bb260df2e}\DC\{29f6c1db-86da-48c5-9fdb-f2b67b1f44da}"
        $SleepTimeoutAC = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerSettingDataIndex | Where-Object -Property InstanceID -EQ "Microsoft:PowerSettingDataIndex\{381b4222-f694-41f0-9685-ff5bb260df2e}\AC\{29f6c1db-86da-48c5-9fdb-f2b67b1f44da}"

        # Convert this values to seconds and store them into the variables
        $DisplayTimeoutDC = $DisplayTimeoutDC.SettingIndexValue / 60
        $DisplayTimeoutAC = $DisplayTimeoutAC.SettingIndexValue / 60
        $SleepTimeoutDC = $SleepTimeoutDC.SettingIndexValue / 60
        $SleepTimeoutAC = $SleepTimeoutAC.SettingIndexValue / 60

        # Set screen and sleep timeout to infinite
        powercfg -change -monitor-timeout-dc 0
        powercfg -change -monitor-timeout-ac 0
        powercfg -change -standby-timeout-dc 0
        powercfg -change -standby-timeout-ac 0

        # create path
        if (!(Test-Path -Path "C:\Temp\HPDrivers")) {
            New-Item -ItemType Directory -Path "C:\Temp\HPDrivers" -Force
        }
        Set-Location -Path "C:\Temp\HPDrivers"

        # Install HPCMSL
        $LatestHPCMSL = (Find-Module -Name HPCMSL).Version
        $InstalledHPCMSL = (Get-InstalledModule -Name HPCMSL -ErrorAction Ignore).Version
        Write-Host "`nLatest HPCMSL: $LatestHPCMSL" -ForegroundColor Green
        Write-Host "Installed HPCMSL: $InstalledHPCMSL `n" -ForegroundColor Green

        if ($LatestHPCMSL -gt $InstalledHPCMSL) {
            Install-PackageProvider -Name NuGet -Force
            Install-Module -Name PowerShellGet -AllowClobber -Force -WarningAction Ignore
            Start-Process -FilePath "powershell" -Wait -NoNewWindow {
                Install-Module -Name HPCMSL -Force -AcceptLicense -Scope CurrentUser
            }
            Start-Sleep -Seconds 2
        }

        # Get the list of available drivers
        try {
            if (!$ShowSoftware) { $AvailableDrivers = Get-SoftpaqList -Category BIOS, Driver }
            if ($ShowSoftware) { $AvailableDrivers = Get-SoftpaqList -Category BIOS, Driver, Diagnostic, Dock, Software, Utility }   
        }
        catch {
            $OsVer = (Get-Item "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('DisplayVersion')
            Write-Host "`nHPCMSL does not yet support Windows ${OsVer}!`nIf you want to download and install drivers for an older (supported) version, please provide it below..`n" -ForegroundColor Red
            $OsVer = Read-Host -Prompt "Please provide version (e.g. 22H2, 23H2)"
            if (!$ShowSoftware) { $AvailableDrivers = Get-SoftpaqList -OsVer $OsVer -Category BIOS, Driver }
            if ($ShowSoftware) { $AvailableDrivers = Get-SoftpaqList -OsVer $OsVer -Category BIOS, Driver, Diagnostic, Dock, Software, Utility }   
        }
   
        # Select drivers from the list of available drivers
        if (!$NoPrompt) { $SpList = $AvailableDrivers | Select-Object -Property id, Name, Version, Size, ReleaseDate | Out-GridView -Title "Select driver(s):" -OutputMode Multiple }
        if ($NoPrompt) { $SpList = $AvailableDrivers }

        # Show list of available drivers
        if ($SpList) {
            Write-Host "`nThe script will install the following drivers. Please wait..`n" -ForegroundColor White -BackgroundColor DarkGreen
            $SpList | Select-Object -Property id, Name, Version, Size, ReleaseDate | Format-Table -AutoSize
        }

        $Date = Get-Date -Format "dd.MM.yyyy"
        $HR = "-" * 100
        $Line = $Date + " " + $HR
        $Line | Out-File -FilePath "C:\Temp\InstalledHPDrivers.log" -Append

        # download and install selected drivers
        foreach ($Number in $SpList.id) {
            $AvailableSpVersion = Get-SoftpaqMetadata -Number $Number | Out-SoftpaqField -Field Version
            $InstalledSpVersion = 0

            # Get the version of the installed softpaq package
            if (!$Overwrite) {
                $CvaFile = Get-ChildItem -Path "C:\SWSetup\$Number" -Filter "*.cva" -Recurse
                if ($CvaFile) {
                    $CvaContent = Get-Content -Path $CvaFile.VersionInfo.FileName
                    $InstalledSpVersion = ($CvaContent | Select-String -Pattern "^VendorVersion").ToString().Split('=')[1]
                }

                if (Test-Path -Path "C:\SWSetup\$Number\version.txt") {
                    $InstalledSpVersion = Get-Content -Path "C:\SWSetup\$Number\version.txt" -ErrorAction SilentlyContinue
                }
            }

            # Install selected packages - do not overwrite
            if ($AvailableSpVersion -gt $InstalledSpVersion) {
                try {
                    Get-Softpaq -Number $Number -Action silentinstall -MaxRetries 2
                    $AvailableSpVersion | Out-File -FilePath "C:\SWSetup\$Number\version.txt"

                    $Info = Get-SoftpaqMetadata -Number $Number | Out-SoftpaqField -Field Title
                    $DateTime = Get-Date -Format "dd.MM.yyyy HH:mm"
                    "$DateTime - $Number - $Info - $AvailableSpVersion" | Out-File -FilePath "C:\Temp\InstalledHPDrivers.log" -Append

                    $Info += ' - ' + $Number + ' - INSTALLED'
                    Write-Host $Info -ForegroundColor Green
                }

                catch {
                    $Info = Get-SoftpaqMetadata -Number $Number | Out-SoftpaqField -Field Title
                    $Info += ' - ' + $Number + ' - FAILED!'
                    Write-Host $Info -ForegroundColor Red
                }
            }

            else {
                $AvailableSpVersion | Out-File -FilePath "C:\SWSetup\$Number\version.txt"
                $Info = Get-SoftpaqMetadata -Number $Number | Out-SoftpaqField -Field Title
                $Info += ' - ' + $Number + ' - LATEST VERSION ALREADY INSTALLED'
                Write-Host $Info -ForegroundColor Blue
            }
        }

        # remove installation files
        if ($DeleteInstallationFiles -and (Test-Path -Path "C:\Temp\HPDrivers")) {
            Set-Location -Path $HOME
            Remove-Item -Path "C:\Temp\HPDrivers" -Recurse -Force
        }

        # uninstall HP Client Management Script Library
        $HPCMSL = Get-InstalledModule -Name HPCMSL -ErrorAction Ignore
        if ($UninstallHPCMSL -and $HPCMSL) {
            Write-Host "`nUninstalling HPCMSL..`n" -ForegroundColor Green
            Get-InstalledModule -Name HPCMSL | Uninstall-Module -Force -Verbose
            Get-InstalledModule -Name "HP.*" | Uninstall-Module -Force -Verbose
        }

        # disable BitLocker pin for one restart (BIOS update)
        if ($SuspendBL -and ((Get-BitLockerVolume -MountPoint "C:").VolumeStatus -ne "FullyDecrypted")) {
            Suspend-BitLocker -MountPoint "C:" -RebootCount 1
        }

        # Revert to the previous (user) values
        powercfg -change -monitor-timeout-dc $DisplayTimeoutDC
        powercfg -change -monitor-timeout-ac $DisplayTimeoutAC
        powercfg -change -standby-timeout-dc $SleepTimeoutDC
        powercfg -change -standby-timeout-ac $SleepTimeoutAC
    }
}
Export-ModuleMember -Function Get-HPDrivers
