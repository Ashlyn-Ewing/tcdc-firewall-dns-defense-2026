# TCDC SMC 2026 — Rival reachability assessment (Team 2)

Read-only, rate-limited network service inventory for Teams **1, 3, 4, 5, and 6**. Derives **eight published host addresses per team** from the official packet, with **one expected TCP port per host** (40 total). Team 2 is excluded. No network sweeps, authentication, exploitation, modification, disruption, stealth, or persistence.

## Usage

Preview targets without sending network traffic:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\rival-assessment\Invoke-TCDCRivalAudit.ps1
```

After Black Team tool approval, hands-on authorization, and confirmation of permitted execution location, run in an **approved in-range PowerShell environment**:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\rival-assessment\Invoke-TCDCRivalAudit.ps1 -Run -Authorized -ReportDirectory .\reports
```

The second command additionally requires entering `CHECK`. Defaults are 1.2-second timeout and 1-second delay between connection attempts. Results are written to a CSV in the chosen directory.

## Rules and limitations

- R20 requires public repository submission via Tool Links. Publication is **not** approval.
- R21 prohibits AI usage during competition. Confirm with Black Team whether pre-event AI-assisted resources may be used.
- R23 prohibits exporting competition artifacts. Keep reports in approved in-range storage; do not copy them to personal devices or publish them.
- R10 forbids activity during hands-off periods. R6 scope applies only to matching boxes.
- Reachable TCP port does **not** establish version, vulnerability, CVE applicability, or scoring health.
- Do not operate the script from a disallowed location. It is not tested against live competition infrastructure.
