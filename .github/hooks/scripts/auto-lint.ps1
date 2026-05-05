# Post-tool-use hook: auto-lint after solution YAML edits
$input_json = $input | Out-String
if (-not $input_json) { exit 0 }
try { $data = $input_json | ConvertFrom-Json -ErrorAction Stop } catch { exit 0 }

$toolName = $data.toolName
if ($toolName -notin @('edit_file', 'create_file', 'insert_edit', 'replace_string')) { exit 0 }

$filePath = if ($data.toolInput.filePath) { $data.toolInput.filePath } elseif ($data.toolInput.path) { $data.toolInput.path } elseif ($data.toolInput.file) { $data.toolInput.file } else { '' }
if (-not $filePath) { exit 0 }
if ($filePath -notmatch '\.(yaml|yml)$') { exit 0 }
if ($filePath -notmatch '(scafctl[/\\]|solution\.yaml|actions\.yaml|tests\.yaml)') { exit 0 }

$result = & scafctl lint 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    @{ continue = $true; systemMessage = "Auto-lint found issues after editing ${filePath}:`n${result}`nFix these before proceeding." } | ConvertTo-Json -Compress | Write-Output
}
exit 0
