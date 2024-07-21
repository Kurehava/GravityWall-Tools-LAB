# PLZ run command on administrator.
# PLZ run command on administrator.
# PLZ run command on administrator.

$cer = "$HOME\certificate.cer"
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "US=CSC" -CertStoreLocation Cert:\CurrentUser\My
Export-Certificate -Cert $cert -FilePath $cer
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root
Remove-Item -Path $cer -Force
