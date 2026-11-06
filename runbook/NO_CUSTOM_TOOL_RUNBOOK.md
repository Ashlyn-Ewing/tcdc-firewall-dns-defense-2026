# TCDC SMC — No-Custom-Tool Firewall and DNS Runbook

**Pre-event reference; staff rulings control.** Use only after Black Team has authorized hands-on work, on your assigned OPNsense firewall or Ubuntu DNS host. Avoid hands-off periods and the protected jumpbox. No AI during competition (R21). Verify with staff whether these built-in command families are permitted. Do not paste credentials, host dumps, logs or competition configuration into a public repository or move them off the range.

## Before each change

1. Identify the correct assigned host and connect through the authorized route/client.
2. Use read-only checks first. Check the live scoring dashboard and the actual application behavior.
3. Record pre-change state and keep backups **on approved in-range storage**, not on your personal laptop.
4. Make one change at a time. Re-test DNS from the authorized checker perspective and firewall paths afterward.
5. Do not modify protected accounts, Wazuh/auditd, Xen Orchestra, cloud-init, scoring, jumpbox or staff infrastructure. Observe R18 firewall-filtering constraints.

## A. OPNsense firewall (OPNsense console or authorized SSH)

### 1. Identify platform and services (read-only)
```sh
uname -a
opnsense-version
service -e
sockstat -4 -6 -l
netstat -rn
ifconfig -a
```

### 2. Firewall state and policy inspection (read-only)
```sh
pfctl -si
pfctl -sr
pfctl -sn
pfctl -ss | head -n 60
```

**Warning:** Do not run `pfctl -d`, `pfctl -F all`, or automatic generic deny rules. Respect R18. Inspect the GUI: Firewall > Rules and Firewall > NAT, plus System > Firmware > Status for available security updates. The GUI update requires explicit change approval and a verified rollback route; never upgrade mid-outage without coordination.

### 3. Check configuration and security logs (read-only)
```sh
ls -l /conf/config.xml
find /var/log -maxdepth 2 -type f -name '*.log' | head -n 40
last -n 20
```

For incident review, use the OPNsense UI `System > Log Files` and `Firewall > Log Files > Live View`. Use Settings > Configuration > Backups to make an approved **in-range** backup. Do not export it to a personal laptop. Note unusual users, VPN connections, NAT/rule additions, and new admin access. Inspect, do not indiscriminately remove accounts or rules.

### 4. Recovery decision tree (manual)
1. If firewall management is unavailable, check authorized console access and link/interface state (`ifconfig -a`).
2. If routing failed, review `netstat -rn`, interface assignments and gateways in the OPNsense GUI. Do not blindly reset the firewall.
3. If scoring broke after a rule change, revert **that one identified change**, then re-test expected application behavior.
4. If a malicious change is confirmed, record evidence, use an approved known-good backup via the GUI only with team approval, then verify access, NAT, routes and score.
5. If firmware is vulnerable, check release notes / package updates from the official OPNsense GUI, approve a maintenance window and verify application health after update. No automatic firmware upgrade here.

## B. Ubuntu DNS (authorized SSH terminal on `ns1`)

### 1. Identity, sockets and services (read-only)
```sh
cat /etc/os-release
hostnamectl
sudo ss -lntup
systemctl --no-pager --type=service --state=running
systemctl status named --no-pager || systemctl status bind9 --no-pager
```

### 2. BIND validation and local DNS tests (read-only)
```sh
command -v named-checkconf
sudo named-checkconf -z
sudo named-checkconf -p | head -n 80
sudo journalctl -u named -u bind9 --since '30 minutes ago' --no-pager | tail -n 100
dig @127.0.0.1 SOA +time=2 +tries=1
dig @127.0.0.1 NS +time=2 +tries=1
dig +tcp @127.0.0.1 SOA +time=2 +tries=1
```

For an authoritative zone, replace `YOUR_AUTHORIZED_ZONE` with the actual assigned zone, then query the correct known-good A/NS records. Do **not** assume recursion or zone transfers should be universally disabled without confirming scoring/client requirements.

```sh
dig @127.0.0.1 YOUR_AUTHORIZED_ZONE SOA +time=2 +tries=1
dig @127.0.0.1 YOUR_AUTHORIZED_ZONE NS +time=2 +tries=1
dig +tcp @127.0.0.1 YOUR_AUTHORIZED_ZONE SOA +time=2 +tries=1
```

### 3. Packages, security updates, users, scheduled jobs (read-only)
```sh
dpkg-query -W bind9 bind9-utils bind9-dnsutils 2>/dev/null
apt list --upgradable 2>/dev/null | grep -Ei 'bind9|dns|openssl' || true
apt-cache policy bind9
sudo ss -lntup | grep ':53 ' || true
getent passwd | tail -n 30
sudo crontab -l 2>/dev/null || true
sudo ls -al /etc/cron.d /etc/cron.daily /etc/systemd/system 2>/dev/null
sudo journalctl -u ssh --since '1 hour ago' --no-pager | tail -n 80
```

Package versions alone do not prove exploitability: Ubuntu backports fixes. Compare Ubuntu Security Notices and `apt` candidate versions. Do not attempt crash/DoS exploit tests on scored hosts.

### 4. Safely restore BIND (manual, authorized, one change at a time)

First validate the configuration; **do not restart on validation failure**:
```sh
sudo named-checkconf -z
```

If validation succeeds and the DNS service is unexpectedly stopped, use one of these based on the service name that actually exists:
```sh
sudo systemctl restart named
sudo systemctl status named --no-pager
```

If `named` does not exist and `bind9` does:
```sh
sudo systemctl restart bind9
sudo systemctl status bind9 --no-pager
```

Then re-test the expected DNS answers using the queries in section B.2 and confirm the scoreboard. Never overwrite zones from an unverified backup or blindly flush iptables/ufw.

### 5. Security update (manual only after backup and approved change)
```sh
sudo apt update
apt list --upgradable
sudo apt install --only-upgrade bind9 bind9-utils bind9-dnsutils
sudo named-checkconf -z
systemctl status named --no-pager || systemctl status bind9 --no-pager
```

**Caution:** Package updates can restart services. Confirm scoring-compatible behavior, maintenance timing, backups and staff restrictions first. If package names differ, check `dpkg-query -W 'bind9*'` and install only the actually installed/required packages. Never blanket `apt upgrade` in an emergency.

### 6. Incident response if suspected compromise

1. Record local clock/UTC and identify the specific alert, affected account/service, and time window.
2. Capture only necessary logs to **approved in-range** evidence storage (not personal laptop/cloud). Preserve ownership and timestamps.
3. Compare current service config, zone records, listening ports, users, sudoers, SSH keys and scheduled tasks to a known-good baseline.
4. Do not remove staff-controlled users/agents or shut down service to investigate without approval.
5. If indicators are confirmed, coordinate isolation that complies with R18; restore only reviewed configs and validate the scored application after every change.

### 7. Manual incident note template
`UTC time | host | service | observed symptom | verification command | result | approval/owner | change | rollback | retest | scoring status`

## Rules checklist (from TCDC official packet)

- R20: custom tools (including scripts) require a public repo and Tool Links submission; this runbook is plain-text manual commands, but staff rulings control whether wrappers or command sets count.
- R21: no AI during the event; seek ruling for pre-generated static material.
- R18: do not introduce forbidden outside traffic blocks.
- R23: do not exfiltrate competition data/artifacts; screenshots and passwords are limited exceptions.
- Hands-off is hands-off: stop running checks if staff requires it. No unattended watches across prohibited periods.
