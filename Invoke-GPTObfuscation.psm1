<#
    .Synopsis
        Obfuscate PowerShell code using the Invoke-GPTObfuscation function.
    .Description
        This function will obfuscate PowerShell code using the Invoke-GPTObfuscation function.
    .Parameter ScriptCode
        The script block to obfuscate.
    .Parameter PromptTemplateFile
        The prompt template to use. This is a file with a .prompt_tpl extension.
    .Parameter PromptTemplate
        The prompt template to use. This is a string containing the prompt template.
    .Parameter PromptSettings
        A hashtable containing variables to use in the prompt template.
    .Parameter ShouldSplit 
        Optional. If true, the script will be split into multiple parts if it is too long to fit into a single prompt. Defaults to false.
    .Parameter SplitSize
        Optional. The maximum size of each split. Defaults to 1000.
    .Parameter AIProviderSettings
        A hashtable containing settings for the AI provider.
    .Parameter AIProvider
        Optional. The AI provider to use. Defaults to "OpenAI".
    .Parameter AIProviderKey
        Optional. The API key for the AI provider. Defaults to the environment variable OPENAI_API_KEY.
    .Parameter Verbose
        Optional. If true, verbose output will be displayed. Defaults to true.

    .Example
        Invoke-GPTObfuscation -ScriptBlock {$str = "Hello World!"; Write-Host $str}
#>
function Invoke-GPTObfuscation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [object]
        $ScriptBlock,

        [Parameter(Mandatory=$false)]
        [string]
        $PromptTemplateFile = '',

        [Parameter(Mandatory=$false)]
        [string]
        $PromptTemplate = '',

        [Parameter(Mandatory=$false)]
        [hashtable]
        $PromptSettings,
        [Parameter(Mandatory=$false)]
        [bool]
        $ShouldSplit = $false,
        [Parameter(Mandatory=$false)]
        [int]
        $SplitSize = 1000,
        [Parameter(Mandatory=$false)]
        [hashtable]
        $AIProviderSettings,
        [Parameter(Mandatory=$false)]
        [string]
        $AIProvider = 'OpenAI',
        [Parameter(Mandatory=$false)]
        [string]
        $AIProviderKey = ''
    )

    # Default to verbose output
    if($Verbose -eq $null) {
        $Verbose = $true
    }

    if($PromptTemplate -eq $true) {
        $PromptTemplate = '' #weird
    }
    if($PromptTemplateFile -eq $true) {
        $PromptTemplateFile = ''#weird
    }

    # Cannot pass a file and template string at the same time
    if(($PromptTemplateFile -ne $null -and $PromptTemplateFile.Length -gt 0) -and ($PromptTemplate -ne $null -and $PromptTemplate.Length -gt 0)) {
        throw "Cannot pass a file and template string at the same time (ambiguous): $PromptTemplateFile, $PromptTemplate"
        return;
    }
    elseif($PromptTemplateFile -eq $null -or $PromptTemplateFile.Length -eq 0) {
        if($PromptTemplate -eq $null -or $PromptTemplate.Length -eq 0) {
            throw "Must pass a file or template string"
            return;
        }
    }

    $AIProviderObj = $null
    if($AIProvider -eq $null -or $AIProvider -eq '' -or $AIProvider -eq 'OpenAI') { # Default to OpenAI
        $AIProviderObj = [OpenAIProvider]::new()
    }
    else {
        # Not implemented yet
        throw "AI provider not implemented yet: $AIProvider"
        return;
    }

    # Initialize AI provider
    #Set setting for each
    if($AIProviderSettings -ne $null) {
        foreach($setting in $AIProviderSettings.Keys) {
            $AIProviderObj.$setting = $AIProviderSettings[$setting]
        }
    }

    # Set the API key if param is set
    if($AIProviderKey -ne $null -and $AIProviderKey -ne "") {
        $AIProviderObj.SetSetting("APIKey", $AIProviderKey)
    }

    
    if($ScriptBlock -isnot [string] -and $ScriptBlock -isnot [System.Management.Automation.ScriptBlock] -and $ScriptBlock -isnot [array]) {
        throw "ScriptBlock must be either a string or System.Management.Automation.ScriptBlock"
        return;
    }

    if ($ScriptBlock -is [System.Management.Automation.ScriptBlock]) {
        $script = $ScriptBlock.ToString()
        $script = $script.Trim()
    }
    else {
        $script = $ScriptBlock
    }
    
    $PromptTemplateContent = $null

    # Validate the prompt template file
    if($PromptTemplateFile -ne $null -and $PromptTemplateFile -ne "") {
        write-host "PromptTemplateFile: $PromptTemplateFile" -ForegroundColor Cyan
        if((Test-Path $PromptTemplateFile)) {
            $PromptTemplateContent = (Get-Content $PromptTemplateFile) | Out-String
        }
        else {
            throw "Prompt template file not found: $PromptTemplateFile"
            return;
        }
    }
    else {
        $PromptTemplateContent = $PromptTemplate
    }

    # Validate the prompt template
    if($PromptTemplateContent -eq $null -or $PromptTemplateContent -eq "") {
        if($Verbose) {
            Write-Error "[Error] No prompt template provided"
        }
        else {
            throw "No prompt template provided"
        }
        return;
    }

    # Validate the prompt settings
    if($PromptSettings -eq $null) {
        $PromptSettings = @{}
    }

    # Validate the AI provider
    if($AIProvider -eq "OpenAI") {
        if($AIProviderKey -eq $null -or $AIProviderKey -eq "") {
            # Check for environment variable
            $AIProviderKey = $env:OPENAI_API_KEY
            if($AIProviderKey -ne $null -and $AIProviderKey.Length -gt 0) {
                if($Verbose) {
                    Write-Host "Using API key from environment variable OPENAI_API_KEY" -ForegroundColor Cyan
                }
            }
            else {
                if($Verbose) {
                    Write-Error "[Error] No API key provided for OpenAI (set the OPENAI_API_KEY environment variable or pass the parameter AIProviderKey)"
                }
                else {
                    throw "No API key provided for OpenAI"
                }
                return;
            }
        }
    }



    # Split the script into blocks
    if(-not $ShouldSplit) {
        $SplitSize = 99999999; # large number
    }
    $script_blocks =  Split-ScriptIntoBlocks -script $script -max_block_length $SplitSize -Verbose:$Verbose


    # Write what we have 
    if($Verbose) {
        $total_length = $script_blocks | Measure-Object -Sum Length | Select-Object -ExpandProperty Sum
        Write-Host "Blocks: $($script_blocks.Count), Total length: $total_length"
    }

    $result = @()
    #  generate the completion
    foreach($block in $script_blocks) {
        
        # Generate the prompt
        $prompt = $PromptTemplateContent
        foreach($setting in $PromptSettings.Keys) {
            $prompt = $prompt.Replace("{{" + $setting + "}}", $PromptSettings[$setting])
        }
        # Replace {{SCRIPT_INPUT}}
        $prompt = $prompt.Replace("{{SCRIPT_INPUT}}", (($block -Join "") | Out-String))

        $completion = $AIProviderObj.GenerateCompletion($prompt)
        $result += @($completion)
    }

    return ($result -Join "`n").Trim()


}


function Split-ScriptIntoBlocks($script, [int]$max_block_length = 2000, [bool]$Verbose = $true) {
    
    # Split the script into lines and remove carriage returns (if any)
    if($script -isnot [array]) { # If the script is a single object, split it into lines
        $script = $script -split "`n"
    }

    # Split into blocks of (up-to) 2000 characters, line-by-line #TODO: Make this configurable. Make this take {} into account. Take block comments into account.
    $script_blocks = @()

    $current_block = ""
    $script | % {
        # print a warning if the line is too long
        if($_.Length -gt $max_block_length) {
            Write-Host "[Warning] Line is longer than $max_block_length characters: $_" -ForegroundColor Yellow
        }

        # If the block is empty, add the line
        if($current_block.Length -eq 0) {
            $current_block = $_
            return; # Skip to the next line
        }

        # If the block is too long, add the block to the list and start a new block
        if($current_block.Length + $_.Length -gt $max_block_length) {
            $script_blocks += $current_block
            $current_block = $_
        }
        # Otherwise, add the line to the block
        else {
            $current_block += $_
        } 
    }

    # Add the last block to the list
    if($current_block.Length -gt 0) {
        $script_blocks += $current_block
    }

    # Remove empty blocks
    $script_blocks = $script_blocks | ? { $_.Length -gt 0 }


    # Print the number of blocks
    if($script_blocks.Count -eq 1) {
        
    }
    elseif ($script_blocks.Count -eq 0) {
        if($Verbose) {
            Write-Error "[Error] No script blocks found (This shouldn't happen??)" 
        }
        else {
            throw "No script blocks found (This shouldn't happen??)"
        }
        return;
    }
    else {
        Write-Host "[Warning] Script split into $($script_blocks.Count) blocks" -ForegroundColor Yellow
        Write-Host "This is not properly supported yet, so the script will most likely be broken due to missing context." -ForegroundColor Yellow
    }

    return $script_blocks
            
}




# Virtual class to override
class AIProvider {
    [hashtable] $Settings = @{}

    [void] SetSetting([string] $name, [object] $value) {
        $this.Settings[$name] = $value
    }

    [object] GetSetting([string] $name, [object] $default = $null) {
        if($this.Settings.ContainsKey($name)) {
            return $this.Settings[$name]
        }
        else {
            if($default -eq $null) {
                throw "Setting not found: $name"
            }
            return $default
        }
    }

    [string] GenerateCompletion([string] $prompt) {
        throw "NotImplemented"
    }
}

# OpenAI class
class OpenAIProvider : AIProvider {


    # GenerateCompletion impl
    [string] GenerateCompletion([string] $prompt) {

        if($prompt -eq 'True') {
            throw "Error, `$prompt is 'True', this is not right."
            return $null;
        }

        $API_KEY = $this.GetSetting("APIKey", $env:OPENAI_API_KEY)
        if($API_KEY -eq $null -or $API_KEY -eq "") {
            throw "No API key provided for OpenAI"
        }
        $headers = @{
            "Authorization" = "Bearer $API_KEY"
            "Content-Type" = "application/json"
        }


        $model = $this.GetSetting("Model", 'text-davinci-003')
        $max_tokens = $this.GetSetting("MaxTokens", 1500)
        $temperature = $this.GetSetting("Temperature", 0.1)
        $stop = $this.GetSetting("StopSeqs", @('---','```'))

        
        $request_body = @{
            "model" = $model
            "prompt" = $prompt
            "temperature" = $temperature
            "max_tokens" = $max_tokens
            "stop" = $stop

            "stream"=$false
            "top_p"=1
            "n"=1
        } | ConvertTo-Json

        # Get the response
        $endpoint_uri = 'https://api.openai.com/v1/completions'
        
        write-verbose "Sending request to $endpoint_uri"
        write-verbose "Request body: $request_body"
        write-verbose "Headers: $headers"

        $response = Invoke-RestMethod -Uri $endpoint_uri -Method Post -Headers $headers -Body $request_body
        
        # Check for error
        if($response.choices -eq $null -or $response.choices.Count -eq 0) {
            throw "No response from OpenAI"
        }

        write-verbose "Response: $($response | convertto-json)"

        return (($response.choices | % { $_.text } ) -Join "")

    }

}