﻿$ErrorActionPreference = 'Stop';

if ($env:Path.Contains("chocolatey"))
{
    "Choco already installed"
}
else
{
    "Installing Choco"
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

$ExistingChocoPackages = (& choco list -localonly) | % { $_.Split(' ')[0] }
function Install-ChocoIfNotAlready($name) {
    if ($ExistingChocoPackages -contains $name)
    {
        "$name already installed"
    }
    else
    {
        "Installing $name"
        & choco install $name
    }
}

Install-ChocoIfNotAlready git.install
Install-ChocoIfNotAlready putty.install
Install-ChocoIfNotAlready SublimeText3
Install-ChocoIfNotAlready SublimeText3.PackageControl
Install-ChocoIfNotAlready fiddler4
Install-ChocoIfNotAlready resharper
Install-ChocoIfNotAlready nodejs.install
Install-ChocoIfNotAlready Jump-Location

$OneDriveRoot = (gi HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive).GetValue('UserFolder')
if (-not (Test-Path $OneDriveRoot))
{
    throw "Couldn't find the OneDrive root"
}

$SshKeyPath = Join-Path $OneDriveRoot Tools\ssh\id.ppk
if (-not (Test-Path $SshKeyPath))
{
    throw "Couldn't find SSH key at $SshKeyPath"
}

"Setting Pageant shortcut to load the private key automatically"
# This way, I can type Win+pageant+Enter, and it's all configured
$WshShell = New-Object -ComObject WScript.Shell
$PageantShortcut = $WshShell.CreateShortcut((Join-Path ([Environment]::GetFolderPath("CommonStartMenu")) Programs\PuTTY\Pageant.lnk))
$PageantShortcut.Arguments = "-i $SshKeyPath"
$PageantShortcut.Save()

"Setting plink.exe as GIT_SSH"
$PuttyDirectory = $PageantShortcut.WorkingDirectory
$PlinkPath = Join-Path $PuttyDirectory plink.exe
[Environment]::SetEnvironmentVariable('GIT_SSH', $PlinkPath, [EnvironmentVariableTarget]::User)
$env:GIT_SSH = $PlinkPath

"Setting git identity"
git config --global user.name "Tatham Oddie"
git config --global user.email "tatham@oddie.com.au"

if ((& git config push.default) -eq $null)
{
    "Setting git push behaviour to squelch the 2.0 upgrade message"
    git config --global push.default simple
}

"Setting git aliases"
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.df "diff"
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"

"Setting PS aliases"
if ((Get-Alias -Name st -ErrorAction SilentlyContinue) -eq $null) {
    Add-Content $PROFILE "`r`n`r`nSet-Alias -Name st -Value (Join-Path `$env:ProgramFiles 'Sublime Text 3\sublime_text.exe')"
}

"Reloading PS profile"
. $PROFILE