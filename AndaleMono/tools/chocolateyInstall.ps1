function Get-CurrentDirectory
{
  $thisName = $MyInvocation.MyCommand.Name
  [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

$fontHelpersPath = (Join-Path (Get-CurrentDirectory) 'FontHelpers.ps1')
. $fontHelpersPath

$fontUrl = 'https://downloads.sourceforge.net/project/corefonts/the%20fonts/final/andale32.exe?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fcorefonts%2Ffiles%2Fthe%2520fonts%2Ffinal%2Fandale32.exe%2Fdownload&ts=1541290827'
$checksumType = 'sha1';
$checksum = 'c4db8cbe42c566d12468f5fdad38c43721844c69';
$destination = Join-Path $Env:Temp 'AndaleMono'
 
Install-ChocolateyZipPackage -PackageName 'AndaleMono' -Url $fontUrl -UnzipLocation $destination -ChecksumType "$checksumType" -Checksum "$checksum"
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