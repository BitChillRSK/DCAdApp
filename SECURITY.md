# Security Policy

## Reporting a Vulnerability

Security vulnerabilities should be reported to the BitChill team:

- Email: arynyestos@gmail.com

Please include enough detail to reproduce the issue. Do not open a public GitHub issue for an unfixed vulnerability in a live deployment.

## Bug Bounty

We appreciate responsible disclosure. There is **no formal bug-bounty program** and **no guaranteed reward amount**. Significant, good-faith reports may be acknowledged and rewarded at BitChill's discretion.

## Immutable deployments — no patch / backport promise

Production BitChill contracts are **immutable** (no proxies, no upgradeability). A vulnerability in a deployed
bytecode cannot be patched in place. Incident response is:

1. Operational containment (revoke swapper, pause deposits per route, disable bot routes).
2. Deploy fixed contracts at **new** route indexes where needed.
3. Users exit the old handlers and re-enter on the new routes (manual exit/re-entry; no owner migration of user funds).

There is therefore **no** “security patch for version 1.x” or “backport to past major releases” for on-chain
code. Off-chain consumers (front-end, bot, monitoring) may still receive updates.

## Supported Versions

| Artifact | What “support” means |
| -------- | -------------------- |
| Current relaunch deployment (post-cutover) | Incident response as above; consumer updates |
| Pre-relaunch mainnet contracts | Users should exit; no further on-chain patches |

## Legal / license

First-party `src/` is licensed under **Business Source License 1.1** (see [`LICENSE`](./LICENSE)), with an
Additional Use Grant for non-production use and a Change License of `GPL-2.0-or-later` after the Change Date.
`script/` and `test/` remain MIT. Smart contracts carry technical risk; use is at your own risk.

---

For questions: arynyestos@gmail.com.
