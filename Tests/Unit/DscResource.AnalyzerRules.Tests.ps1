$script:ModuleName = (Get-Item $PSCommandPath).BaseName -replace '\.Tests'
$script:moduleRootPath = Join-Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) $script:ModuleName

# Need to import PSScriptAnalyzer to use the types.
if ( -not (Get-Module -Name PSScriptAnalyzer2) )
{
    Import-Module -Name PSScriptAnalyzer
}

Describe "$($script:ModuleName) Unit Tests" {
    BeforeAll {
        $modulePath = Join-Path -Path $script:moduleRootPath -ChildPath "$($script:ModuleName).psm1"
        Import-LocalizedData -BindingVariable localizedData -BaseDirectory $script:moduleRootPath -FileName "$($script:ModuleName).psd1"
    }

    Describe 'Measure-FunctionBlockBraces' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When a functions opening brace is on the same line as the function keyword' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something {
                        [CmdletBinding()]
                        [OutputType([System.Boolean])]
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [System.String]
                            $Variable1
                        )

                        return $true
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.FunctionOpeningBraceNotOnSameLine
            }
        }

        Context 'When two functions has opening brace is on the same line as the function keyword' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something {
                    }

                    function Get-SomethingElse {
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 2
                $record[0].Message | Should Be $localizedData.FunctionOpeningBraceNotOnSameLine
                $record[1].Message | Should Be $localizedData.FunctionOpeningBraceNotOnSameLine
            }
        }

        Context 'When function opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {   [CmdletBinding()]
                        [OutputType([System.Boolean])]
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [System.String]
                            $Variable1
                        )

                        return $true
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.FunctionOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When function opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {

                        [CmdletBinding()]
                        [OutputType([System.Boolean])]
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [System.String]
                            $Variable1
                        )

                        return $true
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.FunctionOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When function follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        [CmdletBinding()]
                        [OutputType([System.Boolean])]
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [System.String]
                            $Variable1
                        )

                        return $true
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-IfStatement' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When if-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true) {
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.IfStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When two if-statements has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true) {
                        }

                        if ($true) {
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 2
                $record[0].Message | Should Be $localizedData.IfStatementOpeningBraceNotOnSameLine
                $record[1].Message | Should Be $localizedData.IfStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When if-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true)
                        { return $true
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.IfStatementOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When if-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true)
                        {

                            return $true
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.IfStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When if-statement follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true)
                        {
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-ForEachStatement' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When foreach-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $myArray = @()
                        foreach ($stringText in $myArray) {
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.ForEachStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When foreach-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $myArray = @()
                        foreach ($stringText in $myArray)
                        {   $stringText
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.ForEachStatementOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When foreach-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $myArray = @()
                        foreach ($stringText in $myArray)
                        {

                            $stringText
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.ForEachStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When foreach-statement follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $myArray = @()
                        foreach ($stringText in $myArray)
                        {
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-DoUntilStatement' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When DoUntil-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 0

                        do {
                            $i++
                        } until ($i -eq 2)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.DoUntilStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When DoUntil-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 0

                        do
                        { $i++
                        } until ($i -eq 2)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.DoUntilStatementOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When DoUntil-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 0

                        do
                        {

                            $i++
                        } until ($i -eq 2)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.DoUntilStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When DoUntil-statement follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 0

                        do
                        {
                            $i++
                        } until ($i -eq 2)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-DoWhileStatement' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When DoWhile-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        do {
                            $i--
                        } while ($i -gt 0)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.DoWhileStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When DoWhile-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        do
                        { $i--
                        } while ($i -gt 0)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.DoWhileStatementOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When DoWhile-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        do
                        {

                            $i--
                        } while ($i -gt 0)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.DoWhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When DoWhile-statement follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        do
                        {
                            $i--
                        } while ($i -gt 0)
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-WhileStatement' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When While-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0) {
                            $i--
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.WhileStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When While-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        { $i--
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.WhileStatementOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When While-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        {

                            $i--
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.WhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When While-statement follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        {
                            $i--
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-SwitchStatement' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When Switch-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $value = 1

                        switch ($value) {
                            1
                            {
                                ''one''
                            }
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.SwitchStatementOpeningBraceNotOnSameLine
            }
        }

        # Regression test.
        Context 'When Switch-statement has an opening brace on the same line, and also has a clause with an opening brace on the same line' {
            It 'Should write only one error record, and the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $value = 1

                        switch ($value) {
                            1 { ''one'' }
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.SwitchStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When Switch-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $value = 1

                        switch ($value)
                        {   1
                            {
                                ''one''
                            }
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.SwitchStatementOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When Switch-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $value = 1

                        switch ($value)
                        {

                            1
                            {
                                ''one''
                            }
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.SwitchStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When Switch-statement follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $value = 1

                        switch ($value)
                        {
                            1
                            {
                                ''one''
                            }
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-TryStatement' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When Try-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try {
                            $value = 1
                        }
                        catch
                        {
                            throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.TryStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When Try-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try
                        { $value = 1
                        }
                        catch
                        {
                            throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.TryStatementOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When Try-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try
                        {

                            $value = 1
                        }
                        catch
                        {
                            throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.TryStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When Try-statement follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try
                        {
                            $value = 1
                        }
                        catch
                        {
                            throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Measure-CatchClause' {
        BeforeEach {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
        }

        Context 'When Catch-clause has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try
                        {
                            $value = 1
                        }
                        catch {
                            throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.CatchClauseOpeningBraceNotOnSameLine
            }
        }

        Context 'When Catch-clause opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try
                        {
                            $value = 1
                        }
                        catch
                        { throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.CatchClauseOpeningBraceShouldBeFollowedByNewLine
            }
        }

        Context 'When Catch-clause opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try
                        {
                            $value = 1
                        }
                        catch
                        {

                            throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.Count | Should BeExactly 1
                $record.Message | Should Be $localizedData.CatchClauseOpeningBraceShouldBeFollowedByOnlyOneNewLine
            }
        }

        Context 'When Catch-clause follow style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        try
                        {
                            $value = 1
                        }
                        catch
                        {
                            throw
                        }
                    }
                '

                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $record = `
                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should BeNullOrEmpty
            }
        }
    }
}
