$mainFunction = 
{
    $mypath = $MyInvocation.MyCommand.Path
    Write-Output "Path of the script: $mypath"
    Write-Output "Args for script: $Args"

    GetLatestWinGet 

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $dscUri = "https://raw.githubusercontent.com/snailtail/setup/main/"
    $dscToolset = "toolset.dsc.yml";
    $dscWinSettings = "winSettings.dsc.yml";
            
    $dscToolsetUri = $dscUri + $dscToolset 
    
    $dscWinSettingsUri = $dscUri + $dscWinSettings

    # amazing, we can now run WinGet get fun stuff
    if (!$isAdmin)
    {
        # Shoulder tap terminal so it gets registered moving foward
        Start-Process shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App

        # restarting for Admin now
        Start-Process PowerShell -wait -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$mypath' $Args;`"";
        exit;
    }
    else 
    {
        Write-Host "Start: Toolset install"
        winget configuration -f $dscToolsetUri 
        Write-Host "Done: Toolset install"

        Write-Host "Start: Windows Settings"
        winget configuration -f $dscWinSettingsUri 
        Write-Host "Done: Windows Settings"
    }
}

function GetLatestWinGet
{
    # forcing WinGet to be installed
    $isWinGetRecent = (winget -v).Trim('v').TrimEnd("-preview").split('.')

    # turning off progress bar to make invoke WebRequest fast
    $ProgressPreference = 'SilentlyContinue'

    if(!(($isWinGetRecent[0] -gt 1) -or ($isWinGetRecent[0] -ge 1 -and $isWinGetRecent[1] -ge 6))) # WinGet is greater than v1 or v1.6 or higher
    {
       $paths = "Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.UI.Xaml.2.8.x64.appx", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
       $uris = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx", "https://aka.ms/getwinget"
       Write-Host "Downloading WinGet and its dependencies..."

       for ($i = 0; $i -lt $uris.Length; $i++) {
           $filePath = $paths[$i]
           $fileUri = $uris[$i]
           Write-Host "Downloading: ($filePat) from $fileUri"
           Invoke-WebRequest -Uri $fileUri -OutFile $filePath
       }

       Write-Host "Installing WinGet and its dependencies..."
   
       foreach($filePath in $paths)
       {
           Write-Host "Installing: ($filePath)"
           Add-AppxPackage $filePath
       }

       Write-Host "Verifying Version number of WinGet"
       winget -v

       Write-Host "Cleaning up"
       foreach($filePath in $paths)
       {
          if (Test-Path $filePath) 
          {
             Write-Host "Deleting: ($filePath)"
             Remove-Item $filePath -verbose
          } 
          else
          {
             Write-Error "Path doesn't exits: ($filePath)"
          }
       }
    }
    else {
       Write-Host "WinGet in decent state, moving to executing DSC"
    }
}

& $mainFunction