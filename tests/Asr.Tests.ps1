#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }
<#
    Static checks for the readiness script and the docs.
    Run: Invoke-Pester ./tests -Output Detailed
#>

BeforeAll {
    $script:root = Split-Path -Parent $PSScriptRoot
}

Describe 'Get-AsrReadiness' {
    It 'parses without errors' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $script:root 'scripts/Get-AsrReadiness.ps1'), [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It 'is read-only (no Set, New, Remove, Start, Stop or Update calls against Site Recovery)' {
        $text = Get-Content -Raw (Join-Path $script:root 'scripts/Get-AsrReadiness.ps1')
        # Set-AzRecoveryServicesAsrVaultContext only selects the vault for the local session.
        $text | Should -Not -Match '(Set|New|Remove|Start|Stop|Update)-AzRecoveryServices(?!AsrVaultContext)'
    }
}

Describe 'Documentation' {
    It 'every relative link resolves' {
        $broken = foreach ($md in Get-ChildItem $script:root -Recurse -Filter *.md) {
            foreach ($m in [regex]::Matches((Get-Content -Raw $md.FullName), '\]\(([^)#:]+)(#[^)]*)?\)')) {
                $target = Join-Path $md.DirectoryName $m.Groups[1].Value
                if (-not (Test-Path $target)) { "$($md.Name) -> $($m.Groups[1].Value)" }
            }
        }
        $broken | Should -BeNullOrEmpty
    }
}
