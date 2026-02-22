#!/bin/bash
# export-blocked-domains.sh - Merge blocked domains (external + candidate + current - exempt) and upload to GitHub
# Fully preserves 0.0.0.0 <domain> format

set -e

TMP_DIR="/tmp"
REPO_DIR="$TMP_DIR/CoSec"
FILE_TO_UPLOAD="blocked_domains.txt"
BRANCH="main"
BOT_COMMIT_MSG="Update blocked domains via bot-updater"

EXTERNAL_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
CANDIDATE_URL="https://raw.githubusercontent.com/skillmio/CoSec/master/files/candidate_domains"
EXEMPT_URL="https://raw.githubusercontent.com/skillmio/CoSec/master/files/exempt_domains"
CURRENT_URL="https://raw.githubusercontent.com/skillmio/CoSec/master/blocked_domains.txt"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN not defined!"
    exit 1
fi
REPO_URL="https://$GITHUB_TOKEN@github.com/skillmio/CoSec.git"

echo "=== CoSec Blocked Domains Exporter ==="
echo "Date: $(date)"

# --- Helper ---
normalize_file() { sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$1" | sort -u; }

# Step 1: External domains (only 0.0.0.0 lines)
echo "1. Fetching external blocked domains..."
curl -s "$EXTERNAL_URL" \
    | grep '^0\.0\.0\.0 ' > "$TMP_DIR/external_blocked_domains.txt"
normalize_file "$TMP_DIR/external_blocked_domains.txt" > "$TMP_DIR/external_norm.txt"
echo "External blocked domains: $(wc -l < "$TMP_DIR/external_norm.txt")"

# Step 2: Candidate domains
echo "2. Fetching candidate domains..."
curl -s "$CANDIDATE_URL" \
    | grep '^0\.0\.0\.0 ' > "$TMP_DIR/candidate_domains.txt"
normalize_file "$TMP_DIR/candidate_domains.txt" > "$TMP_DIR/candidate_norm.txt"
echo "Candidate domains: $(wc -l < "$TMP_DIR/candidate_norm.txt")"

# Step 3: Current blocked domains
echo "3. Fetching current blocked domains..."
curl -s "$CURRENT_URL" \
    | grep '^0\.0\.0\.0 ' > "$TMP_DIR/current_blocked_domains.txt"
normalize_file "$TMP_DIR/current_blocked_domains.txt" > "$TMP_DIR/current_norm.txt"
echo "Current blocked domains: $(wc -l < "$TMP_DIR/current_norm.txt")"

# Step 4: Exempt domains
echo "4. Fetching exempt domains..."
curl -s "$EXEMPT_URL" \
    | grep '^0\.0\.0\.0 ' > "$TMP_DIR/exempt_domains.txt"
awk '{print $2}' "$TMP_DIR/exempt_domains.txt" | sort -u > "$TMP_DIR/exempt_norm.txt"
echo "Exempt domains: $(wc -l < "$TMP_DIR/exempt_norm.txt")"

# Step 5: Merge all, exclude exempt
echo "5. Merging external + candidate + current domains, excluding exempt domains..."
cat "$TMP_DIR/external_norm.txt" "$TMP_DIR/candidate_norm.txt" "$TMP_DIR/current_norm.txt" \
    | awk '{print $2}' \
    | grep -v -F -f "$TMP_DIR/exempt_norm.txt" \
    | sort -u \
    | awk '{print "0.0.0.0 "$1}' > "$TMP_DIR/$FILE_TO_UPLOAD"
echo "Total blocked domains after merge: $(wc -l < "$TMP_DIR/$FILE_TO_UPLOAD")"

# Step 6: Upload to GitHub
echo "6. Uploading blocked domains to GitHub..."
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Cloning repository using token..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    cd "$REPO_DIR"
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
fi

cd "$REPO_DIR"

# Copy file
cp "$TMP_DIR/$FILE_TO_UPLOAD" "$REPO_DIR/"

# Git commit & push
git config user.name "bot-updater"
git config user.email "bot@skillmio.net"
git add "$FILE_TO_UPLOAD"
git commit -m "$BOT_COMMIT_MSG" || echo "No changes to commit."
git push origin "$BRANCH"

echo ""
echo "✅ Blocked domains merged and exported to GitHub!"
cd /tmp
