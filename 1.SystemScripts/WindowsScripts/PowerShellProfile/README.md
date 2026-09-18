You can COPY Microsoft.PowerShell_profile.ps1 to this path:  
"C:\Users\<user_name>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

Or use command:
echo $PROFILE

Beacuse, PowerShell and PWSH's  Profile path is different.
------------------------------------------------------------------------------
Or you can sign Microsoft.PowerShell_profile.ps1 script then use this.

# cert your script
First, create a cert use code block command. 
> * You must copy & pasta command to powershell and exec.  
> * Then you can get a cert on local.

Second, cert your script
> * Use code block command to cert your script.  
> * Then you can use script on your powershell.  
> * When you script changed, you must cert your script again.

```
first, Download "Microsoft.PowerShell_profile.ps1" and rename to "$PROFILE".

# PLZ run command on administrator.
# PLZ run command on administrator.
# PLZ run command on administrator.

$cer = "$HOME\certificate.cer"
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=CSC" -CertStoreLocation Cert:\CurrentUser\My
Export-Certificate -Cert $cert -FilePath $cer
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root
Remove-Item -Path $cer -Force

$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "CN=CSC" }  
Set-AuthenticodeSignature -FilePath "$PROFILE" -Certificate $cert
```
