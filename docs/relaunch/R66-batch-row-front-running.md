# R66 — Protected purchase window for batch-row front-running

Status: **assigned** · Assigned: yes · Optional/further-review: no

## Objective

Give the swapper a narrowly bounded incident-response mechanism for a malicious schedule owner who
repeatedly changes their own row after the bot has prepared a batch, causing the shared purchase to
revert or to execute against a stale absolute minimum. The mechanism is dormant by default: an
authorized swapper may open one five-block protected purchase window per UTC day, during which only
the user mutations that can invalidate an already prepared batch are refused.

This is an explicit proportionality decision. Normal batches keep their existing all-or-nothing
semantics and gas cost. Benign same-block edits may still revert a batch when no protected window was
opened; the protocol accepts that availability risk rather than permanently redesigning the manager,
handler funding hooks, calldata, and purchase ABI around a low-incentive denial-of-service scenario.

## Background

Found during review of [R64](./R64-batch-calldata-and-schedule-keying.md) (PR
[#119](https://github.com/BitChillRSK/dca-contracts/pull/119)). A batch is composed off-chain, then
`DcaManager` reads current storage when the purchase lands. In between, a schedule owner can pause,
delete, withdraw from, or edit a quoted schedule. The resulting row revert unwinds every other row in
the batch. Raising `purchaseAmount` is different: the purchase may proceed with an absolute
`minRbtcOut` that was quoted for a smaller input and therefore no longer expresses the intended price
tolerance.

The chosen response is an opt-in cross-transaction execution window:

1. An authorized swapper calls `activateProtectedPurchaseWindow` and waits for inclusion.
2. Once the lock is onchain, the bot refreshes the relevant state and rebuilds or simulates the batch.
3. The bot broadcasts the purchase only after the activation receipt, and before the five-block window
   ends.

The repository's indexer treats 12 Rootstock confirmations as finalized, but the protected flow acts
on inclusion rather than waiting for that threshold. Five blocks therefore provide four subsequent
inclusion opportunities, not finality. [Rootstock's block-time proposal](https://ips.rootstock.io/IPs/RSKIP517.html)
describes a 14-second target and roughly 24-second observed main-block interval, so that is typically
around one to two minutes rather than a guaranteed wall-clock duration. If operations later require waiting 12
confirmations after activation, or cannot reliably refresh and submit inside those four following
blocks, this fixed window is too short and must be revisited before adopting that workflow. The same
is true if one tick must be split beyond those four opportunities: R64 measured roughly 525 rows per
transaction, so a tick materially above 2,000 rows could leave a tail outside the protected window.

Activation is a once-per-day budget, not a purchase reservation. If the protected purchase fails for
an unrelated reason, the activation remains consumed and a retry that day is unprotected. Nothing
onchain requires a purchase to land before `N + 5`; the bot must enforce that deadline. UTC-day
eligibility uses `block.timestamp / 1 days`, whose day-boundary attribution a block producer can
influence slightly. In the colluding-producer edge case this can admit one additional bounded window,
not an indefinite lock, because a live window still cannot be extended.

### Why the absolute minimum stays

A rate applied to measured spend is useful when a lending redemption returns less stablecoin than
planned: it preserves the quoted *price* floor while scaling the required rBTC down with the actual
input. The current absolute minimum is stricter in amount terms and may revert instead. That is a
liveness improvement, not additional protection against the owner front-run once the protected
window prevents `purchaseAmount` and the funding book from changing after the refreshed snapshot.

Changing to a rate would also alter bot semantics and thread new arithmetic through `DcaManager`,
`PurchaseRbtc`, `PurchaseUniswap`, and their interfaces. R66 therefore keeps `minRbtcOut` absolute.
A future item may reconsider rate semantics on their independent merits, but they are not part of
this denial-of-service response.

## Open product decisions

**none** — decided 2026-09-06:

- Five-block global window, fixed in code.
- At most one activation per UTC day, enforced onchain. An authorized swapper cannot extend an active
  window across a UTC-day boundary or renew it after expiry on the same UTC day.
- The lock is dormant until a swapper activates it. Purchases never require activation.
- Only mutations that can invalidate an already prepared row are blocked. Reads, deposits, schedule
  creation, interest top-ups, accumulated-rBTC withdrawals, purchases, and governance setters remain
  available.
- Keep the existing absolute `minRbtcOut`, batch calldata, handler ABI, funding behavior, and
  all-or-nothing batch semantics.

## Scope

- [x] Add `activateProtectedPurchaseWindow`, callable only by an address currently authorized as a
      swapper by the constructor-pinned `OperationsAdmin`.
- [x] Store the block at which user mutations resume and the UTC day of the latest activation in one
      packed storage slot.
- [x] Lock exactly five block heights including the activation block: activation in block `N` allows
      the guarded functions again in block `N + 5`.
- [x] Reject a second activation in the same UTC day, including after the first window expired.
- [x] During the window reject `updatePurchaseAmount`, `updatePurchasePeriod`, `setSchedulePaused`,
      `deleteDcaSchedule`, `withdrawToken`, `withdrawTokenAndInterest`, and
      `withdrawAllAccumulatedInterest`.
- [x] Keep `depositToken`, `createDcaSchedule`, `topUpFromInterest`, accumulated-rBTC withdrawals,
      getters, owner setters, and both purchase entry points available.
- [x] Add public getters for the unlock block and current activation eligibility, an activation event,
      and distinct custom errors for the window and its once-per-day limit. Index only the activating
      swapper address.
- [x] Update the durable invariant and consumer follow-ups for the new public surface.

## Out of scope

- [ ] Skipping stale or underfunded rows.
- [ ] Packed expected purchase amounts or a batch sorting requirement.
- [ ] Changing `minRbtcOut` from an absolute amount to a rate.
- [ ] Moving schedule effects after the handler call or adding handler-to-manager funding results.
- [ ] Cross-handler isolation in `batchBuyRbtcAcrossHandlers`.
- [ ] Exact equality between user shares debited and protocol shares redeemed; deferred to
      [R67](./R67-exact-batch-share-accounting.md).
- [ ] Changes to handlers, purchase routes, or deploy scripts.

## Files likely touched

- `src/DcaManager.sol`
- `src/interfaces/IDcaManager.sol`
- `test/unit/ProtectedPurchaseWindowTest.t.sol`
- `AGENTS.md`
- `docs/relaunch/README.md`
- `docs/relaunch/IMPLEMENTATION_ORDER.md`
- `docs/relaunch/R67-exact-batch-share-accounting.md`

## Required tests

- `forge test --match-path test/unit/ProtectedPurchaseWindowTest.t.sol`
- A swapper can activate a window; an unauthorized account cannot.
- Activation at block `N` blocks every listed mutation in blocks `N` through `N + 4`, and each is
  available again at `N + 5`.
- A second activation on the same UTC day reverts both while the first window is live and after it
  expires. A next-day activation still reverts while the old window is active, then succeeds after
  it expires.
- Deposits, creation, top-ups, accumulated-rBTC withdrawals, owner setters, and purchases do not take
  the lock modifier. Structural assertions should make additions or removals from the guarded set
  visible in review.
- A batch prepared after activation succeeds while an attempted owner mutation is locked.
- Existing absolute-minimum behavior and batch ABI remain unchanged.
- Fork tests add no R66-specific assertions, but `make fork-sovryn` and `make fork-tropykus` remain the
  before-push gate.

## Success criteria

- [x] Once activation is included and the bot refreshes its snapshot, no guarded owner mutation can
      invalidate the refreshed batch during the five-block window.
- [x] No authorized swapper can extend an active window or activate more than once in one UTC day.
- [x] The mechanism adds no storage write and no lock branch to an ordinary purchase transaction.
- [x] No handler or purchase-route implementation changes.
- [x] The existing `Batch` and `IPurchaseRbtc` ABIs and absolute-minimum semantics are unchanged.
- [x] `make check`, `make fork-sovryn`, and `make fork-tropykus` pass.

## Validation record

- `SWAP_TYPE=mocSwaps LENDING_PROTOCOL=sovryn STABLECOIN_TYPE=DOC forge test --match-path
  test/unit/ProtectedPurchaseWindowTest.t.sol`: 8 passed.
- `make check`: all unit/fuzz lanes passed (839 tests in the final reported lane set), then all 11
  Sovryn invariants passed at 64 runs × 512 calls with zero reverts.
- `make fork-sovryn`: 381 passed, 26 skipped.
- `make fork-tropykus`: 374 passed, 30 skipped.
- Default-profile `DcaManager` runtime is 14,200 B versus 13,487 B at the exact PR base: +713 B.
- On the MoC/Sovryn test, `testSinglePurchase` is 248,667 gas versus 248,843 at base (−176), and the
  five-row `testBatchPurchasesOneUser` is 1,789,828 versus 1,789,481 (+347, 0.019%). There is no
  window read in either purchase entry; this tiny movement is compiler/dispatcher layout, not a
  per-row lock cost. Activation writes its explicitly packed `uint96` window word once. Guarded user
  calls do pay one permanent cold read: the MoC/Sovryn sentinel `withdrawToken` fixture is 108,608
  gas versus 106,888 at base (+1,720, 1.61%), and `withdrawTokenAndInterest` is 176,615 versus
  174,575 (+2,040, 1.17%).

## Reviewer checklist

- [x] Matches **Scope**; nothing from **Out of scope**.
- [x] The guarded function list is exact: every mutation that can invalidate a prepared row is
      covered, and unrelated exits are not.
- [x] The once-per-UTC-day rule prevents indefinite lock renewal by a swapper.
- [x] Protocol invariants in `AGENTS.md` still hold.
- [x] Files beyond this list are limited to direct dependencies and are named in the PR.
- [x] No unrelated refactors; history is reviewable.

## ABI / deploy / cutover impact

- ABI: adds `activateProtectedPurchaseWindow()`, protected-window unlock and eligibility getters, one
  activation event, and three custom errors. Existing selectors, structs, events, and parameter
  meanings are unchanged.
- Scripts: none.
- Cutover: the swapper bot gains an incident flow: activate, wait for inclusion, refresh/simulate, then
  purchase within the window. The bot can preflight today's activation eligibility. The frontend
  should present the temporary retry block when a guarded user mutation is refused. Monitoring should
  ingest the activation event and new errors. Update the
  existing R64/R66 follow-up issues rather than opening duplicates. Final corrections:
  [swapper-bot#7](https://github.com/BitChillRSK/swapper-bot/issues/7#issuecomment-5558374581),
  [bitchill-monitoring#10](https://github.com/BitChillRSK/bitchill-monitoring/issues/10#issuecomment-5558375453),
  and [front-end#24](https://github.com/BitChillRSK/front-end/issues/24#issuecomment-5558376270).
