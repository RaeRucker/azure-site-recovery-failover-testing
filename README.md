# Azure Site Recovery Failover Testing

How I run Azure Site Recovery test failovers and report on them. It has a runbook, a readiness script, a report template and a failback runbook.

I run these tests in production for VMs protected across multiple Recovery Services vaults, and write the report that goes to leadership and the technical team afterward. Everything here is written generically, with no environment details.

## What a test failover does

It brings up copies of your protected VMs in the disaster recovery region, inside an isolated network, so you can prove they boot and the apps work. Production keeps running the whole time and nothing replicates back. When you're done, you clean the copies up.

## What's here

| File | What it's for |
|---|---|
| [`runbooks/asr-test-failover.md`](runbooks/asr-test-failover.md) | The full test with every portal step, from planning to the report |
| [`scripts/Get-AsrReadiness.ps1`](scripts/Get-AsrReadiness.ps1) | Run before and after the test. Shows replication health per VM, flags leftover test failovers, lists recovery plans |
| [`templates/dr-test-report.md`](templates/dr-test-report.md) | The report to fill in after each test |
| [`runbooks/failback.md`](runbooks/failback.md) | Getting back to the primary region after a real failover |
| [`docs/dependency-map.md`](docs/dependency-map.md) | Which servers come up in which order, and what to do when one doesn't |
| [`docs/decisions/`](docs/decisions/) | Why critical systems use Site Recovery and everything else restores from backup |

## Permissions

| Who | Role | Where it's assigned | Why |
|---|---|---|---|
| Whoever runs the readiness script | Site Recovery Reader | Each Recovery Services vault | The script only reads replication status |
| Whoever runs the test | Site Recovery Operator | Each Recovery Services vault | To start the test failover and the cleanup |
| Whoever runs the test | Reader | The isolated test virtual network | To pick it as the test network |
| App owners | Access to the test VMs, usually through Bastion or a jump box in the test network | The test network | To check their apps work |

You don't need Contributor for any of this. Site Recovery Operator is enough to fail over and clean up, and it can't change replication settings.

## Before test day

1. Agree on a date and window with the business contact.
2. Make sure there's an isolated virtual network in the DR region with no peering to production. Test VMs use the same names and IPs as production, so they must not be able to reach it.
3. Tell each app owner what they'll be checking and when.

## Running a test

### Step 1. Check replication health

1. In the Azure portal, click the **Cloud Shell** icon in the top bar and pick **PowerShell**.
2. Run:

   ```powershell
   git clone https://github.com/RaeRucker/azure-site-recovery-failover-testing
   cd azure-site-recovery-failover-testing
   Set-AzContext -Subscription '<subscription name or ID>'
   ./scripts/Get-AsrReadiness.ps1
   ```

3. Every VM should show as healthy with no test failover already running. If not, stop and fix replication first. Don't test on unhealthy replication.
4. Download the CSV for the report. In Cloud Shell, click **Manage files → Download** and enter `azure-site-recovery-failover-testing/output/` followed by the file name.

To check only certain vaults, add `-VaultName rsv-name-1, rsv-name-2`.

### Step 2. Start the test failover

1. Open the Recovery Services vault and go to **Site Recovery → Recovery Plans**. If you don't use recovery plans, go to **Replicated items** and do it per VM.
2. Select the plan and click **Test failover**.
3. For the recovery point, pick **Latest processed** unless the runbook for this app says otherwise.
4. For the Azure virtual network, pick the isolated test network. Double check this. It must never be the production network.
5. Click **OK** and write down the start time.
6. Watch **Monitoring → Site Recovery jobs** and write down when each VM finishes.

### Step 3. Validate

1. Have each app owner sign in to their test VM and confirm the app works.
2. Write down any problems and how long each VM took to come up. The [runbook](runbooks/asr-test-failover.md) lists what to check.

### Step 4. Clean up

1. Go back to **Site Recovery → Recovery Plans**, select the plan and click **Cleanup test failover**.
2. Add notes on how it went, tick **Testing is complete** and click **OK**.
3. Wait for the cleanup job to succeed under **Site Recovery jobs**.
4. Run `./scripts/Get-AsrReadiness.ps1` again. Every VM should be back to healthy with no open test failovers.

### Step 5. Report

Fill in [`templates/dr-test-report.md`](templates/dr-test-report.md) and send it to the business contact and technical team within two business days.

## If something goes wrong

| What you see | What to do |
|---|---|
| A VM's test failover job fails | Check the error under **Site Recovery jobs** and retry once. If it fails again, escalate with the job ID. |
| A VM won't boot or can't be reached | Check **Boot diagnostics** and **Serial console** on the test VM and screenshot them for the report. |
| Replication is unhealthy before you start | Don't test. Open a ticket, fix replication, reschedule. |
| Cleanup fails | Run cleanup again. If it still fails, delete the test resources by hand after confirming they're test only, then mark the test complete. |
| Anything that could touch production | Stop, clean up, escalate right away. |

## Tests

CI checks that the readiness script parses, that it never calls anything that changes Site Recovery, and that every link in the docs works. It also runs a secret scan.

```powershell
Invoke-Pester ./tests -Output Detailed
```

## Related

Backup vaults and tier policies are in [azure-immutable-backup-vaults](https://github.com/RaeRucker/azure-immutable-backup-vaults).
