


function Get-NumberRanges {
    <#
    .SYNOPSIS
        Extracts begin and end of number sequences (e.g., "824-1475") from a line of text.

    .DESCRIPTION
        Finds all patterns of "<number>-<number>" in a line, ignoring spaces.
        Returns objects with Start and End as [int64].
        Supports negative numbers and various separators around pairs (comma, space, semicolon).
    
    .PARAMETER Line
        The input line of text containing one or more ranges.

    .EXAMPLE
        Get-NumberRanges -Line "824-1475,967620-1012917"
        # Start End
        # ----- ---
        # 824   1475
        # 967620 1012917

    .EXAMPLE
        "  -10 - 20 ; 300- 400  " | Get-NumberRanges
        # Start End
        # ----- ---
        # -10   20
        # 300   400
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Line

        
        <# Read from literal path(s) (no wildcard expansion)
        [Parameter(
            ParameterSetName = 'ByLiteralPath',
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$LiteralPath
        #>
    )

    begin {
        # Regex explanation:
        # (?<!\w)          - ensure we're not inside a word (safer boundaries)
        # (-?\d+)          - first number (supports negative)
        # \s*-\s*          - hyphen with optional spaces around
        # (-?\d+)          - second number (supports negative)
        # (?!\w)           - ensure we're not inside a word
        $pattern = '(?<!\w)(-?\d+)\s*-\s*(-?\d+)(?!\w)'
    }
    process {
        if ([string]::IsNullOrWhiteSpace($Line)) { return }

        $lmatches = [regex]::Matches($Line, $pattern)
        foreach ($m in $lmatches) {
            # Convert to Int64 to handle large values safely
            [pscustomobject]@{
                Start = [int64]$m.Groups[1].Value
                End   = [int64]$m.Groups[2].Value
            }
        }
    }
}

function Test-DoubledDigitsRegex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('InputObject')]
        $Value,
        [switch]$ReturnUnit
    )
    process {
        $s = ($Value -as [string]).Trim()
        $m = [regex]::Match($s, '^(\d+)\1$')

        if ($ReturnUnit) {
            [pscustomobject]@{
                IsDoubled = $m.Success
                Unit      = if ($m.Success) { $m.Groups[1].Value } else { $null }
            }
        }
        else {
            $m.Success
        }
    }
}


function Test-RepeatedDigitUnit {
    <#
    .SYNOPSIS
        Tests if a value consists of a digit sequence repeated 2 or more times.

    .DESCRIPTION
        Returns $true / $false by default. If -ReturnDetails is used, returns an object
        with IsRepeated, Unit (the repeating sequence), and RepeatCount.
        Accepts numbers or strings. By default only digits are allowed; use -IgnoreSign
        to permit a leading '-' (which will be ignored for matching).

    .PARAMETER Value
        The number or string to test.

    .PARAMETER ReturnDetails
        Return structured details instead of a Boolean.

    .PARAMETER IgnoreSign
        Ignore a leading '-' sign (e.g., '-1212' is treated as '1212').

    .PARAMETER MinRepeats
        Minimum repeats required to count as positive (default 2).

    .EXAMPLE
        Test-RepeatedDigitUnit 121212           # True

    .EXAMPLE
        Test-RepeatedDigitUnit 111              # True

    .EXAMPLE
        Test-RepeatedDigitUnit 12               # False

    .EXAMPLE
        Test-RepeatedDigitUnit -Value 45674567 -ReturnDetails
        # IsRepeated Unit   RepeatCount
        # ---------- ----   -----------
        # True       4567   2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('InputObject')]
        $Value,

        [switch]$ReturnDetails,

        [switch]$IgnoreSign,

        [ValidateRange(2, [int]::MaxValue)]
        [int]$MinRepeats = 2
    )
    process {
        if ($null -eq $Value) {
            if ($ReturnDetails) { [pscustomobject]@{ IsRepeated = $false; Unit = $null; RepeatCount = 0 } }
            else { $false }
            return
        }

        # Normalize to string
        $s = ($Value -as [string]).Trim()
        if ($IgnoreSign -and $s.StartsWith('-')) { $s = $s.Substring(1) }

        # Must be only digits
        if ($s -notmatch '^\d+$') {
            if ($ReturnDetails) { [pscustomobject]@{ IsRepeated = $false; Unit = $null; RepeatCount = 0 } }
            else { $false }
            return
        }

        # Quick reject: length < 2 cannot be 2+ repeats
        if ($s.Length -lt 2) {
            if ($ReturnDetails) { [pscustomobject]@{ IsRepeated = $false; Unit = $null; RepeatCount = 0 } }
            else { $false }
            return
        }

        # Regex: group of digits repeated 2+ times
        $m = [regex]::Match($s, '^(\d+)\1+$')
        if (-not $m.Success) {
            if ($ReturnDetails) { [pscustomobject]@{ IsRepeated = $false; Unit = $null; RepeatCount = 0 } }
            else { $false }
            return
        }

            $unit = $m.Groups[1].Value
            $repeats = [int]($s.Length / $unit.Length)
            $ok = ($repeats -ge $MinRepeats)
            if ($ReturnDetails) {
                [pscustomobject]@{
                    IsRepeated  = $ok
                    Unit        = if ($ok) { $unit } else { $null }
                    RepeatCount = if ($ok) { $repeats } else { 0 }
                }
            }
            else {
                $ok
            }
        }
    }



$InputFile = (Join-Path $PSScriptRoot "input.txt")
if (-not (Test-Path $InputFile)) { throw "Input file not found: $InputFile" }

$firstLine = Get-Content -Path $InputFile -TotalCount 1

# Parse all ranges from a file and show results
$ranges = Get-NumberRanges -Line $firstLine 
$ranges | Format-Table -AutoSize    

$sum1 = 0
<#
# Process each range and find numbers with doubled digits
foreach ($r in $ranges) {
    $i=$r.Start
    while ($i -le $r.End) {
        # Process each number in the range
        # For demonstration, just output the number
        # Uncomment the next line to see all numbers (may be large)
        if (Test-DoubledDigitsRegex $i) {
            $sum1 += $i
        }
        $i++
    }
}
#>

$sum2 = 0
# Process each range and find numbers with doubled digits
foreach ($r in $ranges) {
    $i = $r.Start
    while ($i -le $r.End) {
        # Process each number in the range
        # For demonstration, just output the number
        # Uncomment the next line to see all numbers (may be large)
        if (Test-RepeatedDigitUnit $i) {
            $sum2 += $i
            write-output "Found repeated unit number: $i"
        }
        $i++
    }
}

write-output "Done1 : $sum1"
write-output "Done2 : $sum2"



