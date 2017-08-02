#Requires -Version 4.0

# Import Localized Data
Import-LocalizedData -BindingVariable localizedData

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
        Each function should have the opening brace on a separate line. Also, the
        opening brace should be followed by a new line.

    .EXAMPLE
        Measure-FunctionBlockBraces -ScriptBlockAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-FunctionBlockBraces
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

            [System.Management.Automation.Language.Ast[]] $functionsAst = $ScriptBlockAst.FindAll( $findAllFunctionsFilter, $true )

            foreach ($functionAst in $functionsAst)
            {
                <#
                    Remove carriage return since the file is different depending if it's run in
                    AppVeyor or locally. Locally it contains both '\r\n', but when cloned in
                    AppVeyor it only contains '\n'.
                #>
                $functionExtentTextWithNewLine = $functionAst.Extent -replace '\r', ''

                $functionExtentRows = $functionExtentTextWithNewLine -split '\n'

                if ($functionExtentRows.Count)
                {
                    # Check so that an opening brace does not exist on the same line as the function name.
                    if ($functionExtentRows[0] -match '\{')
                    {
                        $results += New-Object `
                            -Typename $diagnosticRecordType `
                            -ArgumentList @(
                            $localizedData.FunctionOpeningBraceNotOnSameLine, `
                                $functionAst.Extent, `
                                $PSCmdlet.MyInvocation.InvocationName, `
                                'Warning', `
                                $null
                        )
                    } # if
                } # if

                if ($functionExtentRows.Count -ge 2)
                {
                    # Check so that an opening brace is followed by a new line.
                    if ($functionExtentRows[1] -match '\{.+')
                    {
                        $results += New-Object `
                            -Typename $diagnosticRecordType `
                            -ArgumentList @(
                            $localizedData.FunctionOpeningBraceShouldBeFollowedByNewLine, `
                                $functionAst.Extent, `
                                $PSCmdlet.MyInvocation.InvocationName, `
                                'Warning', `
                                $null
                        )
                    } # if
                } # if

                if ($functionExtentRows.Count -ge 3)
                {
                    # Check so that an opening brace is followed by only one new line.
                    if (-not $functionExtentRows[2].Trim())
                    {
                        $results += New-Object `
                            -Typename $diagnosticRecordType `
                            -ArgumentList @(
                            $localizedData.FunctionOpeningBraceShouldBeFollowedByOnlyOneNewLine, `
                                $functionAst.Extent, `
                                $PSCmdlet.MyInvocation.InvocationName, `
                                'Warning', `
                                $null
                        )
                    } # if
                } # if
            }

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
        Validates the statement block braces and new lines around braces.

    .DESCRIPTION
        Each statement should have the opening brace on a separate line. Also, the
        opening brace should be followed by a new line.

    .EXAMPLE
        Measure-StatementBlockBraces -ScriptBlockAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-StatementBlockBraces
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

            [System.Management.Automation.Language.Ast[]] $functionsAst = $ScriptBlockAst.FindAll( $findAllFunctionsFilter, $true )

            foreach ($functionAst in $functionsAst)
            {
                $findAllStatementBlockFilter = {
                    $args[0] -is [System.Management.Automation.Language.StatementBlockAst]
                }

                [System.Management.Automation.Language.Ast[]] $statementBlocksAst = $functionAst.FindAll( $findAllStatementBlockFilter, $true )
                if ($statementBlocksAst)
                {
                    $statementParentExtents = $statementBlocksAst.Parent.Extent

                    foreach ($statementParentExtent in $statementParentExtents)
                    {
                        <#
                            Remove carriage return since the file is different depending if it's run in
                            AppVeyor or locally. Locally it contains both '\r\n', but when cloned in
                            AppVeyor it only contains '\n'.
                        #>
                        $statementParentExtentTextWithNewLine = $statementParentExtent.Text -replace '\r', ''

                        $statementParentExtentRows = $statementParentExtentTextWithNewLine -split '\n'

                        if ($statementParentExtentRows.Count)
                        {
                            # Check so that an opening brace does not exist on the same line as the statement.
                            if ($statementParentExtentRows[0] -match '\{')
                            {

                                $results += New-Object `
                                    -Typename $diagnosticRecordType `
                                    -ArgumentList @(
                                    $localizedData.StatementOpeningBraceNotOnSameLine, `
                                        $statementParentExtent, `
                                        $PSCmdlet.MyInvocation.InvocationName, `
                                        'Warning', `
                                        $null
                                    )
                            } # if
                        } # if
                    } # foreach statement parent

                    $statementExtents = $statementBlocksAst.Extent

                    foreach ($statementExtent in $statementExtents)
                    {
                        <#
                            Remove carriage return since the file is different depending if it's run in
                            AppVeyor or locally. Locally it contains both '\r\n', but when cloned in
                            AppVeyor it only contains '\n'.
                        #>
                        $statementExtentTextWithNewLine = $statementExtent.Text -replace '\r', ''

                        $statementExtentRows = $statementExtentTextWithNewLine -split '\n'

                        if ($statementExtentRows.Count)
                        {
                            # Check so that an opening brace is followed by a new line.
                            if ($statementExtentRows[0] -match '\{.+')
                            {
                                $results += New-Object `
                                    -Typename $diagnosticRecordType `
                                    -ArgumentList @(
                                    $localizedData.StatementOpeningBraceShouldBeFollowedByNewLine, `
                                        $statementExtent, `
                                        $PSCmdlet.MyInvocation.InvocationName, `
                                        'Warning', `
                                        $null
                                    )
                            } # if
                        } # if

                        if ($statementExtentRows.Count -ge 2)
                        {
                            # Check so that an opening brace is followed by only one new line.
                            if (-not $statementExtentRows[1].Trim())
                            {
                                $results += New-Object `
                                    -Typename $diagnosticRecordType `
                                    -ArgumentList @(
                                    $localizedData.StatementOpeningBraceShouldBeFollowedByOnlyOneNewLine, `
                                        $statementExtent, `
                                        $PSCmdlet.MyInvocation.InvocationName, `
                                        'Warning', `
                                        $null
                                )
                            } # if
                        } # if
                    } # foreach statement
                } # if
            } # foreach function

            return $results
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

Export-ModuleMember -Function Measure*
