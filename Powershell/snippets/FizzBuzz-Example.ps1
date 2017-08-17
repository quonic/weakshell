# This is how I would approch FizzBuzz

Function FizzBuzz {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [int]$Number
    )
    Begin {
        $Fizz = "Fizz"
        $Buzz = "Buzz"
        $Both = "FizzBuzz"
    }
    Process {
        # For each item from the Pipeline or from $Number
        $result = switch ($Number) {
            # Is the current number a multiple of 3
            {$_ % 3 -eq 0} {
                $Fizz
            }
            # Is the current number a multiple of 5
            {$_ % 5 -eq 0} {
                $Buzz
            }
            # Is the current number NOT a multiple of 3 or 5
            default {
                $_
            }
        }
        # Is the current number a multiple of 3 and 5
        If ($result -is [array]) {
            $result = $Both
        }
        # Output the current number, Fizz, Buzz, or FizzBuzz
        $result
    }
}

# Test the above
$Test = $(1,
    2,
    "Fizz",
    4,
    "Buzz",
    "Fizz",
    7,
    8,
    "Fizz",
    "Buzz",
    11,
    "Fizz",
    13,
    14,
    "FizzBuzz")
If ((Compare-Object -ReferenceObject $Test -DifferenceObject $(1..15 | FizzBuzz)) -eq $null) {
    "Test passed!"
}
else {
    "Test failed!"
}