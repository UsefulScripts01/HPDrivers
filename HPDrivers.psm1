function WriteToHPDriversLog {
    <#
    .SYNOPSIS
        Collect HPDrivers module logs.

    .DESCRIPTION
        'WriteToHPDriversLog' collects log files regarding installations and errors.
        This function will be called multiple times in the script below.
    #>

    $TimeStamp = (Get-Date).ToString('dd.MM.yyyy HH:mm:ss')
    $Status = $Info.Status
    $LogMessage = $TimeStamp + ' - ' + $Number + ' - ' + $Name + ' - ' + $AvailableSpVersion + ' - ' + $Status
    $LogMessage | Out-File -FilePath "C:\Temp\InstalledHPDrivers.log" -Append

    # Collect occurred errors
    foreach ($Entry in $Error) {
        $ErrorMessage = $TimeStamp + ' - ' + $Entry
        $ErrorMessage | Out-File -FilePath "C:\Temp\HPDriversError.log" -Append
    }
    $Error.Clear()
}

function Get-HPDrivers {
    <#
    .SYNOPSIS
        Update all HP device drivers with a single command - Get-HPDrivers.

    .DESCRIPTION
        The HPDrivers module downloads and installs softpaqs that match the operating system version and hardware configuration.

    .PARAMETER NoPrompt
        Download and install all drivers

    .PARAMETER OsVersion
        Specify the operating system version (e.g. 22H2, 23H2)

    .PARAMETER ShowSoftware
        Show additional HP software in the driver list

    .PARAMETER Overwrite
        Install the drivers even if the current driver version is the same

    .PARAMETER BIOS
        Update the BIOS to the latest version

    .PARAMETER DeleteInstallationFiles
        Delete the HP SoftPaq installation files stored in C:\Temp

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
        Get-HPDrivers -ShowSoftware -DeleteInstallationFiles -SuspendBL

        Show a list of available drivers and additional software. The selected drivers will be installed automatically. Do not keep installation files. Suspend the BitLocker pin on next reboot.

    .EXAMPLE
        Get-HPDrivers -NoPrompt -BIOS -Overwrite

        Download and install all drivers and BIOS, even if the current driver version is the same.

    .EXAMPLE
        Get-HPDrivers -OsVersion '22H2'

        Show a list of available drivers that match the current platform and Windows 22H2. The selected drivers will be installed automatically.

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [switch]$NoPrompt,
        [Parameter(Mandatory = $false)] [string]$OsVersion,
        [Parameter(Mandatory = $false)] [switch]$ShowSoftware,
        [Parameter(Mandatory = $false)] [switch]$Overwrite,
        [Parameter(Mandatory = $false)] [switch]$BIOS,
        [Parameter(Mandatory = $false)] [switch]$DeleteInstallationFiles,
        [Parameter(Mandatory = $false)] [switch]$SuspendBL
    )

    # if machine manufacturer is HP
    $Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    if (($Manufacturer -match "HP") -or ($Manufacturer -match "Hewlett-Packard")) {
        $DefPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        $Error.Clear()

        # create path
        if (!(Test-Path -Path "C:\Temp\HPDrivers")) {
            New-Item -ItemType Directory -Path "C:\Temp\HPDrivers" -Force
        }
        Set-Location -Path "C:\Temp\HPDrivers"

        # Warn if battery is below 80%
        $Charge = (Get-CimInstance -ClassName Win32_Battery).EstimatedChargeRemaining
        if ($Charge -le "50") {
            Write-Output `n
            Write-Warning "Battery level: ${Charge}%`nPLEASE CONNECT AN AC ADAPTER`n"
        }

        $TestConn = Test-Connection "hpia.hpcloud.hp.com" -Count 2 -ErrorAction Ignore
        if (!$TestConn) {
            Write-Output `n
            Write-Warning "hpia.hpcloud.hp.com is unavailable!`nPlease check your internet connection or try again later..`n"
            Break
        }

        # Download the list of available drivers
        try {
            # Check available drivers
            if (!$OsVersion) { $OsVersion = (Get-Item "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('DisplayVersion') }
            $Platform = (Get-CimInstance -ClassName Win32_BaseBoard).Product
            if ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption -match "10") { $OsType = "10" }
            if ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption -match "11") { $OsType = "11" }

            # Download the drivers list
            $CabUri = ("https://hpia.hpcloud.hp.com/ref/${Platform}/${Platform}_64_${OsType}.0.${OsVersion}.cab").ToLower()
            Invoke-WebRequest -Uri $CabUri -OutFile "C:\Temp\HPDrivers\hp.cab"

            $Model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
            Write-Output `n
            Write-Verbose "Drivers found: $Model - Windows ${OsVersion}..`n" -Verbose
        }
        catch {
            Write-Output `n
            Write-Warning "HP does not yet support Windows ${OsVersion}!`nIf you want to download and install drivers for a different (supported) version of Windows,`nplease specify the version using the -OsVersion parameter.`n"
            Break
        }

        # Expand hp.cab and load HPDrivers.xml file
        if (Test-Path -Path "C:\Temp\HPDrivers\hp.cab") {
            Start-Process -FilePath "powershell" -Wait -WindowStyle Hidden {
                expand C:\Temp\HPDrivers\hp.cab C:\Temp\HPDrivers\HpDrivers.xml
            }
            Remove-Item -Path "C:\Temp\HPDrivers\hp.cab" -Force
            [XML]$Xml = Get-Content -Path "C:\Temp\HPDrivers\HpDrivers.xml"
        }

        # Sort the driver list
        # 'Driverpack' = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'Driverpack' }
        # 'UWPPack' = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'UWPPack' }
        # 'Software' = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'Software -' }
        $Category = New-Object -Type PSObject @{
            'BIOS'       = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'BIOS' }
            'Driver'     = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'Driver -' }
            'Diagnostic' = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'Diagnostic' }
            'Utility'    = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'Utility -' }
            'Dock'       = $Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Category -match 'Dock -' }
        }

        # Select category
        if (!$ShowSoftware) { $AvailableDrivers = $Category.Driver }
        if ($ShowSoftware) { $AvailableDrivers = $Category.Driver + $Category.Software + $Category.Diagnostic + $Category.Utility + $Category.Dock }
        if ($BIOS) { $AvailableDrivers += $Category.BIOS }

        # Select drivers from the list of available drivers
        if (!$NoPrompt) { $SpList = $AvailableDrivers | Select-Object -Property id, Name, Category, Version, Size, DateReleased | Out-GridView -Title "Select driver(s):" -OutputMode Multiple }
        if ($NoPrompt) { $SpList = $AvailableDrivers }

        $Date = Get-Date -Format "dd.MM.yyyy"
        $HR = "-" * 100
        $Line = $Date + " " + $HR
        $Line | Out-File -FilePath "C:\Temp\InstalledHPDrivers.log" -Append

        # Show list of available drivers
        if ($SpList) {
            Write-Verbose "The script will install the following drivers. Please wait..`n" -Verbose
            $SpList | Select-Object -Property Id, Name, Version, Size, DateReleased | Format-Table -AutoSize
        }

        # download and install selected drivers
        foreach ($Number in $SpList.id) {

            # Obtain information about the actual installed driver
            $Name = ($Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Id -eq $Number }).Name
            $Source = ($Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Id -eq $Number }).Url
            $SilentInstall = ($Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Id -eq $Number }).SilentInstall
            $AvailableSpVersion = ($Xml.ImagePal.Solutions.UpdateInfo | Where-Object { $_.Id -eq $Number }).Version

            # Get the version of the installed softpaq package
            $InstalledSpVersion = 0

            if (!$Overwrite) {
                $CvaFile = Get-ChildItem -Path "C:\SWSetup\$Number" -Filter "*.cva" -Recurse -ErrorAction Ignore
                if ($CvaFile) {
                    $CvaContent = Get-Content -Path $CvaFile.VersionInfo.FileName
                    $InstalledSpVersion = ($CvaContent | Select-String -Pattern "^VendorVersion").ToString().Split('=')[1]
                }

                if (Test-Path -Path "C:\SWSetup\$Number\version.txt") {
                    $InstalledSpVersion = Get-Content -Path "C:\SWSetup\$Number\version.txt" -ErrorAction SilentlyContinue
                }
            }

            # if a new driver version is available
            if ($AvailableSpVersion -gt $InstalledSpVersion) {

                try {
                    # Download file
                    Start-BitsTransfer -Source "https://${Source}" -Destination "C:\Temp\HPDrivers" -DisplayName "Downloading:" -Description $Name

                    # Checksum
                    $SPFileExist = Test-Path -Path "C:\Temp\HPDrivers\${Number}.exe"
                    $SPFileChecksum = (Get-FileHash -Path "C:\Temp\HPDrivers\${Number}.exe" -Algorithm SHA256).Hash
                    $OryginalChecksum = ($AvailableDrivers | Where-Object { $_.Id -eq $Number }).SHA256

                    if (!$SPFileExist -or ($SPFileChecksum -ne $OryginalChecksum)) {
                        $ThrowMessage = "${Number}.exe - " + $Name + " - Checksum Error!"
                        throw $ThrowMessage
                    }

                    # Installation process
                    $SetupFile = $SilentInstall.Split()[0].Trim('"')
                    $SetupCommand = $SilentInstall.Split()[0]
                    $Param = $SilentInstall.Replace($SetupCommand, '')

                    # Setup.exe files with a special params
                    if ($Param) {
                        Start-Process -FilePath "C:\Temp\HpDrivers\$Number" -Wait -ArgumentList "/s /e /f C:\SWSetup\$Number"
                        Start-Process -FilePath "C:\SWSetup\$Number\$SetupFile" -Wait -ArgumentList $Param
                    }

                    # CMD Wrapper, HPUP and other installers
                    if (!$Param) {
                        Start-Process -FilePath "C:\Temp\HpDrivers\${Number}.exe" -Wait -ArgumentList "/s /f C:\SWSetup\$Number"
                    }

                    # Save file with installd version
                    if (Test-Path -Path "C:\SWSetup\$Number") {
                        $AvailableSpVersion | Out-File -FilePath "C:\SWSetup\$Number\version.txt"
                    }

                    $Info = New-Object -Type PSObject -Property @{
                        'Id'      = $Number
                        'Name'    = $Name
                        'Version' = $AvailableSpVersion
                        'Status'  = "Installed"
                    }
                    $Info | Select-Object -Property Id, Name, Version, Status

                    WriteToHPDriversLog
                    Start-Sleep -Seconds 5
                }

                catch {
                    $Info = New-Object -Type PSObject -Property @{
                        'Id'      = $Number
                        'Name'    = $Name
                        'Version' = $AvailableSpVersion
                        'Status'  = "Failed"
                    }
                    $Info | Select-Object -Property Id, Name, Version, Status

                    WriteToHPDriversLog
                }
            }

            # if the driver is up to date
            if ($AvailableSpVersion -le $InstalledSpVersion) {
                # Save file with installd version
                if (Test-Path -Path "C:\SWSetup\$Number") {
                    $AvailableSpVersion | Out-File -FilePath "C:\SWSetup\$Number\version.txt"
                }

                $Info = New-Object -Type PSObject -Property @{
                    'Id'      = $Number
                    'Name'    = $Name
                    'Version' = $AvailableSpVersion
                    'Status'  = "Already Installed"
                }
                $Info | Select-Object -Property Id, Name, Version, Status

                WriteToHPDriversLog
            }
        }

        # remove installation files
        if ($DeleteInstallationFiles -and (Test-Path -Path "C:\Temp\HPDrivers")) {
            Set-Location -Path $HOME
            Remove-Item -Path "C:\Temp\HPDrivers" -Recurse -Force
        }

        # disable BitLocker pin for one restart (BIOS update)
        if ($SuspendBL -and ((Get-BitLockerVolume -MountPoint "C:").VolumeStatus -ne "FullyDecrypted")) {
            Suspend-BitLocker -MountPoint "C:" -RebootCount 1
        }

        $ProgressPreference = $DefPref
    }
}
Export-ModuleMember -Function Get-HPDrivers