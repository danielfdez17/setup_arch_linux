#!/bin/bash
# SSH stability fix — run with sudo inside the VM
set -x

# ── 1. SSHD Watchdog service ────────────────────────────────────────────────
cat > /usr/local/bin/sshd-watchdog.sh << 'WDEOF'
#!/bin/bash
# Monitors sshd health every 15 seconds. Auto-restarts if dead.
LOG=/var/log/sshd-watchdog.log
echo "$(date): watchdog started (pid=$$)" >> "$LOG"
while true; do
    SSHD_ACTIVE=$(systemctl is-active ssh 2>/dev/null)
    SSHD_COUNT=$(pgrep -c sshd 2>/dev/null || echo 0)
    LISTEN=$(ss -tlnp 2>/dev/null | grep -c 4242)
    ESTAB=$(ss -tnp 2>/dev/null | grep -c 4242)
    MEM_FREE=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null)

    if [ "$SSHD_ACTIVE" != "active" ] || [ "$LISTEN" = "0" ]; then
        echo "$(date): ALERT sshd=$SSHD_ACTIVE procs=$SSHD_COUNT listen=$LISTEN estab=$ESTAB mem_free=${MEM_FREE}kB" >> "$LOG"
        systemctl restart ssh >> "$LOG" 2>&1
        echo "$(date): sshd restart attempted, new_status=$(systemctl is-active ssh)" >> "$LOG"
    fi

    # Periodic health log every 5 minutes
    MIN=$(date +%M)
    SEC=$(date +%S)
    if [ "$((MIN % 5))" = "0" ] && [ "$SEC" -lt "16" ]; then
        echo "$(date): OK sshd=$SSHD_ACTIVE procs=$SSHD_COUNT listen=$LISTEN estab=$ESTAB mem=${MEM_FREE}kB" >> "$LOG"
    fi

    sleep 15
done
WDEOF
chmod +x /usr/local/bin/sshd-watchdog.sh

cat > /etc/systemd/system/sshd-watchdog.service << 'SWEOF'
[Unit]
Description=SSHD health watchdog with auto-restart
After=ssh.service
Requires=ssh.service

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/sshd-watchdog.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SWEOF

systemctl daemon-reload
systemctl enable sshd-watchdog
systemctl start sshd-watchdog
echo "[OK] sshd-watchdog: $(systemctl is-active sshd-watchdog)"

# ── 2. Fix sshd_config for VS Code Remote SSH ───────────────────────────────
# Remove old values that will be re-added
sed -i '/^MaxSessions /d' /etc/ssh/sshd_config
sed -i '/^LoginGraceTime /d' /etc/ssh/sshd_config
sed -i '/^MaxStartups /d' /etc/ssh/sshd_config
sed -i '/^# VS Code/d' /etc/ssh/sshd_config

# VS Code Remote SSH opens MANY parallel connections:
# - SOCKS proxy (-D)
# - exec server connection
# - port forwarding tunnels
# - extension host connections
# MaxStartups 50:30:100 = accept 50 unauthenticated, then 30% random drop until 100
cat >> /etc/ssh/sshd_config << 'SSHEOF'

# VS Code Remote SSH compatibility
MaxStartups 50:30:100
MaxSessions 20
LoginGraceTime 300
SSHEOF

echo "[OK] sshd_config updated"

# ── 3. Fix kernel TCP keepalive (verify) ─────────────────────────────────────
sysctl -w net.ipv4.tcp_keepalive_time=60
sysctl -w net.ipv4.tcp_keepalive_intvl=15
sysctl -w net.ipv4.tcp_keepalive_probes=5
echo "[OK] kernel TCP keepalive applied"

# ── 4. Restart sshd ─────────────────────────────────────────────────────────
systemctl restart ssh
echo "[OK] sshd restarted: $(systemctl is-active ssh)"

# ── 5. Verify everything ────────────────────────────────────────────────────
echo ""
echo "=== FINAL VERIFICATION ==="
echo "sshd: $(systemctl is-active ssh)"
echo "nat-keepalive: $(systemctl is-active nat-keepalive)"
echo "sshd-watchdog: $(systemctl is-active sshd-watchdog)"
echo "tcp_keepalive_time: $(cat /proc/sys/net/ipv4/tcp_keepalive_time)"
echo "tcp_keepalive_intvl: $(cat /proc/sys/net/ipv4/tcp_keepalive_intvl)"
echo ""
echo "=== sshd_config (non-comments) ==="
grep -v '^#' /etc/ssh/sshd_config | grep -v '^$'
echo ""
echo "=== ALL DONE ==="
