# R75 — Final audit: no-catch-up cadence and concise source documentation

Status: **in progress** · Assigned: yes · Optional/further-review: no · Order: stack on the current
source tip after R73 and the three review follow-ups (#131–#133), before any deployment

## Objective

Close the final protocol-wide audit with one cadence correction: a successful purchase skips every
missed slot and must leave the schedule ineligible for another purchase that UTC day. Record the
non-obvious but intentional security/accounting choices concisely in verified source, without version
history, ticket language, or claims that constructor-patched deployed bytecode is identical.

## Background

The UTC-day eligibility check is correct, but the timestamp update beneath it is not sufficient to
enforce the intended no-catch-up policy. Example: first weekly purchase Monday 23:00; miss the next
Monday; execute the following Monday 00:00. Raw elapsed seconds contain only one complete week, so the
current floor quotient advances the anchor to the missed Monday 23:00. The next due timestamp is then
the current Monday 23:00; its UTC day has already started, so a second same-day purchase is accepted.

The update must instead choose the latest cadence anchor whose UTC day has begun. Equivalently, compute
complete periods through the end of the current UTC day. The next anchor plus one period then falls on
a strictly later UTC day. This preserves the schedule's original time-of-day cadence: if a weekly bot
misses Monday and succeeds Tuesday, the anchor advances to Monday's slot and the next due day is the
following Monday. Only the execution price/time moves to Tuesday.

The audit also found no second exploitable accounting or external-call defect. Existing deliberate
choices remain: exact external receipt-share consumption with cash haircuts allowed; per-row ceiling
share debits and floor rBTC allocation dust; balance-delta cash; trusted, add-only handler wiring;
caller-only rBTC withdrawal; and an oracle floor without a tautological handler-generated deadline.
Those reasons should remain available where a reviewer meets the code, but shorter than the current
multi-paragraph form.

## Open product decisions

**none** — the human explicitly chose no catch-up and asked for the final audit/documentation pass.

## Scope

- [ ] Change `DcaManager._rBtcPurchaseChecksEffects` so one successful purchase consumes all cadence
      slots whose due UTC day has started and the next due UTC day is strictly later than today.
- [ ] Prove the missed-cycle/early-day counterexample, same-day rejection, multiple missed periods,
      and the weekly Monday-failure/Tuesday-success/next-Monday sequence with focused tests.
- [ ] Document `lastPurchaseTimestamp` as a cadence anchor, not necessarily the execution timestamp;
      state the no-catch-up policy on `IDcaManager` without mentioning another protocol version.
- [ ] Audit all first-party `src/` comments/NatSpec. Remove version-history/ticket language, replace
      Tropykus “legacy” labels with production-deployment facts, correct generic leaf “same bytecode”
      claims, and trim repetition while retaining durable security, accounting, authority, rounding,
      constructor-order, and external-integration reasons.
- [ ] Remove the production-dead `_calculateFee` wrapper and have test harnesses call the existing
      loaded-settings helper directly. This has no ABI or deployed-runtime behavior effect.
- [ ] Strengthen the canonical deployment test's assertions for immutable manager, stablecoin,
      venue, oracle/router, and receipt-token wiring where the current test checks only a subset.
- [ ] Re-run Slither and Aderyn and update the release record only if their triage changes.

## Out of scope

- [ ] Fee/economics changes (R74), route-map changes, migration, upgradeability, rescue functions,
      handler flattening, or a new purchase/venue pause.
- [ ] New public functions, events, custom errors, indexed fields, storage fields, or constructor args.
- [ ] Supporting fee-on-transfer tokens, async/partial lending redemptions, or untrusted handlers.
- [ ] Rewriting historical specs/tests/docs merely because they legitimately record R-items or earlier
      behavior. The stand-alone wording rule applies to verified first-party `src/` comments/NatSpec.
- [ ] `forge fmt` of existing files or any live/testnet broadcast.

## Files likely touched

- `src/DcaManager.sol`
- `src/interfaces/IDcaManager.sol`
- `src/FeeHandler.sol`
- Concise comment-only corrections in first-party `src/**`
- `test/unit/RbtcPurchaseTest.t.sol`
- `test/mocks/FeeHandlerHarness.sol`
- `test/unit/PurchaseUniswapMinOutTest.t.sol`
- `test/unit/deployment/FinalDeploymentTest.t.sol`
- `docs/relaunch/IMPLEMENTATION_ORDER.md`
- `docs/relaunch/README.md`
- `docs/relaunch/R73-RELEASE_RECORD.md` only if final analyzer triage changes

## Required tests

```bash
SWAP_TYPE=mocSwaps LENDING_PROTOCOL=sovryn STABLECOIN_TYPE=DOC \
  forge test --match-contract RbtcPurchaseTest
SWAP_TYPE=dexSwaps LENDING_PROTOCOL=none STABLECOIN_TYPE=USDT0 \
  forge test --match-contract RbtcPurchaseTest
SWAP_TYPE=mocSwaps LENDING_PROTOCOL=sovryn STABLECOIN_TYPE=DOC \
  forge test --match-contract FinalDeploymentTest
make slither
make aderyn
make check
make check-deploy
make fork-sovryn
make fork-tropykus
make fork-dex-path
```

The cadence tests must fail against the pre-R75 formula. Fork tests add no cadence-specific assertion;
they remain the live integration gate before push.

## Success criteria

- [ ] No schedule can complete two purchases in one UTC day, including after one or many missed slots.
- [ ] A weekly schedule missed on Monday and bought Tuesday remains due the following Monday; no
      schedule drift or extra skip is introduced.
- [ ] The verified source states that missed purchases are skipped and never recovered later.
- [ ] First-party source comments contain no BitChill version comparison, relaunch wording, R-item id,
      or “legacy only” label, and the retained rationale is concise and accurate.
- [ ] Audit/static-analysis findings are either fixed or explicitly retained with a current reason.
- [ ] ABI and storage layout are unchanged; deployment wiring assertions and all gates pass.

## Reviewer checklist

- [ ] Matches **Scope**; nothing from **Out of scope**.
- [ ] Protocol invariants in `AGENTS.md` still hold.
- [ ] Calendar-day proof works for periods that are not exact multiples of one day.
- [ ] Tests in the PR match **Required tests** and the regression fails on the parent commit.
- [ ] Files beyond this list are limited to audited source-comment corrections or failing-test fallout
      and are named in the PR.
- [ ] No unrelated refactor or promotional security claim.

## ABI / deploy / cutover impact

- ABI: none. `lastPurchaseTimestamp` keeps its type and event; its documented cadence rule becomes exact.
- Storage: none.
- Scripts: none; canonical deployment tests gain assertions only.
- Cutover: the swapper and schedule readers must mirror the no-catch-up UTC-day rule. Existing matching
  consumer issues should be updated rather than duplicated. No broadcast action is performed here.
