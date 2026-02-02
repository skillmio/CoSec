# Skillmio’s Blocklists

**Skillmio’s Blocklists** is an open-source collection of **DNS and IP blocklists** derived from the real-world filtering logic and threat intelligence used by **dns.skillmio.net**, our **free public DNS service**.

These blocklists are designed to enhance **privacy, security, and network performance** by stopping unwanted and malicious traffic at the DNS and network layers.

## What This Project Blocks

The DNS blocklists protect against:

* **Ads** (advertisements)
* **Trackers** (user and behavior tracking)
* **Phishing** domains
* **Malware and suspicious domains**
* **Invasive telemetry**

The lists are continuously refined based on production DNS traffic and threat intelligence.

## Blocklist Groups

### DNS Blocklist (dns-blist)

A curated **DNS blocklist**, suitable for:

* DNS resolvers
  *(Unbound, BIND, Pi-hole, AdGuard, Technitium, etc.)*
* Firewalls and NGFWs
  *(OPNsense, pfSense, FortiGate, Palo Alto, etc.)*
* Network filtering platforms
* SIEM and security monitoring tools

These lists can be **automatically updated** and integrated into existing security workflows.


### IP Blocklist (ip-blist)

The **ipblist** is used on **Skillmio’s public-facing infrastructure** to protect services from **malicious and abusive activity**, including:

* Network and port scanning
* SSH brute-force attempts
* RDP attacks
* Unauthorized access attempts

This blocklist is intended for **firewalls, IDS/IPS, and perimeter security systems**, not DNS resolvers.

## Key Features

* Blocklists derived from **dns.skillmio** production data
* Improves **user privacy** and **network security**
* Reduces **latency** and **bandwidth usage**
* Centralized protection at DNS and network layers
* Suitable for **home, enterprise, on-prem, and cloud environments**


## Compatibility

Skillmio’s Blocklists can be deployed across a wide range of platforms:

* Windows, Linux, macOS
* Android and iOS
* Routers, firewalls, and gateways
* On-premises and cloud infrastructures

Supports secure DNS transports:

* **DNS-over-HTTPS (DoH)**
* **DNS-over-TLS (DoT)**


## Public DNS (dns.skillmio.net)

```
DNS-over-HTTPS (DoH): dns.skillmio.net
dns1:
dns2:
```

## Use Cases

* Network-wide ad and tracker blocking
* Phishing and malware protection
* Privacy-focused DNS filtering
* DNS enforcement for home and enterprise networks
* Perimeter defense for public-facing services
