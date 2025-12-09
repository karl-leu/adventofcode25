
param(
    [string]$InputFile = (Join-Path $PSScriptRoot "input.txt")
)

if (-not (Test-Path $InputFile)) { throw "Input file not found: $InputFile" }

[int]$DIAL = 100
[int]$pos  = 50
[int]$part1 = 0
[int]$part2 = 0

function Get-CrossingsRight([int]$p, [int]$s) {
    return [int][math]::Floor(($p + $s) / 100.0)
}
function Get-CrossingsLeft([int]$p, [int]$s) {
    $first = if ($p -gt 0) { $p } else { 100 }
    if ($s -lt $first) { return 0 }
    return 1 + [int][math]::Floor(($s - $first) / 100.0)
}

Get-Content $InputFile | Where-Object { $_ -match '^[LR]\s*(\d+)$' } | ForEach-Object {
    $dir   = $_[0]                 # 'L' or 'R'
    $steps = [int]$Matches[1]

    if ($dir -eq 'R') {
        $part2 += Get-CrossingsRight -p $pos -s $steps
        $pos = $pos + $steps
    } else {
        $part2 += Get-CrossingsLeft  -p $pos -s $steps
        $pos = $pos - $steps
    }

    # wrap into 0..99
    $pos = $pos % $DIAL
    if ($pos -lt 0) { $pos += $DIAL }

    if ($pos -eq 0) { $part1++ }
}

"Part1 (land on 0): $part1"
"Part2 (all 0 touches): $part2"
