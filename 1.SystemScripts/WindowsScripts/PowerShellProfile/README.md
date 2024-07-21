# cert your script
First, create a cert use cert_script.ps1
> * You can not exec this script on windows.  
> * You must copy & pasta command to powershell and exec.  
> * Then you can get a cert on local.

Second, cert your script
> * Use code block command to cert your script.  
> * Then you can use script on your powershell.  
> * When you script changed, you must cert your script again.

```
$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "US=CSC" }  
Set-AuthenticodeSignature -FilePath "$HOME\Documents\PowerShell\Microsoft.Powershell_profile.ps1" -Certificate $cert
```
