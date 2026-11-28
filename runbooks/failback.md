# Failback Runbook

Use this to move VMs back to the primary region after a real failover. Failback is a second planned move, not an undo button. Give it the same care as the failover.

## Before you start

- The primary region has been healthy for a period you agreed on, like 48 hours. Check it in Service Health.
- The business has approved a maintenance window. Failback means a short outage while the last changes sync and the VMs switch over.
- You have permission to create VMs in the primary region.

## Steps

1. Commit the failover if you haven't already. Open the vault, go to Protected items → Replicated items, click the VM and click Commit. Commit deletes the old recovery points, so only do it once you're happy with the failed-over VM.
2. Reprotect so replication runs from the disaster recovery region back to the primary. On the same VM page, click Re-protect, check the direction is secondary to primary, and click OK. For a recovery plan, do this from Manage → Recovery Plans (Site Recovery).
3. Wait for the reprotect job to finish under Monitoring → Site Recovery jobs, and for the VM to show Protected and Healthy. This can take hours for large disks.
4. Start the failback in the maintenance window. On the VM or recovery plan, click Failover. Check the direction is secondary to primary and pick a recovery point.
5. Tick Shut down machine before beginning failover. Site Recovery then tries to shut down the VMs in the disaster recovery region first so their last changes sync. The failover still goes ahead if the shutdown fails, so check the VMs are off.
6. Check the VMs with the same checks used in the [test failover runbook](asr-test-failover.md).
7. Point DNS or your load balancer back to the primary region. Lower the DNS TTL before the window so the change takes effect quickly.
8. Commit the failback, then reprotect again so the VMs replicate from primary to secondary and are protected for next time.
9. Check that backup jobs for these VMs resume in the primary region's vault, and run an on-demand backup for your most important systems.

## Common problems

| What you see | What to check |
|---|---|
| Re-protect is greyed out or fails | The failover has to be committed first. The primary region also has to be reachable, and the original VM's resource group and disks have to still exist. If they were deleted, turn off replication and set it up again from the current region. |
| Data written after the failover is missing after failback | Shut down machine before beginning failover wasn't ticked, or reprotect hadn't finished before the failback started. |
| Backups stop after failback | Check the VM is still listed under Protected items → Backup items in the primary vault. If it isn't, turn backup on again or check that Azure Policy auto-enrollment covers it. |
