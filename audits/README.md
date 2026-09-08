# Security Audits

BitChill has two published reviews by the same independent researcher. They are **historical** reviews of
pre-relaunch code. They are not a substitute for reviewing the 2026 relaunch diff, and they are **not**
independent multi-firm audits.

## Audit Reports

| Date | Auditor | Scope (at the time) | Findings | Report |
|------|---------|---------------------|----------|--------|
| April 2025 | [Ivan Fitro](https://twitter.com/FitroIvan) | Then-current protocol (Tropykus/Sovryn MoC stack) | 3 Medium, 4 Low, 2 Info | [PDF](./2025-04-29-Ivan-Fitro.pdf) |
| June 2025 | [Ivan Fitro](https://twitter.com/FitroIvan) | Mitigations + Uniswap V3 integration | 1 Low, 1 Info | [PDF](./2025-06-02-Ivan-Fitro.pdf) |

Both engagements were performed by **Ivan Fitro** (later of Pashov Audit Group / OpenZeppelin). Same auditor
twice is useful continuity; it is not “multiple independent audits.”

## What those reports covered

### Initial review (April 2025)

Contracts then named differently in places (`AdminOperations`, `TropykusDocHandler`, schedule-id model, stuck-fund recovery paths, etc.). Findings listed in the PDF were addressed in that generation of the codebase.

### Mitigation + Uniswap review (June 2025)

Follow-up on prior mitigations plus `PurchaseUniswap` / Dex handler surface as it existed then.

## Relaunch status (2026)

The relaunch stack (OpenZeppelin **v5.7.0**, solc **0.8.36** / `cancun`, idle + LayerBank + Sovryn route map,
BUSL-1.1 on `src/`, protected purchase window, exact lending-share consumption, and related work) has
**not** received a separate third-party audit as of this writing unless a later report is added here.

Treat the PDFs as evidence about the **2025** code under review, not as a claim that every 2026 change was
re-audited. Several mitigations described in older summaries (for example owner stuck-rBTC rescue, or the
old schedule-id construction) were later removed or redesigned on purpose — see the relaunch specs under
[`docs/relaunch/`](../docs/relaunch/).

Static analysis at cutover (`make slither`, `make aderyn`) is triaged in
[`docs/relaunch/R73-RELEASE_RECORD.md`](../docs/relaunch/R73-RELEASE_RECORD.md); analyzers are not audits.
