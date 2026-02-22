#!/bin/bash
# export-domains.sh - Export Pi-hole blocked domains and upload to GitHub (token auth)

set -e  # Exit on error

TMP_DIR="/tmp"
REPO_DIR="$TMP_DIR/CoSec"
FILE_TO_UPLOAD="blocked_domains.txt"
BRANCH="main"
BOT_COMMIT_MSG="Update blocked domains via bot-updater"

# --- Token & Repo ---
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN não está definido no environment!"
    exit 1
fi
REPO_URL="https://$GITHUB_TOKEN@github.com/skillmio/CoSec.git"

echo "=== Pi-hole Blocked Domains Exporter ==="
echo "Date: $(date)"

# Step 1: Export all blocked domains from gravity
echo "1. Exporting all gravity domains..."
sudo sqlite3 /etc/pihole/gravity.db "SELECT DISTINCT domain FROM gravity;" > "$TMP_DIR/raw_blocked_domains.txt"

# Step 2: Add 0.0.0.0 prefix (hosts format)
echo "2. Adding 0.0.0.0 prefix..."
sed -i.bak 's/^/0.0.0.0 /' "$TMP_DIR/raw_blocked_domains.txt"

# Step 3: Download exempt list
echo "3. Downloading exempt list..."
wget -O "$TMP_DIR/exempt.txt" https://raw.githubusercontent.com/skillmio/CoSec/master/files/exempt_domains

# Step 4: Filter out exempt domains
echo "4. Excluding exempt domains..."
grep -Fvx -f "$TMP_DIR/exempt.txt" "$TMP_DIR/raw_blocked_domains.txt" > "$TMP_DIR/pre_blocked_domains.txt"

# Step 5: Sort & deduplicate
echo "5. Sorting & removing duplicates..."
sort -u "$TMP_DIR/pre_blocked_domains.txt" -o "$TMP_DIR/$FILE_TO_UPLOAD"

# Stats
echo ""
echo "=== RESULTS ==="
echo "Total gravity domains: $(wc -l < $TMP_DIR/raw_blocked_domains.txt)"
echo "Clean domains (after exempt filter): $(wc -l < $TMP_DIR/pre_blocked_domains.txt)"
echo "Ready for upload: $TMP_DIR/$FILE_TO_UPLOAD"

# --- GitHub Upload Section ---
echo ""
echo "=== Uploading to GitHub ==="

# Clone repo (or pull if already exists)
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
else
    cd "$REPO_DIR"
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
fi

# Copy the blocked_domains.txt
cp "$TMP_DIR/$FILE_TO_UPLOAD" "$REPO_DIR/"

cd "$REPO_DIR"

# Configure git user for bot commits
git config user.name "bot-updater"
git config user.email "bot@skillmio.net"

# Add, commit, push
git add "$FILE_TO_UPLOAD"
git commit -m "$BOT_COMMIT_MSG" || echo "No changes to commit."
git push origin "$BRANCH"

echo ""
echo "✅ Upload complete!"
cd /tmp
find -type f -exec rm -f {} \;
