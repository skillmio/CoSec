#!/bin/bash
# ---------------------------------------------------
# Script: ban_ddos.sh
# Purpose: Copy SQLite DB, extract all IPs querying dhl.com,
#          feed them to Fail2Ban sshd jail, and sync banned IPs to GitHub in batches.
# ---------------------------------------------------

# ---------------------------
# Paths
# ---------------------------
DB_SOURCE="/etc/dns/apps/Query Logs (Sqlite)/querylogs.db"
DB_COPY="/tmp/querylogs_copy.db"
IP_FILE="/tmp/abuse_ips.txt"
LOG_FILE="/tmp/ban_ddos.log"

# GitHub repo for banned IPs
GIT_REPO="/tmp/CoSec"
DDOS_FILE="$GIT_REPO/files/ddos.txt"
BRANCH="main"
BOT_USER="Skillmio"
BOT_EMAIL="skillmiocfs@gmail.com"

# ---------------------------
# Timestamp
# ---------------------------
NOW=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$NOW] Starting ban_ddos.sh" >> "$LOG_FILE"

# ---------------------------
# 1️⃣ Copy DB safely
# ---------------------------
/bin/cp -f "$DB_SOURCE" "$DB_COPY"

# ---------------------------
# 2️⃣ Extract unique IPs querying dhl.com
# ---------------------------
sqlite3 "$DB_COPY" <<'EOF'
.headers off
.mode list
.once /tmp/abuse_ips.txt
SELECT DISTINCT client_ip
FROM dns_logs
WHERE qname='dhl.com';
EOF

# ---------------------------
# 3️⃣ Ensure Git repo exists
# ---------------------------
if [ ! -d "$GIT_REPO" ]; then
    echo "⚠️ GitHub repo not found at $GIT_REPO. Cloning..."
    git clone "https://$GITHUB_TOKEN@github.com/skillmio/CoSec.git" "$GIT_REPO"
fi

touch "$DDOS_FILE"

cd "$GIT_REPO" || exit
git config user.name "$BOT_USER"
git config user.email "$BOT_EMAIL"

# ---------------------------
# 4️⃣ Ban IPs and update ddos.txt locally
# ---------------------------
count=0
new_ips=0
while read -r ip; do
    if [ -n "$ip" ]; then
        # Check Fail2Ban
        if ! fail2ban-client status sshd | grep -q "$ip"; then
            count=$((count+1))
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Banning IP: $ip" | tee -a "$LOG_FILE"
            fail2ban-client set sshd banip "$ip"
        fi

        # Append to ddos.txt if not already present
        if ! grep -q "^$ip\$" "$DDOS_FILE"; then
            echo "$ip" >> "$DDOS_FILE"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Synced locally: Banned IP: $ip" | tee -a "$LOG_FILE"
            new_ips=$((new_ips+1))
        fi
    fi
done < "$IP_FILE"

# ---------------------------
# 5️⃣ Commit & push to GitHub (batch)
# ---------------------------
if [ $new_ips -gt 0 ]; then
    git add "$DDOS_FILE"
    commit_msg="Batch update banned IPs $(date '+%Y-%m-%d %H:%M:%S')"
    commit_output=$(git commit -m "$commit_msg" 2>&1)
    if [[ "$commit_output" == *"nothing to commit"* ]]; then
        echo "No new IPs to commit" | tee -a "$LOG_FILE"
    else
        git push origin "$BRANCH"
        echo "✅ GitHub updated with $new_ips new IP(s)" | tee -a "$LOG_FILE"
    fi
else
    echo "No new IPs to push to GitHub" | tee -a "$LOG_FILE"
fi

# ---------------------------
# Done
# ---------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed. Total new IPs banned this run: $count" >> "$LOG_FILE"
echo "-------------------------------------------------------" >> "$LOG_FILE"
