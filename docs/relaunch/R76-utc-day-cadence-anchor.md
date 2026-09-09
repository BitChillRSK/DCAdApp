# R76 — Anchor cadence to the UTC-midnight grid and name the field for what it is

Status: **implemented** · Assigned: yes · Optional/further-review: no · Order: stack on
[R75](./R75-final-audit-cadence-and-source-docs.md) (#134), before any deployment

## Objective

Make the no-catch-up cadence rule correct *by construction* rather than correct by proof, and rename
`lastPurchaseTimestamp` to `cadenceAnchor` so the field says what it holds. Both halves must land
before the relaunch deploy: the field name is in the ABI's tuple components and the event is a
signature, so neither is layout- or consumer-compatible afterwards.

## Background

R75 fixed a real defect — after a fully missed period, a retry earlier in the day than the anchor's
time of day left the schedule immediately eligible for a second purchase that same UTC day. The fix
was correct but *subtle*: it measured elapsed periods to the **end** of the current UTC day
(`currentDayStart + 1 days - 1`) so that the day-granular eligibility check and the second-granular
advancement would agree, and it relied on a non-obvious proof that the resulting quotient is at
least one.

The reason that subtlety was needed at all is that a schedule's anchor carried a **time of day** that
nothing reads. Eligibility only ever compares `dayFloor(anchor + period)`, so for a period that is a
whole number of days the anchor's time of day is semantically dead weight — and it was exactly the
degree of freedom that made the R75 defect representable. The old anchor could also sit in the
**future** (R2 called this intended), which is what the day-end trick had to compensate for.

Two facts settle the design:

- The swapper runs at a fixed time of day, and eligibility opens at 00:00 UTC on the due day. The
  bot therefore has the whole due day to succeed or retry, and the anchor's time of day plays no
  part in that. This is what absorbed the 2026-09 lending-liquidity incident, where the morning tick
  failed and an evening retry succeeded with no slot lost.
- For a period that is a whole number of days, `dayFloor(anchor + period) == dayFloor(anchor) + period`.
  Snapping the anchor to UTC midnight is therefore **behaviour-preserving** for every period the
  protocol means to offer, not a semantic change.

### The policy itself was not new, and is reaffirmed

Skip-don't-recover has been the intent since `6335994` (2025-11-06), which replaced `anchor + period`
— a genuine catch-up design, where each purchase advanced exactly one period and a gap made the
schedule repeatedly eligible until it had made up every missed slot — with
`anchor + periodsElapsed * period`. R2 then explicitly preserved that snap. R75 closed the gap
between the intent and its enforcement; R76 does not revisit the policy.

The reasoning was never written down, so it is recorded here. Catch-up is rejected because:

- **It is structurally incompatible with one purchase per UTC day.** For a daily schedule, catching
  up a missed Monday *means* two purchases on Tuesday. One-per-day is what bounds batch size and
  makes per-tick gas predictable, which is what R64/R71–R73 optimised against.
- **Nothing is lost by skipping.** The stablecoin stays in `tokenBalance`; the schedule's tail
  extends by one slot. Total deployment over the schedule's life is unchanged — only the timing
  shifts.
- **Catch-up would not recover what was missed.** Two buys at one Tuesday price is one double-size
  buy. The volume comes back, the price diversification — the entire product — does not.
- **It would concentrate buying at the worst moments.** Outages correlate with market stress
  (a lending venue runs out of free liquidity precisely under withdrawal pressure), and every
  schedule shares the outage, so every schedule would catch up in the same tick.
- **It compounds failure.** `purchaseAmount > tokenBalance` reverts the whole batch, so larger
  catch-up debits make one under-funded row likelier to kill every other user's purchase in it.
- **It is unbounded.** A schedule paused six months and refunded would owe ~180 purchases, so it
  needs an arbitrary cap that becomes a new product parameter.

The liquidity incident that prompted the review is a **routing** problem, not a cadence one, and the
levers for it are same-day bot retry (which already worked), an idle-route fallback, and alerting on
venue free liquidity.

## Open product decisions

**none** — the human reviewed the catch-up question directly and reaffirmed skip, then asked for the
grid simplification, the rename, and the consumer issues.

## Scope

- [x] Snap the anchor to UTC midnight: a first purchase stamps `dayFloor(block.timestamp)` instead of
      `block.timestamp`, so every anchor is a grid point and no anchor is ever in the future.
- [x] Require `purchasePeriod % 1 days == 0` on user schedules and on the protocol minimum, with a new
      `DcaManager__PurchasePeriodMustBeWholeDays` error. This is what keeps a schedule on the grid its
      anchor sits on; the pre-existing one-day floor stays.
- [x] Replace the day-end formula with the exact one: eligibility is `dayFloor(now) >= anchor + period`
      and advancement is `anchor + ((dayFloor(now) - anchor) / period) * period`. The `periodsElapsed`
      floor-at-one and the `currentDayEnd` term both disappear as redundant.
- [x] Rename `lastPurchaseTimestamp` → `cadenceAnchor` and
      `DcaManager__LastPurchaseTimestampUpdated` → `DcaManager__CadenceAnchorUpdated`. Widths, field
      order, and slot packing are unchanged.
- [x] Keep the whole cadence computation inside one `unchecked` block and restore the safety
      justification R75 had removed.
- [x] Start the shared test fixture at a real UTC instant (Monday 2026-01-05 09:00 UTC). Foundry's
      default `block.timestamp == 1` floors to a zero day start, which would collide with the
      `cadenceAnchor == 0` sentinel.
- [x] Rework the boundary tests: the widest period is now the widest whole-day `uint32`, and the
      anchor's `uint48` edge is the first UTC midnight past `type(uint48).max`.
- [x] Prove non-whole-day rejection on both the schedule setter and the protocol minimum, and keep a
      whole-day-but-not-whole-week (3-day) no-catch-up regression.

## Out of scope

- [ ] Revisiting no-catch-up itself, fee/economics (R74), route maps, migration, or new public surface
      beyond the one error and the two renames.
- [ ] Calendar-month periods, which no whole-day grid can express.
- [ ] Sub-weekly cadence *policy* (whether the bot should run every 3 days, or Mondays and Fridays).
      The contract now permits any whole-day period; which ones the product offers is a separate
      decision, and an uneven split like Mon/Fri is not expressible as a single fixed period at all.
- [ ] `forge fmt` of existing files, and any broadcast.

## Semantics after this change

For a schedule with anchor `A` (a UTC midnight) and period `P` (a whole number of days):

- **Eligible** from `A + P` at 00:00 UTC, and on every later day.
- **A successful purchase** sets `A' = A + floor((dayFloor(now) - A) / P) * P`, the newest grid point
  at or before today. It consumes its own slot plus every slot missed before it.
- **`A' + P` is always on a strictly later UTC day**, so a schedule cannot buy twice in one UTC day —
  now true by construction, since `A'` and `A' + P` are both grid points and `A' <= dayFloor(now)`.
- **`A'` is never in the future**, unlike the old anchor.
- **Cadence day-of-week survives a late execution**: a weekly Monday buy executed Tuesday sets the
  anchor to Monday and stays due the following Monday.

## Measurements

Controlled probe (same test file on both sides, warping to a fixed absolute instant):

| | before (#134) | after | delta |
|---|---|---|---|
| first purchase | 248,093 | 248,118 | +25 |
| subsequent purchase | 110,732 | 110,687 | **−45** |
| `DcaManager` runtime | 13,547 | 13,620 | +73 bytes |

The steady-state path — the one the protocol pays for every schedule, forever — is cheaper by one
`MOD`, one `SUB` and one `ADD`. The one-time first purchase pays 25 gas for the day-start snap.

## ABI changes

Yes, and they are why this cannot land after the deploy:

- `DcaSchedule.lastPurchaseTimestamp` → `cadenceAnchor` (tuple component name; width, position and
  packing unchanged).
- `DcaManager__LastPurchaseTimestampUpdated` → `DcaManager__CadenceAnchorUpdated` — a new event
  signature and topic0. No indexed field moved.
- New error `DcaManager__PurchasePeriodMustBeWholeDays`.

No function selector changes. The execution time of a purchase is unchanged for consumers: it is the
block timestamp of the log, which is where it always was — the anchor never carried it reliably,
because a purchase made late in its due day already reported an earlier value.

## Files touched

- `src/DcaManager.sol`
- `src/interfaces/IDcaManager.sol`
- `test/unit/DcaDappTest.t.sol` (fixture instant, shared `_utcDayStart` / `_expectedCadenceAnchor`)
- `test/unit/RbtcPurchaseTest.t.sol`, `test/unit/SchedulePackingTest.t.sol`,
  `test/unit/ModifiersTest.t.sol`
- Mechanical rename in the remaining first-party test files
- `docs/relaunch/README.md`, `docs/relaunch/IMPLEMENTATION_ORDER.md`

`test/gas/prototype/**` keeps `lastPurchaseTimestamp`: those are frozen R64 benchmark designs that
record an earlier shape, and R75's stand-alone-wording rule does not reach them.

## Tests run

```bash
make check
make check-deploy
make slither      # 89 findings, unchanged from R73/R75 triage; retains its expected nonzero exit
make aderyn       # exit 0, same retained categories
```

Both lanes (`mocSwaps/sovryn/DOC` and `dexSwaps/none/USDT0`) match the pre-change failure baseline
exactly: the same five pre-existing fork/RPC-dependent failures, no new ones.

## Consumer follow-ups

The field rename, the event rename and the anchor's new meaning all reach off-chain readers:

- [swapper-bot#11](https://github.com/BitChillRSK/swapper-bot/issues/11), [data-api#10](https://github.com/BitChillRSK/data-api/issues/10), [bitchill-monitoring#20](https://github.com/BitChillRSK/bitchill-monitoring/issues/20), [front-end#26](https://github.com/BitChillRSK/front-end/issues/26), [metrics-dashboard#8](https://github.com/BitChillRSK/metrics-dashboard/issues/8).

The rename is a **silent** break for any log filter keyed on the old topic0: a renamed event stops
matching rather than failing to decode, so every consumer issue calls that out explicitly.
