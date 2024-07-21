If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "need admin ..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$script = ""
$cer = "$HOME\certificate.cer"
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "US=CSC" -CertStoreLocation Cert:\CurrentUser\My
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
Export-Certificate -Cert $cert -FilePath $cer
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root
Set-AuthenticodeSignature -FilePath $script -Certificate $cert
Get-AuthenticodeSignature -FilePath $script
if (Test-Path $cer) {
    try {
        Remove-Item -Path $cer -Force
        Write-Output "File successfully deleted: $cer"
    } catch {
        Write-Error "An error occurred while deleting the file: $_"
    }
} else {
    Write-Output "File does not exist: $cer"
}
