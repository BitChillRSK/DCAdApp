# R67 — Exact batch share accounting

Status: **not started** · Assigned: no · Optional/further-review: yes

## Objective

Decide whether lending batches should debit users for exactly the number of protocol shares the
handler redeems, eliminating the small rounding difference in the current two-stage calculation.
This is an accounting-quality question, not part of R66's denial-of-service defense.

## Background

`LendingErc20Handler._batchRetrieveStablecoin` first rounds the aggregate stablecoin request into one
`totalSharesToRedeem`, then assigns each row a rounded-up pro-rata share of that total. The per-row
ceilings can sum to slightly more than the aggregate shares actually redeemed. The handler therefore
may remove a few more virtual shares from users collectively than it burns at the lending protocol.

One candidate is to compute each row's rounded-up share debit directly from that row's stablecoin
amount, sum those debits, and redeem exactly the sum. This makes the two books equal but can slightly
increase the aggregate redemption because every row, rather than only the aggregate, rounds up. The
gas, measured cash result, allocation effects, and behavior for repeated buyers need review before
choosing it.

## Open product decisions

- Does removing the bounded share-dust discrepancy justify changing the batch redemption arithmetic?
- If yes, should each row independently round up and the protocol redeem the exact sum, accepting the
  corresponding small increase in underlying requested?

## Scope

- [ ] Measure the maximum and observed difference between shares debited and shares redeemed across
      supported lending adapters and representative batch sizes.
- [ ] If approved, sum each row's independently calculated share debit and redeem exactly that sum.
- [ ] Preserve the existing revert when any row's buyer lacks the required shares.
- [ ] Preserve measured stablecoin accounting and pro-rata rBTC allocation from actual cash received.

## Out of scope

- [ ] Skipping or clamping an underfunded row.
- [ ] Returning per-row funding results to `DcaManager`.
- [ ] Moving schedule effects after the handler call.
- [ ] Any change to idle handlers, batch calldata, min-out semantics, or the protected purchase window.

## Files likely touched

- `src/LendingErc20Handler.sol`
- `test/unit/LendingErc20HandlerRedeemTest.t.sol`
- Dedicated lending-handler tests only where adapter rounding differs materially

## Required tests

- A multi-user batch debits exactly the sum of shares redeemed at the protocol.
- Repeated rows for one buyer debit that buyer by exactly their rows' combined share requirement.
- An insufficient-share row continues to revert the whole handler batch with
  `TokenLending__InsufficientShares`.
- Measured stablecoin receipt and rBTC allocation invariants remain unchanged.
- Record gas against the parent revision for 1, 5, 10, 50, and 200 rows.
- Fork tests add no R67-specific assertions unless measurement finds adapter-specific behavior.

## Success criteria

- [ ] The product decision is recorded before Solidity changes.
- [ ] If implemented, total virtual shares debited equals total protocol shares redeemed for every
      successful batch.
- [ ] No R66 behavior or ABI change is pulled into this item.
- [ ] The full local and fork gates pass.

## Reviewer checklist

- [ ] Matches **Scope**; nothing from **Out of scope**.
- [ ] Measurements distinguish harmless bounded dust from a solvency or withdrawal impact.
- [ ] Existing insufficient-funding behavior remains explicit.
- [ ] No unrelated refactors; history is reviewable.

## ABI / deploy / cutover impact

- ABI: none expected.
- Scripts: none.
- Cutover: none expected; open a monitoring follow-up only if an existing event's field meaning changes.
