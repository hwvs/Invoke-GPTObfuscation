<#
    .Synopsis
        Obfuscate PowerShell code using the Invoke-GPOObfuscation function.
    .Description
        This function will obfuscate PowerShell code using the Invoke-GPOObfuscation function.
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

    .Example
        Invoke-GPOObfuscation -ScriptBlock {$str = "Hello World!"; Write-Host $str}
#>

# Virtual class to override
class AIProvider {
    [hashtable] $Settings = @{}

    AIProvider($new_settings) {
        foreach($Settings in $new_settings.Keys) {
            $this.SetSetting($Settings, $new_settings[$Settings])
        }
    }

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

    [string] GenerateCompletion([string] $prompt, [string] $script) {
        throw "NotImplemented"
    }
}

# OpenAI class
class OpenAIProvider {
    # GenerateCompletion impl
    [string] GenerateCompletion([string] $prompt, [string] $script) {
        $API_KEY = $this.GetSetting("APIKey", $env:OPENAI_API_KEY)
        if($API_KEY -eq $null -or $API_KEY -eq "") {
            throw "No API key provided for OpenAI"
        }
        $headers = @{"Authorization" = "Bearer $API_KEY"}
        $body = @{
            "prompt" = $prompt
            "max_tokens" = $this.GetSetting("MaxTokens", 1024)
            "temperature" = $this.GetSetting("Temperature", 0.1)
            "top_p" = 1.0
            "n" = 1
            "stream" = $false
            "logprobs" = $null
            "stop" = $this.GetSetting("StopSeqs", @('---','```'))
        }
        $body = $body | ConvertTo-Json
        $response = Invoke-RestMethod -Method Post -Uri "https://api.openai.com/v1/engines/davinci/completions" -Headers $headers -Body $body
        return $response.choices[0].text
    }

}

function Invoke-GPOObfuscation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,
        [Parameter(Mandatory=$false)]
        [string]
        $PromptTemplateFile,
        [Parameter(Mandatory=$false)]
        [string]
        $PromptTemplate,
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
        $AIProvider = $null,
        [Parameter(Mandatory=$false)]
        [string]
        $AIProviderKey = $env:OPENAI_API_KEY
    )

    if($AIProvider -eq $null) {
        $AIProvider = New-Object 'AIProvider' $AIProviderSettings
        
    }

    # Validate the script block
    $script = $ScriptBlock.ToString()
    $script = $script.Trim()
    $script = $script.TrimStart("{")
    $script = $script.TrimEnd("}")
    $script = $script.Trim()

    # Validate the prompt template file
    if($PromptTemplateFile -ne $null -and $PromptTemplateFile -ne "") {
        if(Test-Path $PromptTemplateFile) {
            $PromptTemplate = Get-Content $PromptTemplateFile | Out-String
        }
        else {
            Write-Host "[Error] Prompt template file not found: $PromptTemplateFile" -ForegroundColor Red
            return;
        }
    }

    # Validate the prompt template
    if($PromptTemplate -eq $null -or $PromptTemplate -eq "") {
        Write-Host "[Error] No prompt template provided" -ForegroundColor Red
        return;
    }

    # Validate the prompt settings
    if($PromptSettings -eq $null) {
        $PromptSettings = @{}
    }

    # Validate the AI provider
    if($AIProvider -eq "OpenAI") {
        if($AIProviderKey -eq $null -or $AIProviderKey -eq "") {
            Write-Host "[Error] No API key provided for OpenAI" -ForegroundColor Red
            return;
        }
    }

}