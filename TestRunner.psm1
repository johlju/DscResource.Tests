<#
    .SYNOPSIS
        Runs all tests (including common tests) on all DSC resources in the given folder.

    .PARAMETER ResourcesPath
        The path to the folder containing the resources to be tested.

    .EXAMPLE
        Start-DscResourceTests -ResourcesPath C:\DscResources\DscResources
#>
function Start-DscResourceTests
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ResourcesPath
    )

    $testsPath = $pwd
    Push-Location -Path $ResourcesPath

    Get-ChildItem | ForEach-Object {
        $moduleName = $_.Name
        $destinationPath = Join-Path -Path $ResourcesPath -ChildPath $moduleName

        Write-Verbose -Message "Copying common tests from $testsPath to $destinationPath"
        Copy-Item -Path $testsPath -Destination $destinationPath -Recurse -Force

        Push-Location -Path $moduleName

        Write-Verbose "Running tests for $moduleName"
        Invoke-Pester

        Pop-Location
    }

    Pop-Location
}

<#
    .EXAMPLE
        Start-MetaTestsInRepositories -ClonePath './temp/' -TestFrameworkUrl 'https://github.com/SSvilen/DscResource.Tests' -TestFrameworkBranch 'KeywordsCheck' -Verbose
#>
function Start-MetaTestsInRepositories
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ParameterSetName = 'Url')]
        [System.String]
        $RepositoriesUrl = 'https://raw.githubusercontent.com/dsccommunity/dsccommunity.org/master/data/resources.json',

        [Parameter(Mandatory = $true, ParameterSetName = 'Json')]
        [System.String]
        $Repository,

        [Parameter()]
        [System.String]
        $Organization = 'PowerShell',

        [Parameter()]
        [System.String]
        $ClonePath = '.',

        [Parameter()]
        [System.String]
        $TestFrameworkUrl = 'https://github.com/PowerShell/DscResource.Tests',

        [Parameter()]
        [System.String]
        $TestFrameworkBranch
    )

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        throw 'Need to run as administrator to run meta tests.'
    }

    $ClonePath = Resolve-Path -Path $ClonePath -ErrorAction 'Stop'

    $githubUrlPath = "https://github.com/$Organization/{0}"

    $resourceObject = Invoke-RestMethod -Uri $RepositoriesUrl

    $repositories = $resourceObject.Resources

    foreach ($currentRepository in $repositories)
    {
        $repositoryPath = Join-Path -Path $ClonePath -ChildPath $currentRepository

        & git clone ($githubUrlPath -f $currentRepository) $repositoryPath

        $repositoryTestFrameworkPath = Join-Path -Path $repositoryPath -ChildPath 'DSCResource.Tests'

        if ($PSBoundParameters.ContainsKey('TestFrameworkBranch'))
        {
            & git clone $TestFrameworkUrl $repositoryTestFrameworkPath --branch $TestFrameworkBranch
        }
        else
        {
            & git clone $TestFrameworkUrl $repositoryTestFrameworkPath
        }

        Invoke-Pester -Script (Join-Path -Path $repositoryTestFrameworkPath -ChildPath 'Meta.Tests.ps1') -Show Failed,Summary
    }
}

function Start-MetaTests
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName
    )
}

Export-ModuleMember -Function @(
    'Start-DscResourceTests'
    'Start-MetaTestsInRepositories'
    'Start-MetaTests'
)
