# Generate a self signed certificate and add to cert store
$CertSplat = @{
    CertStoreLocation = "cert:\currentuser\my"
    Subject           = "CN=Test Code Signing"
    KeyAlgorithm      = "RSA"
    KeyLength         = 2048
    Provider          = "Microsoft Enhanced RSA and AES Cryptographic Provider"
    KeyExportPolicy   = "Exportable"
    KeyUsage          = "DigitalSignature"
    Type              = "CodeSigningCert"
}

New-SelfSignedCertificate @CertSplat


# VSCode add command to sign current script

Register-EditorCommand -Name SignCurrentScript -DisplayName 'Sign Current Script' -ScriptBlock {
    $cert = (Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
    $currentFile = $psEditor.GetEditorContext().CurrentFile.Path
    Set-AuthenticodeSignature -Certificate $cert -FilePath $currentFile
}
