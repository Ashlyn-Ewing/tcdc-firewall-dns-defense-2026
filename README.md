# TCDC SMC 2026 — Firewall and DNS Defense Preparation

**Status: unapproved example toolkit. Not tested on competition infrastructure.** Built for defensive preparation and staff review. This repo contains no competition secrets, addresses, host configuration or logs.

## Packages

- `runbook/NO_CUSTOM_TOOL_RUNBOOK.md`: manually entered built-in commands, host recovery decision trees and incident checklist. Ask staff whether this static material is allowed under R21.
- `toolkit/tcdc_dns.sh`: custom Ubuntu BIND read-only audit / watch; explicit `recover` restarts **only** a stopped BIND service after named-checkconf validation. Does not modify zones, firewall rules, software packages or accounts.
- `toolkit/tcdc_opnsense.sh`: read-only OPNsense audit. Never writes firewall rules.
- `toolkit/TCDC-Launcher.ps1`: optional Windows OpenSSH wrapper for already deployed, approved remote scripts. Needs SSH user and host parameters. No installation/configuration transport is built in.

## R20 / R21 — mandatory approval

Under the supplied official packet, any **custom tool** must be published in a publicly accessible repository and submitted to Black Team through the **Tool Links** form (R20). R21 prohibits AI use during the event; obtain a Black Team ruling on pre-event AI-assisted static guides and scripts. Publishing a repository does **not** imply approval. Do not use these custom scripts on competition hosts before staff authorization. Confirm approved install/run locations and whether unattended monitoring is permitted through hands-off periods.

## Pre-event safe test on a throwaway VM (not competition infrastructure)

On an Ubuntu VM with BIND or test DNS:

```bash
bash -n toolkit/tcdc_dns.sh
sudo bash toolkit/tcdc_dns.sh audit
```

On a separate OPNsense lab VM, if permitted:

```sh
sh -n toolkit/tcdc_opnsense.sh
sh toolkit/tcdc_opnsense.sh audit
```

Run only after manually verifying each command and the effect. `recover` deliberately restarts services; test that **only on your own lab VM**. The Windows launcher requires the host-specific scripts on authorized systems and existing SSH key-based access; it does not transfer files. Only deploy with staff approval.

## Operational limits

- Never run the toolkit against the protected jumpbox, shared subnets, other teams, or unapproved targets.
- Leave protected accounts, staff agents, scorekeeping, infrastructure and sensitive data unchanged.
- Logs and configuration backups must remain in approved **in-range** storage under R23. Do not copy them to your personal computer or GitHub.
- No auto firmware updates, arbitrary package installation, exploit testing, firewall-rule deletion, account disabling or unreviewed backup restores.
- DNS `watch` runs until manually stopped; stop before any hands-off period unless staff explicitly permits ongoing monitors.
- Service liveness is not scored service correctness. Use authorized zone-specific tests and the scoring dashboard.
- No vulnerability can be presumed absent based on this tool; check official upstream advisories and perform controlled patching only with team authorization.

## Example Windows launcher (only after approval and deployment)

```powershell
.\toolkit\TCDC-Launcher.ps1 -Mode DnsAudit -DnsHost 'AUTHORIZED_DNS_HOST' -FirewallHost 'AUTHORIZED_FIREWALL_HOST' -SshUser 'AUTHORIZED_USER'
```

## Staff submission checklist

1. Make this repository **public**, verify it contains no secrets or competition output, and submit the exact URL via the event **Tool Links** form.
2. Disclose this kit was generated with pre-event AI assistance; request a clear ruling under R21.
3. Explain that manual commands are separate from the custom scripts and ask if the runbook is permitted.
4. Test in a lab before the event (R24); capture screenshots or textual test summary *outside the competition*.
5. Record staff approval, allowed paths, approved time windows, and restrictions before using any script.

## Stop / removal

Use Ctrl+C to stop `watch`; no background systemd jobs or scheduled tasks are installed. Files can be removed by authorized administrators, without changing OS firewall or service configuration. No user credentials are stored.
