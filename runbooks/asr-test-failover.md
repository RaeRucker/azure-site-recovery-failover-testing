# Test Failover Runbook

Use this to prove your protected VMs can be brought up in the disaster recovery region within your recovery targets, without touching the source VMs.

Run it at least twice a year, and after any big change to the replicated VMs. Plan on 2 to 4 hours, depending on how many VMs there are and how much app testing is needed.

| Role | What they do |
|---|---|
| Test lead | Runs this runbook, writes down the times and writes the report |
| App owners | Check their apps in the test network |
| Escalation engineer | First call if a VM won't fail over or won't boot |
| Business contact | Approves the test window and signs off on the results |

Two terms used below. The recovery time objective, or RTO, is how long you can afford to be down. The recovery point objective, or RPO, is how much recent data you can afford to lose.

## 1. Plan, one to two weeks before

- [ ] Agree on the test window with the business contact and tell everyone involved.
- [ ] Check the isolated test virtual network exists in the disaster recovery region and has no peering, VPN or other link to the source network. Test VMs keep the same names and IP addresses as the source VMs, so a link would cause conflicts.
- [ ] Decide what the test network needs for app checks, like DNS, a jump box or a domain controller. A domain-joined app needs a domain controller in the test network. See [the dependency map](../docs/dependency-map.md).
- [ ] Get a short checklist from each app owner that says what working means for their app.
- [ ] Write down the RTO and RPO targets you're testing against.

## 2. Pre-checks, on the day

1. Run the readiness script from Cloud Shell and save the CSV for the report. The [README](../README.md#step-1-check-replication-health) has the exact steps.

   ```powershell
   ./scripts/Get-AsrReadiness.ps1
   ```

2. In the portal, open each vault and go to Protected items → Replicated items. Check that:
   - [ ] every VM shows Replication health Healthy and Status Protected
   - [ ] no VM shows a failover readiness warning
   - [ ] no VM still has a test failover waiting for cleanup
3. Click each VM and write down its latest recovery point. That's the RPO you'll get.

Stop here if anything is unhealthy. Fix replication or escalate first. A test that starts from broken replication proves nothing.

## 3. Run the test failover

Use the recovery plan if there is one. It brings VMs up in the right order, like domain controller, then database, then app servers, and it's what you'd use in a real disaster.

1. Open the vault and go to Manage → Recovery Plans (Site Recovery). Click the plan, then click Test failover.

   For a single VM, go to Protected items → Replicated items, click the VM, then click Test failover.
2. For Recovery Point, pick one of these:
   - Latest processed. The usual choice. It starts fastest.
   - Latest app-consistent. Use it for databases that need app-consistent data.
3. For Azure virtual network, pick the isolated test network. Double check this. Never pick the source network.
4. Click OK and write down the start time.
5. Go to Monitoring → Site Recovery jobs and write down the time each VM finishes.

## 4. Check the VMs and apps

Connect through the jump box or Bastion in the test network.

The test lead checks the VMs:

- [ ] Every VM in the plan is running in the disaster recovery region.
- [ ] Each VM boots and you can sign in.
- [ ] The disks are attached and the data drives are there.
- [ ] The data is as recent as the recovery point. Check a recent file, log entry or database row.
- [ ] Names resolve inside the test network.

The app owners work through their checklists and write down pass or fail with notes.

Write down the total time from the start of the failover to the last app being confirmed working. That's the RTO you got.

## 5. Clean up

Cleanup deletes the test VMs that the test failover created. Replication keeps running.

1. Go to Manage → Recovery Plans (Site Recovery), click the plan and click Cleanup test failover. For a single VM, do it from Protected items → Replicated items.
2. Add notes on how it went, tick Testing is complete and click OK.
3. Go to Monitoring → Site Recovery jobs and check the cleanup job shows Successful.
4. Run `./scripts/Get-AsrReadiness.ps1` again. It should say READY.

## 6. Report

Fill in [the report template](../templates/dr-test-report.md) and send it to the business contact and technical team within two business days.

## Escalation

| What you see | What to do |
|---|---|
| A VM's test failover job fails | Open the job under Monitoring → Site Recovery jobs and read the error. Retry once. If it fails again, send the job ID to the escalation engineer. |
| A VM won't boot or can't be reached | On the test VM, check Help → Boot diagnostics and Help → Serial console. Take screenshots for the report. |
| Replication is unhealthy before the test | Don't test. Open a ticket, fix replication and reschedule. |
| Cleanup fails | Run cleanup again. If it still fails, delete the test VMs by hand after confirming they're test only, then run cleanup once more. |
| Anything that could touch the source network | Stop, clean up and escalate right away. |
