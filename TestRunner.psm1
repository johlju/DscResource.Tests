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
        Start-MetaTestsInRepositories -ClonePath './temp/' -TestFrameworkUrl 'https://github.com/SSvilen/DscResource.Tests' -TestFrameworkBranch 'KeywordsCheck'
#>
function Start-MetaTestsInRepositories
{
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

    $ClonePath = Resolve-Path -Path $ClonePath -ErrorAction 'Stop'

    $githubUrlPath = "https://github.com/$Organization/{0}"

    #$currentLocation = Get-Location

    try
    {
        $resourceObject = Invoke-RestMethod -Uri $RepositoriesUrl

        $repositories = $resourceObject.Resources

        foreach ($currentRepository in $repositories)
        {
            #Set-Location -Path $ClonePath

            $repositoryPath = Join-Path -Path $ClonePath -ChildPath $currentRepository

            & git @(
                'clone',
                ($githubUrlPath -f $currentRepository),
                $repositoryPath
            )

            #Set-Location -Path './{0}' -f $currentRepository

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
    catch
    {
        throw $_
    }
    finally
    {
        #Set-Location -Path $currentLocation
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
