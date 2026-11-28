# Azure Site Recovery Failover Testing

A runbook, a readiness script and a report template for running Azure Site Recovery test failovers. There's also a failback runbook for after a real failover.

## What it does

A test failover brings up copies of your protected VMs in the disaster recovery region, inside an isolated network, so you can prove they boot and the apps work. The source VMs keep running and replication carries on. When you're done, cleanup deletes the test VMs.

| Part | What it's for |
|---|---|
| [`runbooks/asr-test-failover.md`](runbooks/asr-test-failover.md) | The full test, from planning to the report, with every portal step |
| [`scripts/Get-AsrReadiness.ps1`](scripts/Get-AsrReadiness.ps1) | Run before and after the test. Shows replication health per VM, flags test failovers that weren't cleaned up and lists recovery plans. It only reads. |
| [`templates/dr-test-report.md`](templates/dr-test-report.md) | The report you fill in after each test |
| [`runbooks/failback.md`](runbooks/failback.md) | Getting back to the primary region after a real failover |
| [`docs/dependency-map.md`](docs/dependency-map.md) | Which servers come up in which order, and what to do when one doesn't |
| [`docs/design-decisions/`](docs/design-decisions/) | Short notes on why things were done a certain way. The first one covers when to use Site Recovery and when to restore from backup. |

## Permissions

| Who | Role | Where it's assigned | Why |
|---|---|---|---|
| Whoever runs the readiness script | Site Recovery Reader | Each Recovery Services vault | The script only reads replication status |
| Whoever runs the test | Site Recovery Operator | Each Recovery Services vault | To start the test failover and the cleanup |
| Whoever runs the test | Reader | The isolated test virtual network | To pick it as the test network |
| App owners | A sign-in on the test VMs, usually through Bastion or a jump box in the test network | The test network | To check their apps work |

You don't need Contributor. Site Recovery Operator can run failovers and cleanups but can't turn replication on or off.

## What to change for your environment

| Setting | What to put in |
|---|---|
| Subscription | The subscription that holds your vaults. Set it in Cloud Shell before you run the script with `Set-AzContext -Subscription '00000000-0000-0000-0000-000000000000'`. A subscription name works too. |
| `-VaultName` | Optional script parameter. The vaults to check, separated by commas, like `rsv-contoso-dr1, rsv-contoso-dr2`. Leave it out to check every Recovery Services vault in the subscription. |
| `-OutputFolder` | Optional script parameter. Where the CSV is saved. Default is the `output` folder at the top of the repo. |
| Test network | An existing virtual network in the disaster recovery region with no peering, VPN or other link to the source network, like `vnet-contoso-drtest`. You pick it during the test failover in step 2. |
| Report header fields | In `templates/dr-test-report.md`, fill in Organization, Test date, Test lead, Environment, Regions and Overall result. Regions look like `eastus2` and `centralus`. |
| Report targets | The recovery time and data loss targets you agreed with the business, like `4 hours` and `1 hour`. They go in the Targets and results table. |
| Report scope | Your vault names, recovery plan names and VM names. They go in the Scope table. |

## Setup

### Before test day

1. Agree on a date and time window with the business contact.
2. Check there's an isolated virtual network in the disaster recovery region. Test VMs use the same names and IP addresses as the source VMs, so the test network must not be able to reach the source network.
3. Tell each app owner what they'll be checking and when.

The [runbook](runbooks/asr-test-failover.md) has the full planning list.

### Step 1. Check replication health

1. In the Azure portal, click the Cloud Shell icon in the top bar and pick PowerShell. Cloud Shell already has the Az modules and is signed in as you.
2. Run:

   ```powershell
   git clone https://github.com/RaeRucker/azure-site-recovery-failover-testing
   cd azure-site-recovery-failover-testing
   Set-AzContext -Subscription '00000000-0000-0000-0000-000000000000'
   ./scripts/Get-AsrReadiness.ps1
   ```

3. You should see a READY line at the end. That means every VM's replication health is Normal and no test failover is still open. If you see NOT READY, stop and fix replication first.
4. Download the CSV for the report. In Cloud Shell, click Manage files → Download and enter `azure-site-recovery-failover-testing/output/` followed by the file name. The script prints the file name on its last line.

To check only some vaults, add `-VaultName rsv-contoso-dr1, rsv-contoso-dr2`.

### Step 2. Start the test failover

1. Open the Recovery Services vault and go to Manage → Recovery Plans (Site Recovery). If you don't use recovery plans, go to Protected items → Replicated items and do it one VM at a time.
2. Click the plan, then click Test failover.
3. For Recovery Point, pick Latest processed unless the runbook says otherwise for that app.
4. For Azure virtual network, pick the isolated test network. Double check this. It must never be the source network.
5. Click OK and write down the start time.
6. Go to Monitoring → Site Recovery jobs and write down when each VM finishes.

### Step 3. Check the apps

1. Have each app owner sign in to their test VM and confirm the app works.
2. Write down any problems and how long each VM took to come up. The [runbook](runbooks/asr-test-failover.md) lists what to check.

### Step 4. Clean up

1. Go back to Manage → Recovery Plans (Site Recovery), click the plan and click Cleanup test failover.
2. Add notes on how it went, tick Testing is complete and click OK. This deletes the test VMs.
3. Go to Monitoring → Site Recovery jobs and wait for the cleanup job to show Successful.
4. Run `./scripts/Get-AsrReadiness.ps1` again. You should see READY.

### Step 5. Write the report

Fill in [`templates/dr-test-report.md`](templates/dr-test-report.md) and send it to the business contact and technical team within two business days.

## If something goes wrong

| What you see | What to check |
|---|---|
| The script says NOT READY | Look at the Errors column for that VM, then check it under Protected items → Replicated items. Fix replication and run the script again. Don't test on unhealthy replication. |
| The script says Az.RecoveryServices is not installed | You're not in Cloud Shell. Run `Install-Module Az.RecoveryServices -Scope CurrentUser` or use Cloud Shell. |
| The script says no matching vaults were found | You're in the wrong subscription, or a name in `-VaultName` is misspelled. Check `Get-AzContext`. |
| A VM's test failover job fails | Open the job under Monitoring → Site Recovery jobs and read the error. Retry once. If it fails again, escalate with the job ID. |
| A VM won't boot or can't be reached | Open the test VM and check Help → Boot diagnostics and Help → Serial console. Take screenshots for the report. |
| The test network isn't in the list | You need Reader on that virtual network, and it has to be in the disaster recovery region. |
| Cleanup fails | Run cleanup again. If it still fails, delete the test VMs by hand after confirming they're test only, then run cleanup once more. |
| Anything that could touch the source network | Stop, clean up and escalate right away. |

## How it's built

The runbooks are written for the Azure portal. The script uses the Az.RecoveryServices module and only calls Get cmdlets. It goes through every vault, every fabric, every protection container and every replicated item, then writes one CSV row per VM.

A few choices worth explaining:

- The script runs before and after the test. Before shows it's safe to start. After shows cleanup really finished and replication is still healthy.
- A VM counts as not ready when replication health isn't Normal or a test failover is still open on it.
- Recovery plans are the default because they bring VMs up in order, the same way a real failover would.
- The test network has to be isolated because test VMs keep the same names and IP addresses as the source VMs.

## Files

| File | What it is |
|---|---|
| `runbooks/asr-test-failover.md` | Step-by-step test failover runbook |
| `runbooks/failback.md` | Failback after a real failover |
| `scripts/Get-AsrReadiness.ps1` | Read-only replication health check |
| `templates/dr-test-report.md` | Report template |
| `docs/dependency-map.md` | Example recovery order for a three-tier app |
| `docs/design-decisions/0001-recovery-method.md` | Why some systems use Site Recovery and others restore from backup |
| `tests/Asr.Tests.ps1` | Pester tests |
| `tests/PSScriptAnalyzerSettings.psd1` | Analyzer settings for the tests folder |
| `.github/workflows/validate.yml` | CI |

## Checks

CI runs on every push to main and on every pull request. It fails if any of these happen:

- PSScriptAnalyzer finds a warning or error in `scripts/` or `tests/`
- `Get-AsrReadiness.ps1` doesn't parse
- `Get-AsrReadiness.ps1` calls a Set, New, Remove, Start, Stop or Update cmdlet against Site Recovery. Setting the vault context is allowed because it only picks the vault for the session.
- a relative link in any markdown file points at a file that doesn't exist
- gitleaks finds a secret

To run the tests yourself:

```powershell
Invoke-Pester ./tests -Output Detailed
```

## Known gaps

- The script checks one subscription per run. Run it again after `Set-AzContext` for each other subscription.
- The script doesn't check protection state, failover readiness warnings or the latest recovery point. Check those in the portal as the runbook says.
- The link check only covers links inside this repo, not web links.
- The runbooks are for Azure VMs replicating to another Azure region. VMware and Hyper-V have different steps.

## Related

Backup vaults and restore testing are in [azure-immutable-backup-vaults](https://github.com/RaeRucker/azure-immutable-backup-vaults).
