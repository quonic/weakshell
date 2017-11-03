# Does not seem to work as Windows.Devices.Bluetooth doesn't not exist.

Add-Type @'

using Windows.Devices.Bluetooth;

public static class Bluetooths{

    public static bool GetDevice(string Name)
    {
        // look for any paired device
        PeerFinder.AllowBluetooth = true;
        // start looking for BT devices
        PeerFinder.Start();
        PeerFinder.AlternateIdentities["Bluetooth:Paired"] = "";
        // get the list of paired devices
        var peers = await PeerFinder.FindAllPeersAsync();
        var peer = peers.First(p => p.DisplayName.Contains(Name));
    
        var bt = await BluetoothDevice.FromHostNameAsync(peer.HostName);
        if (bt.ConnectionStatus == BluetoothConnectionStatus.Connected)
        {
            return true;
        }
        return false;
    }
    
}
'@


