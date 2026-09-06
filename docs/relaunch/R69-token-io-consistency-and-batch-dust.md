# R69 — Unify token I/O helpers, visibility style, and batch rBTC dust

Status: **not started** · Assigned: yes · Optional/further-review: no · Planning PR: [#125](https://github.com/BitChillRSK/dca-contracts/pull/125) · Order: after R68, before relaunch

## Objective

Make first-party token I/O and override seams use one house style, and stop batch purchases from
leaving uncredited native rBTC on the handler. None of these are product features: they close small
consistency and custody gaps that the relaunch should not ship with.

## Background

A pre-cutover pass over the handler stack surfaced four related gaps. They are small individually;
together they are the kind of polish that is cheap now and awkward after immutable deploy.

### 1. Two IERC165 import sources

`TokenHandler` (and every handler that inherits it) advertises ERC-165 through OpenZeppelin's
`ERC165`. `OperationsAdmin.assignTokenHandler` consumes the same interface via
`lib/forge-std/src/interfaces/IERC165.sol`. The two ABIs match today, so assignment works, but the
registry that *checks* capability and the handlers that *advertise* it disagree on which dependency
owns the type. First-party production code should not import forge-std interfaces; that package is
the test harness.

### 2. Two safe-approve helpers on the Dex path

Every first-party stablecoin move uses OpenZeppelin `SafeERC20`. `PurchaseUniswap._purchaseRbtc` is
the exception: it calls Uniswap v3-periphery's `TransferHelper.safeApprove` for the router allowance.
That helper is the only Uniswap *library* whose bytecode compiles into the Dex leaves (the router
interfaces are ABIs only). Replacing it with `SafeERC20.forceApprove` (the OZ 5.x shape already used
elsewhere after R44) gives the Dex path the same approve semantics as the rest of `src/` and removes
that GPL-2.0-or-later library from the shipped artifact. It does **not** close the broader licensing
question in `IMPLEMENTATION_ORDER.md` — `ISwapRouter02` / `IV3SwapRouter` imports remain — but it
removes the one Uniswap dependency that is compiled in rather than merely referenced.

### 3. Batch pro-rata floor dust leaves uncredited rBTC

`PurchaseRbtc.batchBuyRbtc` allocates measured rBTC (and the reported stablecoin spent) by
floor-dividing each buyer's planned net weight:

```solidity
usersPurchasedRbtc = totalPurchasedRbtc * plannedNet / totalNetStablecoinPlanned;
s_usersAccumulatedRbtc[buyer] += usersPurchasedRbtc;
```

The sum of those floors is at most `totalPurchasedRbtc`, and can be up to `n − 1` wei short for an
`n`-buyer batch. The shortfall stays as native balance on the handler but is never written into any
`s_usersAccumulatedRbtc` entry. After R8 removed the owner rescue, that wei is not withdrawable by
anyone: `withdrawAccumulatedRbtc` pays only the books, and there is no other exit. The existing
`PurchaseRbtcTest` already asserts the truncated shares (`sum a wei short of the measured total`)
and treats the truncation as load-bearing for R51 — so the behavior is known, not accidental, but it
has no NatSpec statement of where the dust goes, and "known stranded wei" is the wrong relaunch
posture when a one-line last-buyer remainder closes it.

Stablecoin attribution in the same loop has the same floor shape, but that figure is event-only: the
stablecoin was already spent into the venue. Only the rBTC side creates an un-attributable custody
residue.

### 4. Override seams that are `public` only so `super` works

Most of `src/` already uses **`external` entry + `internal` helper**: the ABI function is `external`
(matching the interface and the `EXTERNAL FUNCTIONS` banner), and shared or overridable logic lives
in a `_`-prefixed internal. Examples: `PurchaseUniswap.setPurchasePath` → `_setPurchasePath`, fee
setters, DcaManager mutators.

`TokenHandler.depositToken` / `withdrawToken` are the main exception. They are `public virtual`
because `LendingErc20Handler` and `IdleErc20Handler` call `super.depositToken` /
`super.withdrawToken`, and Solidity forbids `super` on an `external` function. That works, but it
makes the only reason for `public` an inheritance mechanic rather than a caller need: nobody inside
the contract should call the modifier-guarded ABI entry as an ordinary function.

The house alignment is the same pattern used elsewhere:

```solidity
function depositToken(address user, uint256 amount) external onlyDcaManager {
    _depositToken(user, amount);
}
function _depositToken(address user, uint256 amount) internal virtual { ... }
```

Children override or extend `_depositToken` / `_withdrawToken` and call `super._depositToken` (still
an internal JUMP). `ITokenHandler` stays `external`; selectors and behavior stay the same.

`PurchaseUniswap.setPurchasePath` is already wired through `_setPurchasePath` (the constructor never
calls the public setter) but the ABI function is still unnecessarily `public`. Narrow it to
`external` in the same pass.

**Gas (known, no new benchmark required).** For these `(address, uint256)` signatures both shapes are
the same class of cost: an external caller hits one entry, and a child that continues into the base
takes an internal JUMP either via `super.depositToken` or via `super._depositToken`. `external` can
avoid a calldata→memory copy that `public` often pays when arguments might also be used on an
internal path; with two static words that difference is noise. Adding an `external` wrapper around
an internal helper is one extra JUMP on the hot path (~tens of gas), also noise next to
`safeTransferFrom` / lending redemptions. Prefer the clearer override seam; do not claim a gas win
either way.

**Public immutables stay.** Construction wiring (`i_stableToken`, `i_dcaManager`, venue immutables,
`EXCHANGE_RATE_DECIMALS`, …) as `public immutable` / `public constant` is a deliberate deploy and
explorer surface. Mutable state already uses `internal`/`private` + named getters. Do not convert
immutables to private-without-getter or invent parallel `getStableToken` wrappers in this PR.

## Open product decisions

**none.** House-style I/O and override seams are not product questions. Dust policy is: credit every
measured wei of rBTC to some buyer's books, with the remainder on the last row. Do not ask;
implement.

## Scope

- [ ] Change `OperationsAdmin` to import `IERC165` from
      `@openzeppelin/contracts/utils/introspection/IERC165.sol`. Drop the forge-std interface import.
      Keep the existing `supportsInterface` checks and error paths unchanged.
- [ ] In `PurchaseUniswap._purchaseRbtc`, replace `TransferHelper.safeApprove(...)` with
      `SafeERC20.forceApprove` on the purchase token (add `using SafeERC20 for IERC20` if the file does
      not already have it). Remove the `TransferHelper` import. Do not change the exact-input
      consumption checks R59 added, the oracle floor, or path allowlisting.
- [ ] Refactor `TokenHandler.depositToken` / `withdrawToken` to `external` entries that call
      `_depositToken` / `_withdrawToken` (`internal virtual`). Move the balance-delta body into those
      helpers. Keep `onlyDcaManager` on the external entries (not on the internals), matching how other
      guarded entries wrap helpers.
- [ ] Update `LendingErc20Handler` and `IdleErc20Handler` to override / call `super` on the internal
      helpers instead of on the ABI functions. External overrides become `external override` that call
      into the same internal story (or override only the internal when the child has nothing to add at
      the ABI layer — prefer the shape that keeps one `onlyDcaManager` gate and no duplicate modifier).
- [ ] Change `PurchaseUniswap.setPurchasePath` from `public` to `external` (helper already exists).
- [ ] Leave `supportsInterface` and `BitChillOwnable.renounceOwnership` `public` (OZ / ERC-165 require
      it). Leave all `public immutable` / `public constant` construction wiring unchanged.
- [ ] In `PurchaseRbtc.batchBuyRbtc`, after the per-buyer floor loop (or as a final-row adjustment),
      credit any remaining `totalPurchasedRbtc - sum(floors)` to the last buyer so the sum of
      `s_usersAccumulatedRbtc` increments equals the measured rBTC for that batch. Keep planned nets as
      allocation weights for every row before the remainder. Do the same for the event's reported
      `usersStablecoinSpent` only if a matching remainder exists and can be attributed without changing
      fee or retrieval accounting; if the stablecoin side is event-only dust with no custody effect,
      documenting that in NatSpec is enough and a code change is optional.
- [ ] Add NatSpec on `batchBuyRbtc` (implementation and, if the surface owns the claim,
      `IPurchaseRbtc`) stating the durable rule: floor division allocates by planned-net weight; any
      leftover measured rBTC wei is credited to the last buyer so the handler's native balance and the
      sum of books stay aligned; there is no owner sweep of that residue.
- [ ] Update `PurchaseRbtcTest` (and any sibling that asserts truncated shares) so the last buyer's
      credit includes the remainder and the sum of credits equals `RBTC_OUT` / the measured total.
- [ ] Confirm `forge build --sizes` on the Dex leaves after dropping `TransferHelper` and the
      visibility refactor; record the runtime delta in the implementation PR.

## Out of scope

- [ ] Flattening the `TokenHandler` / `PurchaseRbtc` diamond inheritance. The leaf shape
      (`LendingErc20Handler`/`IdleErc20Handler` + `PurchaseMoc`/`PurchaseUniswap`) is deliberate; this
      PR does not redesign it.
- [ ] Converting `public immutable` / `public constant` construction wiring into private fields or
      named getters. That surface is intentional for deploy verification and explorers.
- [ ] Comment-volume or NatSpec voice passes (R61 / R65 / R63 already own that layer).
- [ ] Relicensing `src/` or changing SPDX on Uniswap-importing files (human decision; see
      **Licensing — reopened** in `IMPLEMENTATION_ORDER.md`). Removing `TransferHelper` only narrows
      the compiled GPL surface; it does not answer which license BitChill keeps.
- [ ] Reviving an owner rBTC rescue or adding a `to` parameter (R8 stands).
- [ ] Changing fee math, `minRbtcOut`, exact Uniswap input consumption (R59), or lending share
      consumption (R67 / R68).
- [ ] `forge fmt` of existing files.
- [ ] Deploy broadcasts or live addresses.

## Files likely touched

- `src/OperationsAdmin.sol`
- `src/TokenHandler.sol`
- `src/LendingErc20Handler.sol`
- `src/idle/IdleErc20Handler.sol`
- `src/PurchaseUniswap.sol`
- `src/PurchaseRbtc.sol`
- `src/interfaces/IPurchaseRbtc.sol` (NatSpec only, if the surface owns the dust rule)
- `test/unit/PurchaseRbtcTest.t.sol`
- Possibly other batch allocation assertions under `test/unit/` that hard-code truncated shares
- Handler unit tests / harness subclasses that override `depositToken` / `withdrawToken` as `public`
  (follow compiler errors; name extras in the PR)
- `docs/relaunch/README.md` (assignment status on the implementation PR)

## Required tests

Targeted first:

```bash
SWAP_TYPE=mocSwaps LENDING_PROTOCOL=sovryn STABLECOIN_TYPE=DOC forge test --match-contract PurchaseRbtcTest
SWAP_TYPE=mocSwaps LENDING_PROTOCOL=sovryn STABLECOIN_TYPE=DOC forge test --match-contract BatchMinRbtcOutTest
SWAP_TYPE=mocSwaps LENDING_PROTOCOL=sovryn STABLECOIN_TYPE=DOC forge test --match-contract NetRedemptionTest
STABLECOIN_TYPE=USDRIF LENDING_PROTOCOL=layerbank SWAP_TYPE=dexSwaps forge test --match-contract PurchaseUniswap
SWAP_TYPE=mocSwaps LENDING_PROTOCOL=sovryn STABLECOIN_TYPE=DOC forge test --match-path test/unit/TokenHandler*
SWAP_TYPE=mocSwaps LENDING_PROTOCOL=idle STABLECOIN_TYPE=DOC forge test --match-contract Idle
```

Behaviors to assert:

- A multi-buyer batch credits every measured wei of rBTC: `sum(getAccumulatedRbtcBalance(buyer_i))`
  increases by exactly the measured batch output (no stranded native wei from floor division).
- Single-buyer batches are unchanged (remainder is zero or the sole buyer receives it).
- Deposit and withdraw through DcaManager still pull/push the full requested amount (or the existing
  lending/idle clamps); `onlyDcaManager` still rejects a direct EOA call on the handler.
- `OperationsAdmin.assignTokenHandler` still accepts `ITokenHandler` / `ITokenLending` via ERC-165
  after the IERC165 import move (existing assignment tests).
- Dex purchase path still approves the router and still reverts on R59 partial-input / intermediate
  mismatches; no new approve-related revert under a fresh allowance.
- Sibling MoC path unchanged.
- Selectors for `depositToken` / `withdrawToken` / `setPurchasePath` are unchanged (`forge inspect`
  methodIdentifiers equal on those three before vs after, or the existing suite is the proof).

Fork tests: no new fork-specific assertions. Still run `make fork-sovryn` and `make fork-tropykus`
before push (`AGENTS.md`).

Done-gate: `make check`, then the forks above. Prefer also `make check-deploy` if the Dex size delta
is material enough to want the shipping profile in the PR record.

## Success criteria

- [ ] One IERC165 import source in production `src/` (OpenZeppelin); no forge-std interface import
      from `src/`.
- [ ] No `TransferHelper` import or call in `src/`; Dex approve goes through `SafeERC20.forceApprove`.
- [ ] Handler deposit/withdraw ABI entries are `external`; overridable bodies are `internal virtual`
      helpers; no `super.depositToken` / `super.withdrawToken` remains.
- [ ] `setPurchasePath` is `external`.
- [ ] Public immutables / constants used for construction wiring are unchanged.
- [ ] After every successful `batchBuyRbtc`, the sum of per-buyer accumulated-rBTC credits equals the
      measured rBTC that batch received.
- [ ] NatSpec states the last-buyer remainder rule without R-ids.
- [ ] Tests that previously expected truncated shares now expect full conservation; suite green on
      `make check` and both forks.
- [ ] Implementation PR records Dex/handler runtime size delta and any consumer note (expect none: no
      ABI change).

## Reviewer checklist

- [ ] Matches **Scope**; nothing from **Out of scope**.
- [ ] Protocol invariants in `AGENTS.md` still hold (invariant 3 especially: rBTC still pays the
      signer; dust goes to a buyer's books, not an owner sweep).
- [ ] Tests in the PR match **Required tests**.
- [ ] Files beyond this list are limited to direct dependencies and are named in the PR.
- [ ] No unrelated refactors; history is reviewable.
- [ ] Licensing section is not reopened or "solved" by this PR — only the compiled `TransferHelper`
      dependency is removed.
- [ ] Visibility change is style-only: same selectors, same `onlyDcaManager` gate, same cash
      accounting.

## ABI / deploy / cutover impact

- ABI: none. No selector, event, error, or mutability change. `public` → `external` on an
      already-external interface method does not change the ABI JSON. Behavior change is internal
      credit conservation only (last buyer may receive up to `n − 1` extra wei of rBTC per batch vs
      today).
- Scripts: none.
- Cutover: none expected. No consumer ABI change. If monitoring ever asserted that per-buyer rBTC
  event amounts sum to less than the batch total, update that assertion — check
  `bitchill-monitoring` before closing the implementation PR and comment on the existing R68/R67
  thread if needed rather than opening a duplicate issue.
