# Cutover runbook — relaunch (R73)

Human operator only. Agents must not `--broadcast`.

## Preconditions

1. Merge stack through R72; tip commit is the one that will deploy.
2. Green on that exact commit:
   - `make check`
   - `make check-deploy`
   - `make fork-sovryn`
   - `make fork-tropykus`
   - `make fork-dex-path` (Dex path allowlist)
3. Static analysis triaged in [`R73-RELEASE_RECORD.md`](./R73-RELEASE_RECORD.md).
4. `RSK_MAINNET_RPC_URL`, Blockscout verifier URL, deployer keystore/Ledger ready.
5. `INITIAL_SWAPPER` = production bot EOA (non-zero).
6. Safe (`MAINNET_OWNER`) and fee collector (`MAINNET_FEE_COLLECTOR`) match `script/Constants.sol`.

## Deploy

```bash
REAL_DEPLOYMENT=true \
INITIAL_SWAPPER=<bot-eoa> \
FOUNDRY_PROFILE=deploy \
forge script script/DeployFinal.s.sol:DeployFinal \
  --rpc-url $RSK_MAINNET_RPC_URL \
  --account <deployer-eoa> \
  --broadcast --legacy \
  --verify --verifier blockscout --verifier-url $BLOCKSCOUT_API_URL
```

`DeployFinal.run()` is **mainnet-only** (fail-closed incomplete map on testnet). For a
`via_ir` Rootstock **testnet** bytecode proof, use a representative component script under
`FOUNDRY_PROFILE=deploy` (see R60); that is not a substitute for this full-stack mainnet cutover.

## After broadcast

1. Copy every address from the script log into the consumer issue / ops sheet.
2. From the Safe, `acceptOwnership()` on `OperationsAdmin`, `DcaManager`, and all seven handlers.
3. Confirm Dex `getSwapPath()` on each Dex handler matches the intended route (constructor
   already allowlisted it).
4. Confirm `isSwapper(INITIAL_SWAPPER)` and per-token mins (DOC/USDRIF `25 ether`, USDT0 `25e6`).
5. Publish addresses to `front-end`, `swapper-bot`, `data-api`, `bitchill-monitoring`,
   `metrics-dashboard`.
6. Enable bot ticks only after a successful dry-run simulation against the new stack.

## Abort / rollback

Immutable contracts: do not “patch.” Abort before Safe accept if verification or wiring is wrong
(deployer EOA still owns until accept). After accept, recovery is new route indexes + user
exit/re-entry (R13), never same-index overwrite or owner rescue.

## Compromised swapper

`revokeSwapper` **before** revoking purchase paths. Then restore preferred path if needed.
See README “Compromised swapper.”

## Ops history note

Standing `redeemDocRequest` queue entries on **pre-relaunch** MoC handlers: checked and closed
2026-09-07 (no stranded DOC / no unexpected settlement observed across ~2 years of that call
pattern). Relaunch handlers do not call `redeemDocRequest`.
