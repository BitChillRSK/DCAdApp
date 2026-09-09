# R74 — Revisit launch-era economic parameters (future, unassigned)

Status: **not started** · Assigned: no · Optional/further-review: yes · Order: after relaunch cutover,
not before it

This is a **documentation-only placeholder for a future prompt**, written from the 2026-09-07 chat that
decided [R72](./R72-licensing.md)'s licensing question. It is deliberately not assigned: do not
implement anything here without a fresh `Start with R74` human prompt, and do not let it block or widen
R71/R72/R73.

## Objective

BitChill's original economic parameters — flat 1% fee, $25 minimum purchase, 1-week minimum purchase
period — were set to make the protocol viable at launch. The relaunch has since cut gas costs
substantially (optimizer-on, `via_ir` evaluated, dead selectors and bytecode removed, OZ5 migration —
see `README.md` **Measurement basis**). Revisit whether those parameters are still the right ones, or
whether lower friction now attracts enough additional volume to be more profitable in aggregate than
the current per-purchase economics.

This is a product/business decision informed by, but not decided by, the gas numbers R71 through R73
produced. It is not a Solidity change until a human decides new values.

## Background

Current production defaults, all deploy-time configuration rather than hardcoded protocol limits:

- **Fee: flat 1%** (`MIN_FEE_RATE == MAX_FEE_RATE_PRODUCTION == 100` bps in `script/Constants.sol`).
  `FeeHandler` supports a fee curve between a min and max rate; production collapses it to one flat
  rate. `MAX_FEE_RATE_CAP` (`src/FeeHandler.sol`) hard-caps any configured rate at 5%, which is not
  itself in question here.
- **Minimum purchase: $25** (`MIN_PURCHASE_AMOUNT`, `script/Constants.sol`; USDT0 uses
  `USDT0_MIN_PURCHASE_AMOUNT` for its 6-decimal scale). Set per-token via
  `DcaManager.setTokenMinPurchaseAmount`; there is no protocol-wide default (`DeployUsdrifHandler.s.sol`).
- **Minimum purchase period: 1 week on the live launch-era deployment, but the relaunch scripts pass
  1 day.** `MIN_PURCHASE_PERIOD` in `script/Constants.sol` is `1 days`, and that is what
  `DeployFinal.s.sol` hands the constructor, so **the relaunch will accept daily schedules from day
  one unless that constant is changed before cutover.** The front end currently offers only weekly,
  2-weekly and 4-weekly, so the gap is invisible until a caller goes direct. The on-chain floor is
  also 1 day (`DcaManager.validateMinPurchasePeriod`), and since
  [R75](./R75-final-audit-cadence-and-source-docs.md#same-pr-follow-up-utc-midnight-cadence-grid-and-cadenceanchor-rename)
  every period must additionally be a whole number of days.
  Deciding the deployed default is therefore part of this item, not a given — see the sub-weekly
  cadence note below.

None of these three is a code constant that requires a Solidity change to revisit — the fee rate and
minimum purchase are per-token `DcaManager` setter calls, and the minimum period only needs a Solidity
change if the new desired floor would go **below** today's 1-day contract minimum (e.g., enabling daily
purchases needs no code change; enabling sub-daily would).

## Open product decisions

**All of them — this entire prompt is the open question.** Suggested framing for whoever picks this up:

1. Is the 1% fee still calibrated to viability, or would a lower fee plus higher volume net more
   protocol revenue at today's gas costs? What is the actual current gas cost of one purchase, and
   what fee floor does that alone justify (as opposed to the historical $25/1% figures, which predate
   the relaunch's gas-efficiency work)?
2. Does $25 still make sense as a minimum, or is it now leaving addressable users behind for a
   friction reason that no longer holds at current per-purchase gas cost?
3. Daily purchases (relaxing the 1-week deploy default toward the 1-day contract floor) were noted as
   needing "significant volume" to justify — what volume, measured how, and is there a batching-cost
   argument (shared `batchBuyRbtc` gas is amortized across schedules in the same batch) that changes
   the answer independent of raw per-user volume?
4. Any of the above may want a **per-token** or **per-route** answer rather than one protocol-wide
   number, given USDT0 already has its own minimum-purchase constant.
5. **Sub-weekly but not daily.** Raised 2026-09-09. The contract already permits any whole-day period
   at or above the configured minimum, so 3-day, 4-day and 10-day schedules need no Solidity change —
   only a deploy-config and front-end decision. Two shapes are *not* equivalent and should not be
   conflated:
   - **A fixed sub-weekly period** (every 3 days) is expressible and behaves exactly like the weekly
     case. Its cost is that the cadence *drifts across weekdays*: 3 does not divide 7, so a schedule
     lands on a different weekday each cycle. Multiples of a week are what kept purchase days aligned
     with the bot's operating rhythm, which is why weekly/2-weekly/4-weekly were chosen.
   - **An uneven weekly pattern** (Mondays and Fridays) is **not expressible at all** as one fixed
     period, because the gaps alternate 3 and 4 days. It would need either two schedules per user
     (3-day and 4-day offsets do not stay aligned either) or a genuine weekday-mask field — new
     storage and a new eligibility rule, not a parameter change.

   So the realistic sub-weekly options are a fixed whole-day period with accepted weekday drift, or
   `7 days` staying the floor. The intermediate frequency does not otherwise interact with R75's grid:
   any whole-day period keeps one purchase per UTC day and skips missed slots identically.

## Scope

Not defined. Whoever answers the questions above should write the actual scope into this file (or a
renumbered replacement) before implementation starts, per `TASK_TEMPLATE.md`.

## Out of scope

- [ ] Anything to do with `MAX_FEE_RATE_CAP` (5%) — that is a safety ceiling, not part of this question.
- [ ] The 1-day on-chain `minPurchasePeriod` floor itself — only the deploy-time default above it.
- [ ] Blocking R71/R72/R73 on this decision. This is explicitly post-cutover revisit work.

## Files likely touched

Likely **none** in `src/`. All three parameters already have owner-only live setters and need no
redeployment to change: `FeeHandler.setFeeRateParams` (fee), `DcaManager.setTokenMinPurchaseAmount`
(minimum purchase, per token), `DcaManager.modifyMinPurchasePeriod` (period, floored at 1 day on-chain
by `validateMinPurchasePeriod`). If the answer only changes the values passed to these on the live
deployment, this is an **ops action** (an owner/Safe transaction), not a source PR. `src/` would only
change if the decision needs a new on-chain floor (e.g., a minimum period below 1 day) — check
`DcaManager.validateMinPurchasePeriod` before assuming that's needed. `script/Constants.sol` and the
`Deploy*.s.sol` call sites only matter for what a *future* redeployment starts with, not for changing
the parameters BitChill already runs.

## Required tests

Unknown until scoped. If this resolves to an ops-only owner-transaction change (see **Files likely
touched**), tests are whatever already covers `setFeeRateParams` / `setTokenMinPurchaseAmount` /
`modifyMinPurchasePeriod` — confirm they still pass, do not write new ones for a parameter value.

## Success criteria

- [ ] A human has answered the four questions above (or superseded them) and rewritten this file's
      **Scope** before any code or ops change.

## Reviewer checklist

Unknown until scoped — this file is not yet an implementation spec.

## ABI / deploy / cutover impact

- ABI: none, if resolved via the existing owner-only setters (see **Files likely touched**).
- Scripts: `script/Constants.sol` deploy-time defaults, so a *future* redeployment starts with the
  revisited values — separate from changing the currently live deployment.
- Cutover: if resolved as an ops action, this can happen any time after cutover with no code review
  at all; note it in the runbook so ops knows which owner call to make and why.
