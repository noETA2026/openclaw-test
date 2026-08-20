# Bad Apple ASCII Animation → Discord Player (NO rate limit)
# Usage: .\badapple-play.ps1 <frames.txt> <bot_token> <channel_id>

param(
    [Parameter(Mandatory=$true)][string]$File,
    [Parameter(Mandatory=$true)][string]$Token,
    [Parameter(Mandatory=$true)][string]$Channel
)

$raw = [IO.File]::ReadAllText($File)
$frames = $raw -split 'SPLIT' | ForEach-Object { $_.TrimEnd() } | Where-Object { $_.Length -gt 0 }

Write-Host "Frames: $($frames.Count) - NO rate limit (full speed)"
Write-Host "Starting in 3s..."
Start-Sleep -Seconds 3

$sent = 0; $skip = 0; $err = 0; $i = 0; $prev = ''

foreach ($f in $frames) {
    $i++
    if ($f -eq $prev) { $skip++; continue }
    $prev = $f

    $art = $f -replace '\$', ' '
    $msg = "```````n$art```````"

    if ($msg.Length -gt 2000) { $err++; continue }

    $body = @{ content = $msg } | ConvertTo-Json -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($body)

    try {
        Invoke-RestMethod `
            -Uri "https://discord.com/api/v10/channels/$Channel/messages" `
            -Method Post `
            -Headers @{ Authorization = "Bot $Token"; 'Content-Type' = 'application/json' } `
            -Body $bytes `
            -ErrorAction Stop
        $sent++
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 429) {
            $r = $_.ErrorDetails.Message | ConvertFrom-Json
            Start-Sleep -Milliseconds ([math]::Ceiling($r.retry_after * 1000))
            try {
                Invoke-RestMethod `
                    -Uri "https://discord.com/api/v10/channels/$Channel/messages" `
                    -Method Post `
                    -Headers @{ Authorization = "Bot $Token"; 'Content-Type' = 'application/json' } `
                    -Body $bytes `
                    -ErrorAction Stop
                $sent++
            } catch { $err++ }
        } else { $err++ }
    }

    if ($i % 50 -eq 0) {
        Write-Host "[$i] sent:$sent skip:$skip err:$err"
    }
}

Write-Host "`nDone! sent:$sent skip:$skip err:$err"
