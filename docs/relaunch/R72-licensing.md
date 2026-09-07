# R72 — License BUSL-1.1 and close the GPL compliance gap

Status: **implemented** · Assigned: yes · Optional/further-review: no · Order: after R71 source phase, before README/audit/security truthfulness (R73) · Implementation: [#129](https://github.com/BitChillRSK/dca-contracts/pull/129), stacked on [#128](https://github.com/BitChillRSK/dca-contracts/pull/128)

## Objective

Answer the licensing question `IMPLEMENTATION_ORDER.md` reopened on 2026-08-31: publish a `LICENSE`
file, move `src/` from `MIT` to `Business Source License 1.1` (4-year term, `GPL-2.0-or-later` change
license), and close the compliance gap that existed regardless of that choice — `PurchaseUniswap` and
`IPurchaseUniswap` imported `GPL-2.0-or-later` Uniswap router interfaces under an `MIT` declaration.
`script/` and `test/` stay `MIT` — they are tooling, never deployed.

## Background

See **Licensing — reopened** in `IMPLEMENTATION_ORDER.md` for the original analysis. Summary of the
decision actually made:

- **Which license.** BUSL-1.1 over Apache-2.0. BitChill is a self-contained product (DCA schedules,
  a fee switch, deployed liquidity) rather than an infrastructure primitive — a directly copyable
  target in the way Uniswap v3 or Aave v3 were when they chose BUSL, and a more nameable forker than
  the "moat is the integrations, not the Solidity" framing in the original note assumed. Every commit
  touching `src/` is one author (`Ynyesto` / `arynyestos`, same person), so relicensing has no
  third-party consent problem.
- **Term.** 4 years, the BUSL maximum, matching Uniswap v3 and Aave v3.
- **Change License.** `GPL-2.0-or-later`, not Apache-2.0: BUSL requires the Change License be
  GPL-compatible, and Apache-2.0 is not GPLv2-compatible. `GPL-2.0-or-later` also matches Uniswap's
  own choice, which makes the compliance gap below moot after conversion.
- **Additional Use Grant.** Explicit non-production carve-out (testing, security research, audits,
  academic use, public testnets) so the license does not read as maximally hostile to the people who
  need to inspect the code before it is trusted with funds.
- **Caveat, stated plainly.** Every commit already merged before this PR is `MIT` and stays `MIT`
  forever — verified source on Rootstock explorers is immortal regardless of any header. BUSL protects
  the relaunch-forward diff, not the two years of code already public. Given the relaunch is close to
  a full rewrite, that is still most of the value, but it is not everything.
- **Not resolved here, and not resolvable by an agent:** the `Licensor` legal entity name in `LICENSE`
  is a placeholder (`BitChill`, matching the project's own branding) pending confirmation from counsel.
  Whether Rootstock ecosystem grant programs BitChill may want require an OSI-approved license (BUSL
  is not one) is also unconfirmed — check before committing to grant applications that assume it.

### The compliance gap (independent of the license choice)

`src/PurchaseUniswap.sol` and `src/interfaces/IPurchaseUniswap.sol` imported
`@uniswap/swap-router-contracts`'s `ISwapRouter02` / `IV3SwapRouter`, both `GPL-2.0-or-later`, while
every `src/` file (including these two) declared `SPDX-License-Identifier: MIT`. `PurchaseUniswap`
only ever calls one function on that surface, `exactInput`. Both files now import a first-party
`src/interfaces/IUniswapV3SwapRouter.sol` (same license as the rest of `src/`) declaring only that
function and its `ExactInputParams` struct — an ABI-identical narrower view of the same deployed
SwapRouter02, not a new or different contract. This closes the gap outright rather than narrowing it:
no GPL import remains anywhere under `src/`.

`test/mocks/MockSwapRouter02.sol` already declared its own local minimal `IV3SwapRouter` and never
imported the GPL package. `test/mainnet-debug/dex-quote-floor/DexQuoteFloorProbe.t.sol` likewise
already declares its own local `IV3SwapRouterLike`. Neither needed a change.

## Open product decisions

**none** — answered above; this file records the decision, it does not ask it.

## Scope

- [x] `LICENSE` at repo root: BUSL-1.1, `Licensor` placeholder pending counsel, `Licensed Work`
      "BitChill Smart Contracts", 4-year Change Date, `GPL-2.0-or-later` Change License, an
      Additional Use Grant carving out non-production use.
- [x] Every `src/**/*.sol` file: `SPDX-License-Identifier` `MIT` → `BUSL-1.1` (43 files, including
      the new interface below). `script/` and `test/` stay `MIT`.
- [x] New `src/interfaces/IUniswapV3SwapRouter.sol`: first-party `exactInput`-only surface.
- [x] `src/PurchaseUniswap.sol`, `src/interfaces/IPurchaseUniswap.sol`: import the new interface
      instead of the GPL package; no behavior change (identical selector, identical struct layout).
- [x] Every `script/` and `test/` file that only used `ISwapRouter02` as a cast/type for
      `UniswapSettings.swapRouter02` (14 files): same mechanical swap, still `MIT`.

## Out of scope

- [ ] `README.md` / `SECURITY.md` / `audits/README.md` prose describing the license — R73 owns making
      those documents describe the deployed code truthfully, once README/SECURITY/audits phase starts.
      Doing it here would mean writing it twice against a still-moving R73 scope.
- [ ] Confirming the `Licensor` legal entity name, the exact Change Date if cutover slips past
      2030-09-07, or grant-program OSI requirements — human/counsel, not a source change.
- [ ] Re-licensing `script/` or `test/` — never deployed, no reason to restrict.

## Files likely touched

`LICENSE` (new); `src/interfaces/IUniswapV3SwapRouter.sol` (new); every other `src/**/*.sol` (SPDX
line only, except `PurchaseUniswap.sol` / `IPurchaseUniswap.sol` which also change an import and two
type names); `script/DeployDexSwaps.s.sol`, `script/DeployUsdrifHandler.s.sol`,
`script/DeployMocAndUniswap.s.sol`; the 13 test files listed in the PR that cast a mock/config address
to `ISwapRouter02` for `UniswapSettings.swapRouter02`.

## Required tests

- `forge build`: clean compile, no `ISwapRouter02` / `IV3SwapRouter` import anywhere under `src/`,
  `script/`, or `test/` outside `test/mainnet-debug/dex-quote-floor/` (which never imported them).
- `make check`: unchanged pass/fail counts across every lane — this PR changes no runtime behavior,
  only license headers and an interface's declaring file.
- `make fork-sovryn` / `make fork-tropykus`: unchanged counts, same reason.

## Success criteria

- [x] `grep -rl "@uniswap/swap-router-contracts" src/ script/ test/` matches nothing outside the new
      interface file's own NatSpec comment.
- [x] `grep -rL "SPDX-License-Identifier: BUSL-1.1" src/**/*.sol` is empty.
- [x] `forge build` exits 0.
- [ ] `make check` and `make fork-sovryn` exit 0 with unchanged counts (run before push).

## Reviewer checklist

- [ ] Matches **Scope**; nothing from **Out of scope**.
- [ ] No `src/` behavior changed — this is a license/import-source change only.
- [ ] `LICENSE` parameters (Change Date, Change License, Additional Use Grant) match the decision
      recorded in `IMPLEMENTATION_ORDER.md`.
- [ ] No unrelated refactors; history is reviewable.

## ABI / deploy / cutover impact

- ABI: none. `IUniswapV3SwapRouter.exactInput` has the identical selector and struct layout as the
  Uniswap interface it replaces; this is a source-level (compile-time) change only.
- Scripts: `script/DeployDexSwaps.s.sol`, `script/DeployUsdrifHandler.s.sol`,
  `script/DeployMocAndUniswap.s.sol` — type of a cast changed, target address unchanged.
- Cutover: none. Counsel should confirm the `Licensor` legal name and the Change Date before the
  license is treated as final; neither blocks deployment.
