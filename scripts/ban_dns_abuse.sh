#!/bin/bash
# ---------------------------------------------------
# Script: dns_abuse_guard.sh
# Purpose: Detect DNS abuse patterns and ban IPs
# ---------------------------------------------------

set -e

# -------------------------------
# Configurable Variables
# -------------------------------
CAPTURE_TIME=120       # seconds to capture live DNS queries
BAN_THRESHOLD=5        # minimum queries per IP to ban
TMP_RAW="/tmp/dns_raw.log"
TMP_IPS="/tmp/dns_scored_ips.txt"
TMP_NEW="/tmp/dns_new_ips.txt"
GIT_REPO="/tmp/CoSec"
DATE=$(date +%F)
DDOS_DIR="$GIT_REPO/files/ddos"
DDOS_FILE="$DDOS_DIR/$DATE.txt"
BRANCH="main"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting DNS abuse detection..."

# -------------------------------
# Capture live DNS ANY queries
# -------------------------------
#timeout "$CAPTURE_TIME" tcpdump -nn -l udp port 53 and 'udp[10] & 0x80 = 0' 2>/dev/null \
#| grep -E "ANY\?|TXT\?|DNSKEY\?|RRSIG\?" >> "$TMP_RAW"

timeout "$CAPTURE_TIME" tcpdump -nn -l udp port 53 and 'udp[10] & 0x80 = 0' 2>/dev/null \
| grep "ANY?" \
| awk '{print $3}' \
| cut -d. -f1-4 >> "$TMP_RAW"

# -------------------------------
# Analyze & count queries per IP
# -------------------------------
awk -v threshold="$BAN_THRESHOLD" '
{
    # Extract source IP (ignores port)
    match($3, /^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/, arr)
    if (arr[1] != "") ip=arr[1]; else next

    count[ip]++
}
END {
    for (i in count)
        if (count[i] > threshold)
            print i
}
' "$TMP_RAW" | sort -u > "$TMP_IPS"

# -------------------------------
# Remove private/internal IPs
# -------------------------------
grep -Ev '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)' "$TMP_IPS" > "${TMP_IPS}.clean" || true
mv "${TMP_IPS}.clean" "$TMP_IPS"

TOTAL_FOUND=$(wc -l < "$TMP_IPS")
echo "Suspicious IPs detected: $TOTAL_FOUND"

# -------------------------------
# Ensure Git repo exists
# -------------------------------
if [ ! -d "$GIT_REPO" ]; then
    git clone "https://$GITHUB_TOKEN@github.com/skillmio/CoSec.git" "$GIT_REPO"
fi

mkdir -p "$DDOS_DIR"
cd "$GIT_REPO"

git config user.name "Skillmio"
git config user.email "skillmiocfs@gmail.com"
git pull --rebase origin "$BRANCH"
touch "$DDOS_FILE"

# -------------------------------
# Filter only new IPs
# -------------------------------
grep -vxFf "$DDOS_FILE" "$TMP_IPS" > "$TMP_NEW" || true
NEW_COUNT=$(wc -l < "$TMP_NEW")
echo "New attacking IPs: $NEW_COUNT"

# -------------------------------
# Ban new IPs via fail2ban
# -------------------------------
BAN_COUNT=0
while read -r ip; do
    [ -z "$ip" ] && continue
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Banning IP: $ip"
    fail2ban-client set sshd banip "$ip" || true
    BAN_COUNT=$((BAN_COUNT+1))
done < "$TMP_NEW"

# -------------------------------
# Update Git log
# -------------------------------
if [ "$NEW_COUNT" -gt 0 ]; then
    cat "$TMP_NEW" >> "$DDOS_FILE"
    git add "$DDOS_FILE"
    git commit -m "DNS abuse batch $(date '+%Y-%m-%d %H:%M:%S')" || true

    for i in 1 2 3; do
        if git push origin "$BRANCH"; then
            echo "✅ GitHub updated with $NEW_COUNT new IPs"
            break
        fi
        git pull --rebase origin "$BRANCH"
    done
else
    echo "No new IPs to ban"
fi

echo "Total banned this run: $BAN_COUNT"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished"
echo "------------------------------------------------"
