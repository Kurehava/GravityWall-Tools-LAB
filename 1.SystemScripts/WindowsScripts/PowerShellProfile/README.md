# cert your script
First, create a cert use code block command. 
> * You must copy & pasta command to powershell and exec.  
> * Then you can get a cert on local.

Second, cert your script
> * Use code block command to cert your script.  
> * Then you can use script on your powershell.  
> * When you script changed, you must cert your script again.

```
# PLZ run command on administrator.
# PLZ run command on administrator.
# PLZ run command on administrator.

$cer = "$HOME\certificate.cer"
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "US=CSC" -CertStoreLocation Cert:\CurrentUser\My
Export-Certificate -Cert $cert -FilePath $cer
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root
Remove-Item -Path $cer -Force

$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "US=CSC" }  
Set-AuthenticodeSignature -FilePath "$HOME\Documents\PowerShell\Microsoft.Powershell_profile.ps1" -Certificate $cert
```
