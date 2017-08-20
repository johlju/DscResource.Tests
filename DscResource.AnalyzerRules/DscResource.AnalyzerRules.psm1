#Requires -Version 4.0

# Import helper module
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'DscResource.AnalyzerRules.Helper.psm1')

# Import Localized Data
Import-LocalizedData -BindingVariable localizedData

$script:diagnosticRecordType = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord'
$script:diagnosticRecord = @{
    Message  = ''
    Extent   = $null
    RuleName = $PSCmdlet.MyInvocation.InvocationName
    Severity = 'Warning'
}

<#
.SYNOPSIS
    Validates the [Parameter()] attribute for each parameter.

.DESCRIPTION
    All parameters in a param block must contain a [Parameter()] attribute
    and it must be the first attribute for each parameter and must start with
    a capital letter P. If it also contains the mandatory attribute, then the
    mandatory attribute must be formatted correctly.

.EXAMPLE
    Measure-ParameterBlockParameterAttribute -ScriptBlockAst $ScriptBlockAst

.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]

.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

.NOTES
    None
#>
function Measure-ParameterBlockParameterAttribute
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    Process
    {
        $results = @()

        try
        {
            $diagnosticRecordType = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord'

            $findAllFunctionsFilter = {
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }

            $findAllParametersFilter = {
                $args[0] -is [System.Management.Automation.Language.ParamBlockAst]
            }

            [System.Management.Automation.Language.Ast[]] $functionsAst = $ScriptBlockAst.FindAll( $findAllFunctionsFilter, $true )

            foreach ($functionAst in $functionsAst)
            {
                [System.Management.Automation.Language.Ast[]] $parametersAst = $functionAst.FindAll( $findAllParametersFilter, $true ).Parameters

                foreach ($parameterAst in $parametersAst)
                {
                    if ($parameterAst.Attributes.TypeName.FullName -notcontains 'parameter')
                    {
                        $results += New-Object `
                            -Typename $diagnosticRecordType `
                            -ArgumentList @(
                            $localizedData.ParameterBlockParameterAttributeMissing, `
                                $parameterAst.Extent, `
                                $PSCmdlet.MyInvocation.InvocationName, `
                                'Warning', `
                                $null
                        )
                    }
                    elseif ($parameterAst.Attributes[0].Typename.FullName -ne 'parameter')
                    {
                        $results += New-Object `
                            -Typename $diagnosticRecordType `
                            -ArgumentList @(
                            $localizedData.ParameterBlockParameterAttributeWrongPlace, `
                                $parameterAst.Extent, `
                                $PSCmdlet.MyInvocation.InvocationName, `
                                'Warning', `
                                $null
                        )
                    }
                    elseif ($parameterAst.Attributes[0].Typename.FullName -cne 'Parameter')
                    {
                        $results += New-Object `
                            -Typename $diagnosticRecordType  `
                            -ArgumentList @(
                            $localizedData.ParameterBlockParameterAttributeLowerCase, `
                                $parameterAst.Extent, `
                                $PSCmdlet.MyInvocation.InvocationName, `
                                'Warning', `
                                $null
                        )
                    } # if
                } # foreach parameter
            } # foreach function

            return $results
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the function block braces and new lines around braces.

    .DESCRIPTION
        Each function should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-FunctionBlockBraces -FunctionDefinitionAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.FunctionDefinitionAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-FunctionBlockBraces
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.FunctionDefinitionAst]
        $FunctionDefinitionAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $FunctionDefinitionAst.Extent

            $testParameters = @{
                StatementBlock = $FunctionDefinitionAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.FunctionOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.FunctionOpeningBraceShouldBeFollowedByNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.FunctionOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the if-statement block braces and new lines around braces.

    .DESCRIPTION
        Each if-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-IfStatement -IfStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.IfStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-IfStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IfStatementAst]
        $IfStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $IfStatementAst.Extent

            $testParameters = @{
                StatementBlock = $IfStatementAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.IfStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.IfStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.IfStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the foreach-statement block braces and new lines around braces.

    .DESCRIPTION
        Each foreach-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-ForEachStatement -ForEachStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.ForEachStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-ForEachStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ForEachStatementAst]
        $ForEachStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $ForEachStatementAst.Extent

            $testParameters = @{
                StatementBlock = $ForEachStatementAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ForEachStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ForEachStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ForEachStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the DoUntil-statement block braces and new lines around braces.

    .DESCRIPTION
        Each DoUntil-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-DoUntilStatement -DoUntilStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.DoUntilStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-DoUntilStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.DoUntilStatementAst]
        $DoUntilStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $DoUntilStatementAst.Extent

            $testParameters = @{
                StatementBlock = $DoUntilStatementAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.DoUntilStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.DoUntilStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.DoUntilStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the DoWhile-statement block braces and new lines around braces.

    .DESCRIPTION
        Each DoWhile-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-DoWhileStatement -DoWhileStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.DoWhileStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-DoWhileStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.DoWhileStatementAst]
        $DoWhileStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $DoWhileStatementAst.Extent

            $testParameters = @{
                StatementBlock = $DoWhileStatementAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.DoWhileStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.DoWhileStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.DoWhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the while-statement block braces and new lines around braces.

    .DESCRIPTION
        Each while-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-WhileStatement -WhileStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.WhileStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-WhileStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.WhileStatementAst]
        $WhileStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $WhileStatementAst.Extent

            $testParameters = @{
                StatementBlock = $WhileStatementAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.WhileStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.WhileStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.WhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the for-statement block braces and new lines around braces.

    .DESCRIPTION
        Each for-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-ForStatement -ForStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.ForStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-ForStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ForStatementAst]
        $ForStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $ForStatementAst.Extent

            $testParameters = @{
                StatementBlock = $ForStatementAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ForStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ForStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ForStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the switch-statement block braces and new lines around braces.

    .DESCRIPTION
        Each switch-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-SwitchStatement -SwitchStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.SwitchStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-SwitchStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.SwitchStatementAst]
        $SwitchStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $SwitchStatementAst.Extent

            $testParameters = @{
                StatementBlock = $SwitchStatementAst.Extent
            }

            <#
                Must use an else block here, because otherwise, if there is a
                switch-clause that is formatted wrong it will hit on that
                and return the wrong rule message.
            #>
            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.SwitchStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            }
            elseif (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.SwitchStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.SwitchStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the try-statement block braces and new lines around braces.

    .DESCRIPTION
        Each try-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-TryStatement -TryStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.TryStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-TryStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.TryStatementAst]
        $TryStatementAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $TryStatementAst.Extent

            $testParameters = @{
                StatementBlock = $TryStatementAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.TryStatementOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            }

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.TryStatementOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.TryStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
    .SYNOPSIS
        Validates the catch-clause block braces and new lines around braces.

    .DESCRIPTION
        Each catch-clause should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-CatchClause -CatchClauseAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.CatchClauseAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-CatchClause
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.CatchClauseAst]
        $CatchClauseAst
    )

    Process
    {
        try
        {
            $script:diagnosticRecord['Extent'] = $CatchClauseAst.Extent

            $testParameters = @{
                StatementBlock = $CatchClauseAst.Extent
            }

            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.CatchClauseOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            }

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.CatchClauseOpeningBraceShouldBeFollowedByNewLine
                $diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.CatchClauseOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

Export-ModuleMember -Function Measure-*
