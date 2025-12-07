# Day 1 - Advent of Code
# PowerShell helper script

<#
.SYNOPSIS
Simple template for reading `input.txt` and computing example output.
#>
param(
    [string]$InputFile = (Join-Path $PSScriptRoot "input.txt")
)

if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

$lines = Get-Content $InputFile | Where-Object { $_ -ne "" }

# Example processing: parse lines of form LetterNumber (e.g. 'L68')
# Separate into a letters file and a numbers file, and compute sum of numbers
[long]$pwd = 0
[long]$dialpos = 50
[long]$tmp = 0

foreach ($line in $lines) {
    # parse line
    $s = $line.Trim()
    if ($s -eq '') { continue }
    if ($s -match '^([A-Za-z])\s*([+-]?\d+)$') {
        $letter = $matches[1]
        $num = [long]$matches[2]

        # add or subtract from dial position
        if ($letter -eq 'L') {
            $dialpos -= $num
        } elseif ($letter -eq 'R') {
            $dialpos += $num
        }
        # adjust dial position to wrap around 0-99
        while ($dialpos -lt 0) {
            $dialpos += 100
        } 
        while ($dialpos -ge 100) {
            $dialpos -= 100
        }
        # check dial position for zero or 100
        if ($dialpos % 100 -eq 0) {
            $pwd += 1
        }   
        write-output "Dial position : $dialpos clicks: $num Pwd: $pwd"

        $sum += $num
    } else {
        Write-Warning "Skipping non-matching line: '$line'"
    }
}


Write-Output "Lines: $($lines.Count)"
Write-Output "Pwd: $pwd"

# Example usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\Day1\script.ps1
#   or from PowerShell: .\Day1\script.ps1 -InputFile .\Day1\input.txt
