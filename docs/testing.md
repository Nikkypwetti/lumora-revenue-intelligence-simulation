# Testing & Verification

## Incremental Entity Tests
For each generalized entity: no-change run → controlled source update → positive extraction → raw upsert verification → exact composite checkpoint advancement → database proof → no-change replay.

## Failure-Hardening Tests
Verified: checkpoint-not-ready, claim failure, owned post-claim failure, unverified commit, already-committed reconciliation, owner-safe release, cursor preservation, and deterministic replay.

## Full Orchestration
Verified final replay:
- 10 entity results / 10 unique entities.
- 10 checkpoints ready and unclaimed.
- zero active sync/entity runs.
- one reporting refresh after the entity batch.
- `full_sync_succeeded = true`.
- `workflow_stage = full_multi_entity_sync_and_reporting_verified`.

## Power BI Reconciliation
Verified: $3,311,500 Closed Won Revenue; $2,902,000 Open Pipeline; 190 Open Deals; 54.9% Win Rate; $14,718 Average Won Deal Size; 45 Stale Open Deals; 114 Overdue Follow Ups; 72 SLA Breaches; 185 Closed Lost Deals.
