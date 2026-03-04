#!/usr/bin/env python3

"""
Script Name: graph_banned_ips.py

Description:
1. Counts IPs inside banned_ips.txt
2. Stores weekly history
3. Generates a BAR graph
4. Exports graph to /tmp/CoSec/files/

Designed for Linux headless environments.

Req.
dnf install -y python pip 
pip install matplotlib pandas

"""

import matplotlib
matplotlib.use('Agg')  # Required for headless servers

import os
import datetime
import pandas as pd
import matplotlib.pyplot as plt

# ==============================
# CONFIGURATION
# ==============================

BANNED_IP_FILE = "/tmp/CoSec/banned_ips.txt"
HISTORY_FILE = "/tmp/CoSec/files/banned_ips_history.csv"
EXPORT_DIR = "/tmp/CoSec/files"
GRAPH_FILE = os.path.join(EXPORT_DIR, "banned_ips_graph.png")

# ==============================
# ENSURE EXPORT DIRECTORY EXISTS
# ==============================

if not os.path.exists(EXPORT_DIR):
    os.makedirs(EXPORT_DIR)
    print(f"Created directory: {EXPORT_DIR}")

# ==============================
# CHECK IF BANNED FILE EXISTS
# ==============================

if not os.path.exists(BANNED_IP_FILE):
    print(f"ERROR: {BANNED_IP_FILE} not found.")
    exit(1)

# ==============================
# COUNT IP ENTRIES
# ==============================

with open(BANNED_IP_FILE, "r") as f:
    lines = f.readlines()

ips = [line.strip() for line in lines if line.strip()]
ip_count = len(ips)

print(f"Total banned IPs: {ip_count}")

# ==============================
# GET CURRENT DATE
# ==============================

today = datetime.date.today()

# ==============================
# UPDATE HISTORY
# ==============================

new_data = pd.DataFrame({
    "date": [today],
    "count": [ip_count]
})

if os.path.exists(HISTORY_FILE):
    history = pd.read_csv(HISTORY_FILE)
    history = pd.concat([history, new_data], ignore_index=True)
else:
    history = new_data

# Remove duplicate dates
history = history.drop_duplicates(subset=["date"], keep="last")

history.to_csv(HISTORY_FILE, index=False)

print("History updated.")

# ==============================
# GENERATE BAR GRAPH
# ==============================

history["date"] = pd.to_datetime(history["date"])

plt.figure()

plt.bar(history["date"].dt.strftime("%Y-%m-%d"), history["count"])

plt.xlabel("Date")
plt.ylabel("Number of Banned IPs")
plt.title("Banned IPs Trend Over Time")

plt.xticks(rotation=45)
plt.tight_layout()

plt.savefig(GRAPH_FILE)

print(f"Bar graph exported to: {GRAPH_FILE}")
print("Done.")
