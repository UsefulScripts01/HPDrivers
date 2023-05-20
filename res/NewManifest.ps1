$param = @{
    Author            = 'Dawid Prowadzisz'
    RootModule        = 'HPDrivers.psm1'
    Path              = 'HPDrivers.psd1'
    ModuleVersion     = '1.1.2'
    GUID              = 'f87cbea8-7a55-47a4-b226-110750dd328d'
    Description       = 'Update all HP device drivers with a single command.'
    Copyright         = '(c) 2023 Dawid Prowadzisz. All rights reserved.'
    ProjectUri        = 'https://github.com/UsefulScripts01/HPDrivers'
    FunctionsToExport = 'Get-HPDrivers'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    FileList          = @(
        'HPDrivers.psm1'
        'HPDrivers.psd1'
    )
    Tags              = @(
        'HP'
        'drivers'
        'bios'
    )

    ReleaseNotes      =
    '

Update all HP device drivers with a single command - Get-HPDrivers


Parameters

-NoPrompt [switch] - Install all drivers and update BIOS
-ShowSoftware [switch] - Show additional HP software in the driver list
-DeleteInstallationFiles [switch] - Delete the HP SoftPaq installation files stored in C:\Temp
-UninstallHPCMSL [switch] - Uninstall HP CMSL at the end of installation process
-SuspendBL [switch] - Suspend BitLocker protection for one restart


Examples

Example 1:
Simple, just download and install all drivers.
Get-HPDrivers -NoPrompt

Example 2:
Show all available drivers and additional software. Do not keep installation files. Suspend the BitLocker pin on next reboot.
Get-HPDrivers -DeleteInstallationFiles -SuspendBL

'
}

New-ModuleManifest @param