# Config
## ProcessName
$ProcessName = "Boundless"


Add-Type @"
using System; 
using System.Runtime.InteropServices; 
 
public static class Keyboard{ 
     
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true, CallingConvention = CallingConvention.Winapi)] 
    public static extern short GetKeyState(int keyCode);

    [DllImport("user32.dll", SetLastError = true)]
    static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo); 
    
    public const int KEYEVENTF_EXTENDEDKEY = 0x0001; //Key down flag
    public const int KEYEVENTF_KEYUP = 0x0002; //Key up flag
    public const int VK_W = 0x57; //W key code
     
    public static bool Numlock{ 
        get{ 
            return (((ushort)GetKeyState(0x90)) & 0xffff) != 0; 
        } 
    } 
     
     public static bool CapsLock{ 
         get{
            return (((ushort)GetKeyState(0x14)) & 0xffff) != 0;
        }
     }
    
    public static bool ScrollLock{
        get{
            return (((ushort)GetKeyState(0x91)) & 0xffff) != 0;
        }
    }
    
    public static void MoveForward(){
        keybd_event(VK_W, 0, KEYEVENTF_EXTENDEDKEY, 0);
    }

    public static void StopMoveForward(){
        keybd_event(VK_W, 0, KEYEVENTF_KEYUP, 0);
    }
}
"@

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Mouse
{
    [Flags]
    public enum MouseEventFlags
    {
        LeftDown = 0x00000002,
        LeftUp = 0x00000004,
        MiddleDown = 0x00000020,
        MiddleUp = 0x00000040,
        Move = 0x00000001,
        Absolute = 0x00008000,
        RightDown = 0x00000008,
        RightUp = 0x00000010
    }

    [DllImport("user32.dll", EntryPoint = "SetCursorPos")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetCursorPos(int X, int Y);      

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetCursorPos(out MousePoint lpMousePoint);

    [DllImport("user32.dll")]
    private static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

    public static void SetCursorPosition(int X, int Y) 
    {
        SetCursorPos(X, Y);
    }

    public static void SetCursorPosition(MousePoint point)
    {
        SetCursorPos(point.X, point.Y);
    }

    public static MousePoint GetCursorPosition()
    {
        MousePoint currentMousePoint;
        var gotPoint = GetCursorPos(out currentMousePoint);
        if (!gotPoint) { currentMousePoint = new MousePoint(0, 0); }
        return currentMousePoint;
    }

    public static void MouseEvent(MouseEventFlags value)
    {
        MousePoint position = GetCursorPosition();
        mouse_event((int)value,position.X,position.Y,0,0);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MousePoint
    {
        public int X;
        public int Y;
        public MousePoint(int x, int y)
        {
            X = x;
            Y = y;
        }
    }
}
"@

$signature = @'
	
	[DllImport("user32.dll")]  
	public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);  
	public static IntPtr FindWindow(string windowName){
		return FindWindow(null,windowName);
	}
	[DllImport("user32.dll")]
	public static extern bool SetWindowPos(IntPtr hWnd, 
	IntPtr hWndInsertAfter, int X,int Y, int cx, int cy, uint uFlags);
	[DllImport("user32.dll")]  
	public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); 
	static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
	static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);
	const UInt32 SWP_NOSIZE = 0x0001;
	const UInt32 SWP_NOMOVE = 0x0002;
	const UInt32 TOPMOST_FLAGS = SWP_NOMOVE | SWP_NOSIZE;
	public static void MakeTopMost (IntPtr fHandle)
	{
		SetWindowPos(fHandle, HWND_TOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS);
	}
	public static void MakeNormal (IntPtr fHandle)
	{
		SetWindowPos(fHandle, HWND_NOTOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS);
	}
'@

$app = Add-Type -MemberDefinition $signature -Name Win32Window -Namespace ScriptFanatic.WinAPI -ReferencedAssemblies System.Windows.Forms -Using System.Windows.Forms -PassThru

Add-Type @"
  using System; 
  using System.Runtime.InteropServices; 
  public class UserWindows { 
    [DllImport("user32.dll")] 
    public static extern IntPtr GetForegroundWindow(); 
} 
"@

function Get-ForgroundWindow {
    return [UserWindows]::GetForegroundWindow()
}

function Get-WindowByTitle($WindowTitle = "*") {
    Write-Verbose "WindowTitle is: $WindowTitle"
	
    if ($WindowTitle -eq "*") {
        Write-Verbose "WindowTitle is *, print all windows title"
        Get-Process | Where-Object {$_.MainWindowTitle} | Select-Object Id, Name, MainWindowHandle, MainWindowTitle
    }
    else {
        Write-Verbose "WindowTitle is $WindowTitle"
        Get-Process | Where-Object {$_.MainWindowTitle -like "*$WindowTitle*"} | Select-Object Id, Name, MainWindowHandle, MainWindowTitle
    }
}

add-type -AssemblyName Microsoft.VisualBasic

add-type -AssemblyName System.Windows.Forms

"Starting Click and Move"
$found = $false
$quittime = $false
$mousedown = $false

if (Get-process | Where-Object {$_.ProcessName -contains $ProcessName}) {
    "$($ProcessName) found, waiting for Scroll Lock to be turned on..."
}
else {
    "$($ProcessName) not found, waiting for $($ProcessName).exe to start..."
}

"Turn on Caps Lock to quit."


do {

    $proc = Get-process | Where-Object {$_.ProcessName -contains $ProcessName}
    if (-not $proc) {
        $found = $false
    }
    elseif ($proc.MainWindowHandle -eq (Get-ForgroundWindow)) {
        if ([Keyboard]::ScrollLock) {
            [Keyboard]::MoveForward()
            if(-not $mousedown){
                [Mouse]::MouseEvent([Mouse+MouseEventFlags]::LeftDown)
            }
            Start-Sleep -Milliseconds 10
        }elseif($mousedown -and -not [Keyboard]::ScrollLock){
            [Keyboard]::StopMoveForward()
            if($mousedown){
                [Mouse]::MouseEvent([Mouse+MouseEventFlags]::LeftDown)
                Start-Sleep -Milliseconds 20
                [Mouse]::MouseEvent([Mouse+MouseEventFlags]::LeftUp)
            }
        }
        $found = $true
    }
    # If CapsLock is on quit
    if ([Keyboard]::CapsLock) {
        $quittime = $true
        if($mousedown){
            [Mouse]::MouseEvent([Mouse+MouseEventFlags]::LeftUp)
        }
        "Caps Lock on, quiting"
    }
}while ($quittime -eq $false)