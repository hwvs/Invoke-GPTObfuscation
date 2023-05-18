$prompt_templates = @()

$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-ChildItem -Path $script_dir -Filter "*.prompt_tpl" -File | % {
    $prompt_templates += $_.FullName
}

if($prompt_templates.Count -eq 0) {
    Write-Host "[Error] No prompt templates (*.prompt_tpl) found in $script_dir" -ForegroundColor Red
    return;
}

# Provide a list of prompts to choose from (do while) and then continue on
write-host "Select a prompt template to use:"

$index = 0
$prompt_templates | % {
    $index++
    write-host "$index. $_"
}

$prompt_template = $null
do {
    $choice = Read-Host "Enter a number between 1 and $index"
    $choice = [int]$choice
    if($choice -gt 0 -and $choice -le $index) {
        $prompt_template = $prompt_templates[$choice-1]
    }
    else {
        write-host "Invalid choice: $choice"
    }
} while($prompt_template -eq $null)

write-host "Using prompt template: $prompt_template"