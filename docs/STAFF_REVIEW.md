# Black Team review request

**Request:** Permission to use a small custom defensive script toolkit on assigned OPNsense firewall and Ubuntu BIND DNS host, only in authorized hands-on periods. The scripts were drafted with AI **before** the competition and will not use AI during the event. Please confirm whether this pre-event content is allowed under R21.

**Repository:** <insert-public-GitHub-URL>

**Files submitted:** `toolkit/tcdc_dns.sh` (audit/watch + explicitly requested, validated stopped-service restart); `toolkit/tcdc_opnsense.sh` (read-only firewall audit); `toolkit/TCDC-Launcher.ps1` (SSH launch wrapper), and manual `runbook/NO_CUSTOM_TOOL_RUNBOOK.md`.

**No:** installation of packages, upload of data to cloud, scanning outside assigned hosts, exploit attempts, automated firewall/routing modification, credential collection, agent persistence, background scheduler deployment or automatic patching.

**Questions:** Is this pre-event AI-assisted material allowed? Are custom wrappers permitted? Where may files be copied and run? May continuous watch run during hands-off or must it be stopped? Are built-in manual commands in the runbook approved? What is the correct Tool Links submission destination?

**Test plan:** Shell syntax checks + read-only audit in disposable test VMs; manually test BIND restart in a test VM with known config; record results and disclose unexpected behavior before use.
