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
[long]$zeros = 0
[long]$dialpos = 50
[long]$tmp = 0
[long]$passZeros = 0

foreach ($line in $lines) {
    # parse line
    $s = $line.Trim()
    if ($s -eq '') { continue }
    if ($s -match '^([A-Za-z])\s*([+-]?\d+)$') {
        $letter = $matches[1]
        $num = [long]$matches[2]

        # add or subtract from dial position
        if (
            $letter -eq 'L') {
            $tmp = $num
            while (($dialpos % 100 -ne 0) -and ($tmp -gt $dialpos)) {
                $passZeros += 1
                $tmp -= 100
                write-output "ZeroPass Dial Pos: $dialpos clicks:< $num zeroPass : $passZeros Pwd: $zeros"
            }
            if (($num -ge $dialpos) -and (($dialpos - $num) % 100 -eq 0)) {
                $passZeros += 1
            } 
            $dialpos -= $num
        } elseif ($letter -eq 'R') {
            $tmp = $num
            while (($dialpos % 100 -ne 0) -and ($tmp -gt 100-$dialpos)) {
                $passZeros += 1
                $tmp -= 100
                write-output "ZeroPass Dial Pos: $dialpos clicks:> $num zeroPass : $passZeros Pwd: $zeros"
            }
            if (($num -ge 100-$dialpos) -and (($dialpos + $num) % 100 -eq 0)) {
                $passZeros += 1
            } 
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
            $zeros += 1
        }   
        write-output "Dial position : $dialpos clicks $letter : $num zeroPass : $passZeros Pwd: $zeros"

    } else {
        Write-Warning "Skipping non-matching line: '$line'"
    }
}


Write-Output "Lines: $($lines.Count)"
Write-Output "Zeros: $zeros"
Write-Output "PassZeros: $passZeros"
[long]$TOTAL = $zeros+$passZeros
Write-Output "TOTAL: $TOTAL"

# Example usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\Day1\script.ps1
#   or from PowerShell: .\Day1\script.ps1 -InputFile .\Day1\input.txt
