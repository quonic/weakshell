#Requires -Version 5 -Modules VMware.PowerCLI
if(-not (Get-Module -ListAvailable -Name VMware.PowerCLI)){
    Install-Module -Name VMware.PowerCLI -Scope CurrentUser
}
Import-Module VMware.PowerCLI

$ServerList = @(
'vCenter1'
'vCenter2'
)

$ServersConnectedTo = ''

#region Connect Button Script
    $scriptConnect = {
        $ServersConnectedTo = $lstServer.SelectedItems
        $lstServer.SelectedItems | ForEach-Object {
            Connect-VIServer -Server [string]$_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }
#endregion

#region Forms

    function New-Form {
        Param(
            [Parameter(Mandatory = $true)]
            [string]
            $Text,
            [switch]
            $TopMost,
            [int]
            $Width = 600,
            [int]
            $Height = 400,
            [string]
            $BackColor,
            [string]
            $BackgroundImage,
            [string]
            $Icon
        )
        Add-Type -AssemblyName System.Windows.Forms
        $Control = New-Object System.Windows.Forms.Form
        $Control.Text = $Text
        $Control.TopMost = $TopMost
        $Control.Width = $Width
        $Control.Height = $Height
        if ($BackColor) {
            $Control.BackColor = $BackColor
        }
        if ($BackgroundImage) {
            $Control.BackgroundImage = [system.drawing.image]::FromFile($BackgroundImage)
        }
        if ($Icon) {
            $Control.Icon = New-Object system.drawing.icon($Icon)
        }
        Return $Control
    }

    function Show-Form ($Form) {
        [void]$Form.ShowDialog()
    }

    function Remove-Form ($Form) {
        $Form.Dispose()
    }

    function Add-Control ($Form, $Control) {
        $Form.Controls.Add($Control)
    }

    function Set-ControlLocation ($Control, [int]$Left, [int]$Top) {
        $Control.location = new-object system.drawing.point($Left, $Top)
    }
#endregion
#region ListBox

    function New-ListBox {
        Param(
            [string]
            $Text,
            [int]
            $Left=0,
            [int]
            $Top=0,
            [int]
            $Width=600,
            [int]
            $Height=400
        )
        $Control = New-Object system.windows.Forms.ListBox
        if($Text){
            $Control.Text = $Text
        }
        $Control.Width = $Width
        $Control.Height = $Height
        $Control.location = new-object system.drawing.point($Left,$Top)
        Return $Control
    }

    function Add-ControlItem ($Control,[string[]]$Items) {
        $Items | ForEach-Object{
            [void] $Control.Items.Add([string]$_)
        }
    }
#endregion
#region Button
    function New-Button {
        Param(
            [string]
            $Text,
            [int]
            $Left = 0,
            [int]
            $Top = 0,
            [int]
            $Width = 600,
            [int]
            $Height = 400,
            [string]
            $Font = 'Microsoft Sans Serif,10',
            [string]
            $BackColor,
            [string]
            $ForColor,
            [switch]
            $Bold,
            [switch]
            $Italic,
            [switch]
            $Strikeout,
            [switch]
            $Underline
        )
        $Control = New-Object system.windows.Forms.Button
        if($Text){
            $Control.Text = $Text
        }
        $Control.Width = $Width
        $Control.Height = $Height
        $Control.location = new-object system.drawing.point($Left, $Top)
        if ($BackColor) {$Control.BackColor = $BackColor}
        if ($ForeColor) {$Control.ForeColor = $ForeColor}
        if ($Bold -or $Italic -or $Strikeout -or $Underline) {$Font = "$Font,style="}
        if ($Bold) {$Font = "$Font,Bold"}
        if ($Italic) {$Font = "$Font,Italic"}
        if ($Strikeout) {$Font = "$Font,Strikeout"}
        if ($Underline) {$Font = "$Font,Underline"}
        $Control.Font = $Font

        Return $Control
    }
#endregion
#region Label

    function New-Label {
        Param(
            [string]
            $Text,
            [int]
            $Left=0,
            [int]
            $Top=0,
            [int]
            $Width=600,
            [int]
            $Height=400,
            [string]
            $Font='Microsoft Sans Serif,10',
            [string]
            $BackColor,
            [string]
            $ForColor,
            [switch]
            $Bold,
            [switch]
            $Italic,
            [switch]
            $Strikeout,
            [switch]
            $Underline,
            [switch]
            $AutoSize
        )
        $Control = New-Object system.windows.Forms.Label
        if($Text){
            $Control.Text = $Text
        }
        $Control.Width = $Width
        $Control.Height = $Height
        $Control.location = new-object system.drawing.point($Left,$Top)
        if ($BackColor) {$Control.BackColor = $BackColor}
        if ($ForeColor) {$Control.ForeColor = $ForeColor}
        if ($Bold -or $Italic -or $Strikeout -or $Underline) {$Font = "$Font,style="}
        if ($Bold) {$Font = "$Font,Bold"}
        if ($Italic) {$Font = "$Font,Italic"}
        if ($Strikeout) {$Font = "$Font,Strikeout"}
        if ($Underline) {$Font = "$Font,Underline"}
        $Control.Font = $Font
        if($Multiline){
            $Control.AutoSize = $true
        }
        Return $Control
    }
#endregion

# Connect Window

$frmConnect = New-Form -Text 'Connect to vCenter' -TopMost -Width 320 -Height 370

$lstServer = New-ListBox -Text 'Server List (Select One)' -Width 300 -Height 289 -Left 0 -Top 0
$btnConnect = New-Button -Text 'Connect' -Width 60 -Height 30 -Left 118 -Top 297

Add-Click -Control $btnConnect -Block $scriptConnect

Add-ListBoxItem -ListBox $lstServer -Items $ServerList

Add-Control -Form $frmConnect -Control $lstServer
Add-Control -Form $frmConnect -Control $btnConnect

Show-Form -Form $frmConnect
Remove-Form -Form $frmConnect



# --- Copy Window

$frmCopyVM = New-Form -Text 'Copy VM Folder' -TopMost -Width 820 -Height 500
$srcDatastore = New-ListBox -Text 'Src Datastore' -Width 220 -Height 400 -Left 15 -Top 45
$srcVMList = New-ListBox -Text 'Src VM' -Width 175 -Height 400 -Left 248 -Top 45
$dstDatastore = New-ListBox -Text 'Dst Datastore' -Width 220 -Height 400 -Left 560 -Top 45
$lblsrcDatastore = New-Label -Text 'Source Datastore' -AutoSize -Width 25 -Height 10 -Left 36 -Top 15
$lblsrcVMFolder = New-Label -Text 'Source VM Folder' -AutoSize -Width 25 -Height 10 -Left 279 -Top 15
$lbldstDatastore = New-Label -Text 'Destination Datastore' -AutoSize -Width 25 -Height 10 -Left 609 -Top 15
$btnCopy = New-Button -Text 'Copy ->' -Width 102 -Height 30 -Left 441 -Top 140

$datastores = Get-Datastore
$datastores | ForEach-Object {
    $srcDatastore.Items.Add($_.Name)
    $dstDatastore.Items.Add($_.Name)
}

$btnCopy.Add_Click({
    $src = Get-Item -Path "vmstore:\$($pathRoot.Name)\$($pathVIServer.Name)\$($srcVMList.SelectedItems[0])"
    $dst = $pathDatastore | Where-Object {$_.Name -like $($dstDatastore.SelectedItems[0])}
    Copy-DatastoreItem -Item $src -Destination $dst
})
$pathRoot = ''
$pathVIServer = ''
$pathDatastore = ''
$srcDatastore.Add_SelectedValueChanged({
    $pathRoot = Get-ChildItem -Path "vmstore:\"
    $pathVIServer = Get-ChildItem -Path "vmstore:\$($pathRoot.Name)\"
    $pathDatastore = Get-ChildItem -Path "vmstore:\$($pathRoot.Name)\$($pathVIServer.Name)\"
    $srcVMList.Items.Clear()
    $pathDatastore | ForEach-Object{
        $srcVMList.Items.Add($_.Name)
    }
})

Add-Control -Form $frmCopyVM -Control $srcDatastore
Add-Control -Form $frmCopyVM -Control $srcVMList
Add-Control -Form $frmCopyVM -Control $dstDatastore
Add-Control -Form $frmCopyVM -Control $lblsrcDatastore
Add-Control -Form $frmCopyVM -Control $lblsrcVMFolder
Add-Control -Form $frmCopyVM -Control $lbldstDatastore
Add-Control -Form $frmCopyVM -Control $btnCopy


Show-Form -Form $frmCopyVM
Remove-Form -Form $frmCopyVM


# --- Disconnect from vCenter Servers
$ServersConnectedTo | ForEach-Object {
    Disconnect-VIServer -Server [string]$_ -Confirm
}
