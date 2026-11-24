# ADR 0001: Choose the recovery method by RTO, not by habit

Status: Accepted

Decision. Critical systems use Azure Site Recovery (continuous replication, recovery plans), plus immutable backup for logical corruption. Business-Essential and Operational systems use backup with Cross Region Restore. Non-Production is rebuilt from IaC.

Rationale. Restoring a set of dependent VMs from backup takes hours and is serialized by operator effort. That can't meet a 4 h RTO for a multi-tier app. Replication can, at the cost of per-VM ASR licensing, cache storage, and replica disks. Paying that for every VM would be wasteful. Replication also doesn't protect against logical failures (it copies them), so Critical keeps backups too.

Consequences. Two recovery mechanisms to test. The [test failover runbook](../../runbooks/asr-test-failover.md) covers ASR. Backup is covered by the restore validation runbook in [azure-immutable-backup-vaults](https://github.com/RaeRucker/azure-immutable-backup-vaults).
