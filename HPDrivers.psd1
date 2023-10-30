#
# Module manifest for module 'HPDrivers'
#
# Generated by: Dawid Prowadzisz
#
# Generated on: 10/30/2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'HPDrivers.psm1'

# Version number of this module.
ModuleVersion = '1.3.2'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'f87cbea8-7a55-47a4-b226-110750dd328d'

# Author of this module
Author = 'Dawid Prowadzisz'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2023 Dawid Prowadzisz. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Update all HP device drivers with a single command.'

# Minimum version of the PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Get-HPDrivers'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = 'HPDrivers.psm1', 'HPDrivers.psd1'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'HP', 'Drivers', 'BIOS', 'UEFI'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/UsefulScripts01/HPDrivers'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '

Update all HP device drivers with a single command - Get-HPDrivers


Parameters

-NoPrompt [switch] - Install all drivers and update BIOS
-ShowSoftware [switch] - Show additional HP software in the driver list
-Overwrite [switch] - Install the drivers even if the current driver version is the same
-DeleteInstallationFiles [switch] - Delete the HP SoftPaq installation files stored in C:\Temp
-UninstallHPCMSL [switch] - Uninstall HP CMSL at the end of installation process
-SuspendBL [switch] - Suspend BitLocker protection for one restart


Examples


Example 1:
Simple, just download and install all drivers.

Get-HPDrivers -NoPrompt


Example 2:
Show all available drivers and additional software.
Do not keep installation files. Suspend the BitLocker pin on next reboot.

Get-HPDrivers -ShowSoftware -DeleteInstallationFiles -SuspendBL


Example 3:
Download and install all drivers and BIOS, even if the current driver version is the same.

Get-HPDrivers -NoPrompt -Overwrite


Example 4:
Automatic driver installation. Can be part of a deployment script.

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name HPDrivers -Force
Get-HPDrivers -NoPrompt -DeleteInstallationFiles

'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

