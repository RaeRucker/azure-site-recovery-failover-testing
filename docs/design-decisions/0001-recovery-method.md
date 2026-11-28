# 0001. Pick the recovery method by recovery time

This folder holds short notes on design decisions. Each one says what was decided, why, and what it costs.

Status: accepted

## Decision

Systems that have to be back within a few hours use Azure Site Recovery with recovery plans. They also keep immutable backups. Everything else restores from backup with Cross Region Restore, which lets you restore a backup into the paired region. Test and dev systems are redeployed from templates.

## Why

Restoring a set of dependent VMs from backup takes hours, and someone has to do each restore by hand in order. That can't meet a recovery time target of a few hours for an app with several tiers. Replication can, but it costs more per VM for Site Recovery licensing, cache storage and replica disks. Paying that for every VM would be a waste.

Replication also copies mistakes. If data gets deleted or encrypted, the replica gets the same change. That's why the replicated systems keep backups too.

## What it costs

There are two recovery methods to test. The [test failover runbook](../../runbooks/asr-test-failover.md) covers Site Recovery. Restores from backup are covered in [azure-immutable-backup-vaults](https://github.com/RaeRucker/azure-immutable-backup-vaults).
