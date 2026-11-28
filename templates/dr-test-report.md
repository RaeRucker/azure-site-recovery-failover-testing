# Disaster Recovery Test Report

Replace everything in square brackets. The numbers in brackets are only examples.

| | |
|---|---|
| Organization | [Organization or business unit] |
| Test date | [Date] |
| Test lead | [Name] |
| Environment | Azure Site Recovery, [number] Recovery Services vaults, [number] protected VMs |
| Regions | Primary: [region] → Disaster recovery: [region] |
| Overall result | [Passed, Passed with issues or Failed] |

## Summary

[Two or three sentences for leadership. For example: "All 12 protected servers came up in the disaster recovery region. App owners confirmed their apps worked. Recovery took 1 hour 20 minutes against a 4 hour target. The source VMs kept running the whole time."]

## Targets and results

| Measure | Target | Achieved | Result |
|---|---|---|---|
| Recovery time, RTO | [4 hours] | [1 hour 20 minutes] | [Pass] |
| Data loss window, RPO | [1 hour] | [12 minutes] | [Pass] |
| VMs recovered | [12] | [12] | [Pass] |
| Apps confirmed working | [5] | [5] | [Pass] |

## Scope

| Vault | Recovery plan | VMs |
|---|---|---|
| [rsv-contoso-dr1] | [plan-1] | [vm-a, vm-b, vm-c] |
| [rsv-contoso-dr2] | [plan-2] | [vm-d, vm-e] |

## Timeline

| Time | Event |
|---|---|
| [09:00] | Pre-checks done, all VMs healthy |
| [09:10] | Test failover started, recovery point Latest processed |
| [09:42] | All VMs running in the disaster recovery region |
| [10:30] | App checks done |
| [10:45] | Cleanup done, replication healthy |

## Check results

| VM or app | Boots | Sign-in works | Data current | App works | Notes |
|---|---|---|---|---|---|
| [vm-a] | [Pass] | [Pass] | [Pass] | [Pass] | |

## Issues and follow-up

| # | Issue | Impact | Owner | Due |
|---|---|---|---|---|
| 1 | [App server needed a manual DNS change in the test network] | [Low] | [Name] | [Date] |

## How the test was run

The test followed the test failover runbook. Readiness checks ran first. VMs were test failed over into an isolated network with no link to the source network. The test lead and app owners checked them. Cleanup ran, then replication was checked again. [Say whether the source VMs or replication were affected.]

## Sign-off

| Name | Role | Date |
|---|---|---|
| | Business or IT owner | |
| | Test lead | |
