function Get-CurrentDirectory
{
  $thisName = $MyInvocation.MyCommand.Name
  [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

$fontHelpersPath = (Join-Path (Get-CurrentDirectory) 'FontHelpers.ps1')
. $fontHelpersPath

$destination = Join-Path $Env:Temp 'SourceCodeVariable'

$romanUrl = 'https://github.com/adobe-fonts/source-code-pro/releases/download/variable-fonts/SourceCodeVariable-Roman.ttf'
$romanChecksum = '01bafa5f571a714275d6d37202e8fa801a05713a';
Get-ChocolateyWebFile -PackageName 'SourceCodeVariable-Roman' -FileFullPath "$destination\SourceCodeVariable-Roman.ttf" -Url $romanUrl -ChecksumType 'sha1' -Checksum "$romanChecksum"

$italicUrl = 'https://github.com/adobe-fonts/source-code-pro/releases/download/variable-fonts/SourceCodeVariable-Italic.ttf'
$italicChecksum = '9bb6cc836a9ee23a6e004a3b0a858a59633cdb83'
Get-ChocolateyWebFile -PackageName 'SourceCodeVariable-Italic' -FileFullPath "$destination\SourceCodeVariable-Italic.ttf" -Url $italicUrl -ChecksumType 'sha1' -Checksum "$italicChecksum"

$shell = New-Object -ComObject Shell.Application
$fontsFolder = $shell.Namespace(0x14)
$fontFiles = Get-ChildItem $destination -Recurse -Filter *.ttf

# unfortunately the font install process totally ignores shell flags :(
# http://social.technet.microsoft.com/Forums/en-IE/winserverpowershell/thread/fcc98ba5-6ce4-466b-a927-bb2cc3851b59
# so resort to a nasty hack of compiling some C#, and running as admin instead of just using CopyHere(file, options)
$commands = $fontFiles |
% { Join-Path $fontsFolder.Self.Path $_.Name } |
? { Test-Path $_ } |
% { "Remove-SingleFont '$_' -Force;" }

# http://blogs.technet.com/b/deploymentguys/archive/2010/12/04/adding-and-removing-fonts-with-windows-powershell.aspx
$fontFiles |
% { $commands += "Add-SingleFont '$($_.FullName)';" }

$toExecute = ". $fontHelpersPath;" + ($commands -join ';')
Start-ChocolateyProcessAsAdmin $toExecute

Remove-Item $destination -Recurse