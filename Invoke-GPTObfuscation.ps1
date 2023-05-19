# This file is an interface to use Invoke-GPTObfuscation as a command line tool.
# It is not intended to be used as a module - instead use Invoke-GPTObfuscation.psm1

# Load the module from the file "Invoke-GPTObfuscation.psm1" or PWD
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$module_path = $script_dir + "/Invoke-GPTObfuscation.psm1"
if(-not (Test-Path $module_path)) {
    # Try PWD
    $module_path = $pwd.Path + "/Invoke-GPTObfuscation.psm1"
}
if((Test-Path $module_path)) {
    Invoke-Expression (Get-Content $module_path -Raw)
} else {
    Write-Host "[Error] Invoke-GPTObfuscation.psm1 not found in $script_dir" -ForegroundColor Red
    return;
}

$prompt_template_paths = @()

Get-ChildItem -Path $script_dir -Filter "*.prompt_tpl" -File | % {
    $prompt_template_paths += $_.FullName
}

if($prompt_template_paths.Count -eq 0) {
    Write-Host "[Error] No prompt templates (*.prompt_tpl) found in $script_dir" -ForegroundColor Red
    return;
}

# Provide a list of prompts to choose from (do while) and then continue on
write-host "Select a prompt template to use:"
Write-Host "Q. [Quit / Exit]"

$index = 0
$prompt_template_paths | % {
    $index++
    write-host "$index. $_"
}

$prompt_template_path = $null
do {
    $choice = Read-Host "Enter a number between 1 and $index"
    $choice = $choice.Trim().ToUpper()
    if($choice -eq 'Q') {
        write-host "Exiting"
        return;
    }
    $choice = [int]$choice
    if($choice -gt 0 -and $choice -le $index) {
        $prompt_template_path = $prompt_template_paths[$choice-1]
    }
    else {
        write-host "Invalid choice: $choice"
    }
} while($prompt_template_path -eq $null)

write-host "Using prompt template: $prompt_template_path"

# Get the script to obfuscate
write-host "How do you want to provide your script?"

# Ask until valid answer, or exit
$script_input_method = $null
do {
    # File (F) or Paste (P)
    $choice = Read-Host "Pick one of: [F]ile, [P]aste, [Q]uit"

    try {
        $choice = $choice.Trim().ToUpper().Substring(0,1) # Take the first character, upper case
    }
    catch {
        Write-Host "Invalid choice: $choice" -ForegroundColor Red
        continue;
    }

    if($choice -eq 'Q') {
        write-host "Exiting"
        return;
    }
    elseif($choice -eq 'F' -or $choice -eq 'P') {
        $script_input_method = $choice # Set the method
        break;
    }
    else {
        write-host "Invalid choice: $choice"
    }
} while($true)

Write-Host "Using input method: " (@("File", "Paste")|? { $_.Substring(0,1) -eq $script_input_method })

switch ($script_input_method) {
    'F' {
        # Get the file
        $script_file = Read-Host "Enter the path to the script file"
        if(Test-Path $script_file) {
            $script = Get-Content $script_file | Out-String
        }
        else {
            Write-Host "[Error] Script file not found: $script_file" -ForegroundColor Red
            return;
        }
    }
    'P' {
        # Get the script, multiple lines
        $script = @()
        do {
            $line = Read-Host "Enter a line of the script, or a single 'Q' to finish"
            if($line.Trim().ToUpper() -eq 'Q') {
                break;
            }
            $script += $line
        } while($true)
    }
}

# Sanity Check - make sure the script is valid
$script = $script.Trim()

# Count the number of non-white space characters
$script_length = ($script | Measure-Object -Character).Characters
if($script_length -eq 0) {
    Write-Host "[Error] Script is empty" -ForegroundColor Red
    return;
}
elseif($script_length -lt 100) {
    Write-Host "[Warning] Script is less than 100 characters long - Are you sure you want to continue? (Y/n)" -ForegroundColor Yellow
    $choice = Read-Host
    if($choice.Trim().ToUpper() -ne 'Y' -and $choice.Trim().ToUpper() -ne 'YES') {
        Write-Host "Exiting!"
        return;
    }
}
elseif($script_length -gt 10000) {
    Write-Host "[Warning] Script is greater than 10,000 characters long - Are you sure you want to continue? (Y/n)" -ForegroundColor Yellow
    $choice = Read-Host
    if($choice.Trim().ToUpper() -ne 'Y' -and $choice.Trim().ToUpper() -ne 'YES') {
        Write-Host "Exiting!"
        return;
    }
}

# Offer to save the script to a file if the input method was paste
if ($script_input_method -eq "P") {
    do {
        $choice = Read-Host "Do you want to save the script to a file? (Y/n)"
        if($choice.Trim().ToUpper() -eq 'Y' -or $choice.Trim().ToUpper() -eq 'YES') {
            $script_file = Read-Host "Enter the path to save the script file"
            if(Test-Path $script_file) {
                Write-Host "[Error] Script file already exists: $script_file" -ForegroundColor Red
                continue;
            }
            else {
                $script | Out-File $script_file
                Write-Host "Script saved to $script_file"
                break;
            }
        }
        else {
            break;
        }
    } while($true)
}

# Ask for the provider (disabled)
#$provider = Read-Host "Enter the provider to use ('OpenAI', )


# TODO: Instead, store a list of things to replace and get context for each, so variables are consistent.

# Okay, let's do this
$script_obfuscated = Invoke-GPTObfuscation -ScriptBlock $script -PromptTemplateFile $prompt_template_path -Verbose $true

# Output the obfuscated script
Write-Host "Obfuscated script:`n`n"
Write-Host $script_obfuscated -ForegroundColor Green
write-host "`n"
