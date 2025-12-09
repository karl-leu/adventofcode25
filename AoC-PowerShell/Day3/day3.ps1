

function Get-DigitStringsFromFile {
    [CmdletBinding()]
    param(
        # Path to the input text file
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        # Text encoding used by the file (default: UTF8 with BOM fallback)
        [ValidateSet('Unicode', 'UTF7', 'UTF8', 'UTF32', 'ASCII', 'BigEndianUnicode', 'Default', 'OEM')]
        [string]$Encoding = 'UTF8',

        # Trim whitespace from each line before processing
        [switch]$Trim,

        # Ignore empty lines (after trimming, if -Trim is set)
        [switch]$IgnoreEmpty,

        # Enforce that each (non-empty) line contains digits only (^\d+$)
        [switch]$ValidateDigitsOnly
    )

    begin {
        # Prepare a list to collect the results and return as [string[]]
        $result = New-Object System.Collections.Generic.List[string]
        $digitRegex = '^\d+$'
    }

    process {
        try {
            if (-not (Test-Path -LiteralPath $Path)) {
                throw "File not found: $Path"
            }

            # Read line by line to avoid large memory spikes on huge files
            $lines = Get-Content -LiteralPath $Path -Encoding $Encoding -ErrorAction Stop

            foreach ($line in $lines) {
                $current = if ($Trim) { $line.Trim() } else { $line }

                if ($IgnoreEmpty -and [string]::IsNullOrWhiteSpace($current)) {
                    continue
                }

                if ($ValidateDigitsOnly -and -not [string]::IsNullOrWhiteSpace($current)) {
                    if ($current -notmatch $digitRegex) {
                        throw "Non-digit content found: '$current'. Use -ValidateDigitsOnly:$false to allow."
                    }
                }

                # Only add non-null strings
                if ($null -ne $current) {
                    [void]$result.Add([string]$current)
                }
            }
        }
        catch {
            throw $_
        }
    }

    end {
        # Emit as an array of strings
        , $result.ToArray()
    }
}




function Get-TwoHighestDigits {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputNumber,

        # Optional: return only the two digits (omit indices and input)
        [switch]$DigitsOnly,

        # Optional: return indices as 1-based instead of 0-based
        [switch]$OneBasedIndex
    )

    process {
        # Normalize and validate
        $s = $InputNumber.Trim()

        if (-not ($s -match '^\d+$')) {
            throw "Input must contain digits only (0-9)."
        }
        if ($s.Length -gt 100) {
            throw "Input must be at most 100 digits long."
        }

        # First pass: highest digit (first occurrence from the left)
        $bestDigit = -1
        $bestIdx = -1
        for ($i = 0; $i -lt $s.Length; $i++) {
            $d = [int]::Parse($s[$i])  # robust digit conversion
            if ($d -gt $bestDigit) {
                $bestDigit = $d
                $bestIdx = $i
                if ($bestDigit -eq 9) { break } # can't beat 9
            }
        }

        # Second pass: next highest digit, skipping the index of the first
        $secondDigit = -1
        $secondIdx = -1
        for ($i = 0; $i -lt $s.Length; $i++) {
            $d = [int]::Parse($s[$i])  # robust digit conversion
            if (($d -gt $secondDigit) -and ($i -ne $bestIdx)) {   
                $secondDigit = $d
                $secondIdx = $i
                if ($secondDigit -eq 9) { break } # can't beat 9
            }
        }

        [pscustomobject]@{
           Input       = $s
           FirstDigit  = $bestDigit
           FirstIndex  = $bestIdx
           SecondDigit = $secondDigit
           SecondIndex = $secondIdx
        }
    }
}


$InputFile = (Join-Path $PSScriptRoot "test.txt")
if (-not (Test-Path $InputFile)) { throw "Input file not found: $InputFile" }

$batteries = Get-DigitStringsFromFile -Path $InputFile 
$batteries | Format-Table -AutoSize    

$sum1 = 0
foreach ($battery in $batteries) {
    $res = Get-TwoHighestDigits -InputNumber $battery
    Write-Output $res
    $joltage = $res.FirstDigit * 10 + $res.SecondDigit;
    $sum1 += $joltage
}

write-output "Done1 : $sum1"



