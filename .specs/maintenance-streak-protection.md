# Maintenance streak protection

## Problem and outcome

Game maintenance can prevent players from completing a daily mission while the
streak calendar continues advancing. Active streaks must not break because of a
declared maintenance window, and an authorized operator must be able to restore
streaks already reset by the incident.

## Scope

- Exclude one configured inclusive day range from missed-day calculations.
- Preserve streak protectors when the only gap is covered by maintenance.
- Add an authorized, auditable, idempotent repair operation that updates the
  profile streak and streak state together.
- Preserve later player progress and the historical longest streak.
- Keep API and worker streak-cache projections aligned with the configured
  on-chain maintenance range.

## Non-goals

- Automatically decide whether historical inactivity was caused by an incident.
- Automate production deployment from the contract implementation itself.
- Change daily mission completion or XP award semantics.

## Acceptance criteria

- A player active immediately before a configured maintenance range can complete
  after it and continue the same streak without consuming protectors.
- Missed days outside the maintenance range still use protectors or break the
  streak according to the existing rules.
- Maintenance configuration and repairs require the existing system permission.
- An invalid maintenance range is rejected.
- A repair updates `Profile.daily_streak` and `StreakState.last_completed_day`
  atomically, never lowers current or longest streak values, and preserves
  protector balances.
- Retrying the same player/incident repair has no effect.
- The next valid daily completion continues from the repaired value.
- Configuration and repair actions emit auditable events.
- Cached API responses and optimistic worker updates exclude the same inclusive
  maintenance range as the contract.

## Assumptions and decisions

- Maintenance days use the same 03:00 ART / 06:00 UTC period IDs as missions.
- The configured start and end days are inclusive.
- The incident starts on 2026-09-18 at the daily boundary (`start_day =
  20714`), as confirmed by the team.
- `end_day` is the last daily period affected when maintenance is disabled. The
  configured inclusive end is period `20724` (2026-09-28 at the 03:00 ART
  boundary). This covers a reopening on Monday 2026-09-28 and lets players
  resume their streak in period `20725` beginning Tuesday 2026-09-29 at 03:00 ART.
- The first implementation supports one retained maintenance range. It must
  remain configured until affected dormant players have had their state repaired
  or materialized; replacing it is an explicit operational decision.
- Production restore values will be derived from historical on-chain state, not
  from the Supabase cache alone.

## Technical plan

- Store a singleton maintenance range in the profile world.
- Subtract the overlap with that range when projecting a streak gap.
- Store one repair receipt per player and incident ID.
- Add permissioned configuration and repair entrypoints to `xp_system`.
- Cover maintenance-only gaps, mixed gaps, repair continuation, and idempotency
  in the existing streak test suite.

## Tasks

- [x] Add maintenance and repair models plus store helpers.
- [x] Apply maintenance overlap to streak projection.
- [x] Add permissioned configuration and repair entrypoints with events.
- [x] Add focused tests and run the streak suite.
- [x] Review migration/rollout requirements and final diff.

## Verification

- `scarb fmt --check`: passed.
- `scarb test`: 20 passed, 0 failed.
- `sozo build`: passed.
- API: 90 tests passed and TypeScript build passed with maintenance-aware
  cached projections.
- Torii worker: 26 tests passed and bundle build passed with maintenance-aware
  optimistic projections.
- `sozo 1.8.7` can read the mainnet World over RPC 0.10.x; the version drift is
  now a warning instead of a fatal error.
- Mainnet migration, maintenance configuration, and the audited repair batch
  were executed successfully and verified on-chain.

## Production rollout

1. [x] Keep maintenance enabled while deploying the profile migration.
2. [x] Configure incident `maintenance-2026-09-18` with `start_day = 20714` and
   inclusive `end_day = 20724` for the planned Monday 2026-09-28 reopening.
3. [x] Configure `STREAK_MAINTENANCE_START_DAY` and
   `STREAK_MAINTENANCE_END_DAY` with the same values in the API and Torii worker,
   then deploy both services. No Supabase schema migration is required.
4. [x] Reconstruct every affected player's uninterrupted value from Starknet event
   history and historical state, starting with resets materialized on or after
   `start_day`; use Supabase only to enrich and cross-check the candidate list.
5. [x] Dry-run the complete repair batch and retain the player, previous value,
   restored value, last completed day, and evidence block for review.
6. [x] Execute one `restore_streak` per affected player with the same incident ID.
   The receipt makes retries safe and the repair never reduces newer progress.
7. [x] Refresh repaired players from chain into `player_streaks`, then verify the
   cache matches the on-chain status.
8. [ ] Verify configuration, repair receipts, emitted events, and a sample of
   post-maintenance streak continuations before reopening the app.
9. [ ] Leave the historical streak range enabled after reopening. Because its end
   day is fixed, it cannot forgive future absences and it continues protecting
   dormant players whenever they eventually return.

## Read-only production audit snapshot

Snapshot taken on 2026-09-24 at Starknet block `15350956`, before any
production mutation:

- 17 reset events were emitted in periods `20714` through `20719`, affecting
  15 distinct players.
- 7 resets emitted in period `20714` were caused by days missed before the
  inclusive maintenance start and are not compensation candidates.
- Simulating the maintenance overlap against each player's preceding streak
  event leaves 6 repairs caused exclusively by missed days from period `20714`
  onward:

| Player | Current raw streak | Restore to | Last completed day |
| --- | ---: | ---: | ---: |
| PMc | 1 | 2 | 20717 |
| Polifemo-7 | 1 | 3 | 20717 |
| HarveyDent84 | 1 | 3 | 20717 |
| Shuc | 1 | 3 | 20719 |
| FlwrChld | 1 | 3 | 20719 |
| Jailsongto | 1 | 2 | 20719 |

This batch is a dry-run snapshot, not an executed migration. Recompute it at
execution time so any later daily completions are preserved. The global
maintenance range, rather than this repair list, protects every other player
who has not yet returned.

### Updated snapshot for 2026-09-28

At Starknet block `15579165`, using the confirmed inclusive range
`20714..20724`, 28 reset events affected 19 players. Replaying their daily
completion events while excluding only maintenance days produced 9 current
repair candidates:

| Player | Current raw streak | Restore to | Last completed day |
| --- | ---: | ---: | ---: |
| FlwrChld | 1 | 4 | 20722 |
| Excel100 | 5 | 7 | 20724 |
| Shuc | 1 | 4 | 20723 |
| PMc | 1 | 2 | 20717 |
| NYtro | 5 | 6 | 20724 |
| Polifemo-7 | 1 | 3 | 20717 |
| Filippo | 1 | 3 | 20723 |
| Jailsongto | 3 | 5 | 20723 |
| HarveyDent84 | 1 | 4 | 20722 |

## Production execution record

- Mainnet World:
  `0x039c8aff3ceda2fffddf0ac20a94c465de6c0020372d43d225cf83655ef99477`.
- Profile migration completed successfully with Sozo 1.8.7.
- Maintenance configured for `20714..20724` in transaction
  `0x013cc59d073baa3e4a4ba108142141d1e2ea2b72530ef73948ed185d286dce8d`.
- All 9 repairs from the refreshed audit were applied atomically in transaction
  `0x04c0ba4567e4d43a7874dc3fc5cc0f5a212d579571b689c101e6eba65ae33f02`.
- Post-transaction reads confirmed the restored streak for every repaired
  player with `days_missed = 0` and `is_broken = false`.
- On 2026-09-28, the API and unified worker were deployed from `develop` with
  `STREAK_MAINTENANCE_START_DAY=20714` and
  `STREAK_MAINTENANCE_END_DAY=20724`. The API's live refresh returned the
  expected chain streak for all 9 repaired players.
- Supabase `player_streaks` was refreshed for all 9 players; cached reads
  matched the chain with `days_missed = 0`, `is_broken = false`, and confirmed
  sync status. Their stable `run_start_day` values were restored from the
  completion history.
- Six existing reward receipts were re-associated with their restored streak
  runs, earned milestone receipts were reconciled, and ten milestone period IDs
  were aligned with the actual completion days. A second rewards read left
  receipt counts unchanged and no duplicate claim scope was found.
- The owner signer was supplied through the ignored local `.env`; no credential
  was written to tracked configuration.
