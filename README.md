# Azure Site Recovery Failover Testing

How I run Azure Site Recovery test failovers and report on them. It's a runbook, a readiness script, a report template and a failback runbook.

I run these tests in production for VMs protected across multiple Recovery Services vaults, and write the report that goes to leadership and the technical team afterward. Everything here is written generically, so no environment details are included.

## What's here

| File | What it's for |
|---|---|
| [`runbooks/asr-test-failover.md`](runbooks/asr-test-failover.md) | The test itself, start to finish: planning, pre-checks, running the failover, validating, cleanup and reporting |
| [`scripts/Get-AsrReadiness.ps1`](scripts/Get-AsrReadiness.ps1) | Run it before the test. It shows replication health for every protected VM, flags any test failover that never got cleaned up, and lists which VMs are in which recovery plan |
| [`templates/dr-test-report.md`](templates/dr-test-report.md) | The report I fill in after each test |
| [`runbooks/failback.md`](runbooks/failback.md) | Getting back to the primary region after a real failover |
| [`docs/dependency-map.md`](docs/dependency-map.md) | Recovery order for a typical multi-tier app and what to do when a step fails |
| [`docs/decisions/`](docs/decisions/) | Why critical systems use ASR and everything else restores from backup |

## How a test goes

1. Two weeks out, agree on the window and the isolated test network, and tell the app owners what they'll be checking.
2. On the day, run `Get-AsrReadiness.ps1` and save the CSV. If anything isn't healthy, don't test. Fix replication and reschedule.
3. Run the test failover on the recovery plan into the isolated network. Double-check the network. It should never be production.
4. Record when each VM comes up, then have the app owners validate their apps.
5. Clean up the test failover and run the readiness script again to confirm everything is back to healthy.
6. Fill in the report and send it within two business days.

The [runbook](runbooks/asr-test-failover.md) has the full portal steps and the escalation table.

## Running the readiness script

```powershell
Connect-AzAccount
Set-AzContext -Subscription '<subscription name or ID>'

./scripts/Get-AsrReadiness.ps1                                         # every vault in the subscription
./scripts/Get-AsrReadiness.ps1 -VaultName rsv-dr-eastus2, rsv-dr-centralus
```

It only reads. It writes a CSV to `./output` and prints a summary. You'll need the Az.RecoveryServices module and Reader on the vaults.

## Tests

```powershell
Invoke-Pester ./tests -Output Detailed
```

CI checks that the script parses, that it never calls anything that would change Site Recovery state, that every link in the docs works, and runs a secret scan.

## Related

Backup vaults and tier policies are in [azure-immutable-backup-vaults](https://github.com/RaeRucker/azure-immutable-backup-vaults).
