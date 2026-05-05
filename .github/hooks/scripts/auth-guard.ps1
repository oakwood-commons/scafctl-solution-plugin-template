# Pre-tool-use hook: block non-scafctl auth commands
$input_json = $input | Out-String
if (-not $input_json) { exit 0 }
try { $data = $input_json | ConvertFrom-Json -ErrorAction Stop } catch { exit 0 }

if ($data.toolName -notin @('run_in_terminal', 'run_command', 'terminal')) { exit 0 }

$command = if ($data.toolInput.command) { $data.toolInput.command } else { '' }
if (-not $command) { exit 0 }

$blocked = @('az login', 'az account', 'gcloud auth login', 'gcloud auth application-default', 'aws configure', 'aws sso login')
foreach ($pattern in $blocked) {
    if ($command -match [regex]::Escape($pattern)) {
        @{ hookSpecificOutput = @{ hookEventName = "PreToolUse"; permissionDecision = "deny"; permissionDecisionReason = "Use 'scafctl auth login <handler>' instead of '${pattern}'. scafctl manages authentication." } } | ConvertTo-Json -Depth 3 -Compress | Write-Output
        exit 0
    }
}
exit 0
