#!/usr/bin/env bash
# TCDC DNS defensive helper — CUSTOM TOOL, staff approval required (R20).
# Run locally on authorized Ubuntu DNS host only. No data export or third-party dependencies.
set -Eeuo pipefail
MODE="${1:-audit}"
INTERVAL="${2:-60}"
case "$MODE" in audit|watch|recover) ;; *) echo 'Usage: sudo bash tcdc_dns.sh audit|watch [seconds]|recover' >&2; exit 2;; esac
if [[ "$MODE" == "watch" ]] && ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] ; then echo 'Interval must be integer seconds' >&2; exit 2; fi
if [[ "$MODE" == "watch" ]] && (( INTERVAL < 30 )); then echo 'Minimum interval 30s' >&2; exit 2; fi
LOGDIR="${TCDC_LOGDIR:-/var/log/tcdc-defense}"
if [[ $EUID -eq 0 ]]; then install -d -m 0700 "$LOGDIR"; else LOGDIR="${HOME}/.tcdc-defense"; mkdir -p "$LOGDIR"; chmod 700 "$LOGDIR"; fi
LOG="$LOGDIR/dns-events.log"
log(){ printf '%s | %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG"; }
svc(){ if systemctl list-unit-files named.service --no-legend 2>/dev/null | grep -q '^named.service'; then echo named; elif systemctl list-unit-files bind9.service --no-legend 2>/dev/null | grep -q '^bind9.service'; then echo bind9; else echo ''; fi; }
SVC="$(svc)"
check(){
  log '--- DNS audit start ---'
  if [[ -z "$SVC" ]]; then log 'ALERT no named/bind9 systemd unit found; manually verify package and DNS implementation'; return 1; fi
  if systemctl is-active --quiet "$SVC"; then log "OK service $SVC active"; else log "ALERT service $SVC is not active"; fi
  if command -v named-checkconf >/dev/null; then if named-checkconf -z >/dev/null 2>&1; then log 'OK BIND config parses and zones load'; else log 'ALERT BIND config/zone validation failed; no automatic restart'; fi; else log 'WARN named-checkconf missing'; fi
  if command -v dig >/dev/null; then
    for proto in udp tcp; do
      if [[ "$proto" == tcp ]]; then out=$(dig +tcp @127.0.0.1 . NS +time=2 +tries=1 +noall +comments 2>&1) || true; else out=$(dig @127.0.0.1 . NS +time=2 +tries=1 +noall +comments 2>&1) || true; fi
      if grep -q 'status:' <<<"$out"; then log "INFO $proto local DNS responded (answer correctness requires authorized zone test)"; else log "ALERT $proto local DNS did not respond"; fi
    done
  else log 'WARN dig unavailable'; fi
  if command -v dpkg-query >/dev/null; then dpkg-query -W -f='${binary:Package} ${Version}\n' 'bind9*' 2>/dev/null | while IFS= read -r line; do log "PACKAGE $line"; done || true; fi
  log 'Inspect package advisories, auth zone integrity, records and journal manually; no arbitrary automatic vulnerability repair.'
  log '--- DNS audit end ---'
}
recover(){
  [[ $EUID -eq 0 ]] || { log 'ERROR recover needs sudo'; exit 1; }
  [[ -n "$SVC" ]] || { log 'ERROR no known BIND service'; exit 1; }
  command -v named-checkconf >/dev/null || { log 'ERROR named-checkconf missing; no restart'; exit 1; }
  named-checkconf -z >/dev/null 2>&1 || { log 'ERROR invalid configuration/zones; no restart'; exit 1; }
  if systemctl is-active --quiet "$SVC"; then log "NO ACTION $SVC already active"; else
    log "RECOVER attempt restart $SVC after validation"
    if systemctl restart "$SVC" && systemctl is-active --quiet "$SVC"; then log "RECOVERED $SVC active; verify authoritative answers and scoring"; else log "ERROR $SVC did not recover; inspect journalctl -u $SVC"; return 1; fi
  fi
}
case "$MODE" in audit) check;; recover) recover; check;; watch) trap 'log "Monitoring stopped"; exit 0' INT TERM; log "Watch mode every ${INTERVAL}s; read-only"; while :; do check || true; sleep "$INTERVAL"; done;; esac
