# Config
## ProcessName
$ProcessName = "SPACEPLAN"


$code = @' 
using System; 
using System.Runtime.InteropServices; 
 
public static class Keyboard{ 
     
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true, CallingConvention = CallingConvention.Winapi)] 
    public static extern short GetKeyState(int keyCode); 
     
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
}
'@

$signature = @"
	
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
"@


Add-Type $code

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

Write-Output "Starting Space Presser"
$quittime = $false

if (Get-process | Where-Object {$_.ProcessName -contains $ProcessName}) {
    Write-Output "$($ProcessName) found, waiting for Scroll Lock to be turned on..."
}
else {
    Write-Output "$($ProcessName) not found, waiting for $($ProcessName).exe to start..."
}

Write-Output "Turn on Caps Lock to quit."


do {

    $proc = Get-process | Where-Object {$_.ProcessName -contains $ProcessName}
    if ($proc.MainWindowHandle -eq (Get-ForgroundWindow)) {
        if ([Keyboard]::ScrollLock) {
            [System.Windows.Forms.SendKeys]::SendWait(" ")
            Start-Sleep -Milliseconds 10
        }
    }
    # If CapsLock is on quit
    if ([Keyboard]::CapsLock) {
        $quittime = $true
        Write-Output "Caps Lock on, quiting"
    }
}while ($quittime -eq $false)