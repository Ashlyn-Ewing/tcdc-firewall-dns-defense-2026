#!/bin/sh
# TCDC OPNsense defensive audit — CUSTOM TOOL, submit under R20.
# Read-only; do not change firewall, routing, users, updates, or store data off range.
set -eu
mode="${1:-audit}"
case "$mode" in audit) ;; *) echo 'Usage: sh tcdc_opnsense.sh audit' >&2; exit 2;; esac
printf '=== TCDC OPNsense read-only check %s UTC ===\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
for c in opnsense-version pfctl sockstat netstat; do command -v "$c" >/dev/null 2>&1 || echo "WARN missing $c"; done
opnsense-version 2>&1 || true
printf '\n--- pf status ---\n'
pfctl -si 2>&1 | head -n 45 || true
printf '\n--- routing ---\n'
netstat -rn 2>&1 | head -n 70 || true
printf '\n--- listening sockets ---\n'
sockstat -4 -6 -l 2>&1 | head -n 100 || true
printf '\n--- rules (read-only) ---\n'
pfctl -sr 2>&1 | head -n 120 || true
printf '\n--- NAT (read-only) ---\n'
pfctl -sn 2>&1 | head -n 80 || true
printf '\nNEXT STEPS: Review unexpected changes against approved baseline in OPNsense GUI.\n'
printf 'Firmware updates, firewall changes, rollback and log storage require manual approval and scoring verification.\n'
