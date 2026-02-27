#!/usr/bin/env python3

import os
import boto3
import sys
from datetime import datetime

# ---------------------------
# Setup logging
# ---------------------------
log_file = "dns_record_log.txt"
timestamp = datetime.utcnow().isoformat()
log_lines = [f"\n--- DNS Record Creation Log [{timestamp}] ---\n"]

def log(message):
    print(message)
    log_lines.append(message + "\n")

# ---------------------------
# AWS credentials from env vars
# ---------------------------
aws_access_key_id = os.getenv("DEMO_AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.getenv("DEMO_AWS_SECRET_ACCESS_KEY")
region = os.getenv("DEMO_AWS_REGION", "us-east-1")
hosted_zone_id = os.getenv("DEMO_HOSTED_ZONE_ID")

if not aws_access_key_id or not aws_secret_access_key or not hosted_zone_id:
    log("❌ ERROR: DEMO_AWS_ACCESS_KEY_ID, DEMO_AWS_SECRET_ACCESS_KEY, and DEMO_HOSTED_ZONE_ID must be set")
    sys.exit(1)

# ---------------------------
# Participant + IPs from env
# ---------------------------
participant_id = os.getenv("INSTRUQT_PARTICIPANT_ID")
dc1_ip = os.getenv("DC1_IP")
client_2_ip = os.getenv("CLIENT_2_IP")
gm_ip = os.getenv("GM_IP")
gm2_ip = os.getenv("GM2_IP")
azure_win11_ip = os.getenv("AZURE_WIN11_IP")
azure_win11_2_ip = os.getenv("AZURE_WIN11_2_IP")

if not participant_id:
    log("❌ ERROR: INSTRUQT_PARTICIPANT_ID is not set")
    sys.exit(1)

if not dc1_ip:
    log("❌ ERROR: DC1_IP must be set")
    sys.exit(1)

if not client_2_ip:
    log("⚠️  WARNING: CLIENT_2_IP is not set, skipping client-2 DNS record")

if not gm_ip:
    log("⚠️  WARNING: GM_IP is not set, skipping infoblox GM DNS record")

if not gm2_ip:
    log("⚠️  WARNING: GM2_IP is not set, skipping infoblox GM2 DNS record")

if not azure_win11_ip:
    log("⚠️  WARNING: AZURE_WIN11_IP is not set, skipping Azure Win11 DNS record")

if not azure_win11_2_ip:
    log("⚠️  WARNING: AZURE_WIN11_2_IP is not set, skipping Azure Win11 #2 DNS record")

# ---------------------------
# Build FQDN mapping
# ---------------------------
fqdn_dc1 = f"{participant_id}-client.iracictechguru.com."
fqdn_client2 = f"{participant_id}-client2.iracictechguru.com."
fqdn_gm = f"{participant_id}-infoblox.iracictechguru.com."
fqdn_gm2 = f"{participant_id}-infoblox2.iracictechguru.com."
fqdn_azure_win11 = f"{participant_id}-client3-azure.iracictechguru.com."
fqdn_azure_win11_2 = f"{participant_id}-client4-azure.iracictechguru.com."

# ---------------------------
# Create boto3 session
# ---------------------------
session = boto3.Session(
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=region
)

route53 = session.client("route53")

# ---------------------------
# Create A record for DC1/Client
# ---------------------------
log(f"➡️  Creating A record: {fqdn_dc1} -> {dc1_ip}")
try:
    response = route53.change_resource_record_sets(
        HostedZoneId=hosted_zone_id,
        ChangeBatch={
            "Comment": f"Upsert A record for {fqdn_dc1}",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": fqdn_dc1,
                        "Type": "A",
                        "TTL": 300,
                        "ResourceRecords": [{"Value": dc1_ip}]
                    }
                }
            ]
        }
    )
    status = response['ChangeInfo']['Status']
    log(f"✅  A record created: {fqdn_dc1} -> {dc1_ip}")
    log(f"📡  Change status: {status}")

except Exception as e:
    log(f"❌ Failed to create A record {fqdn_dc1}: {e}")
    sys.exit(1)

# ---------------------------
# Create A record for Client 2
# ---------------------------
if client_2_ip:
    log(f"➡️  Creating A record: {fqdn_client2} -> {client_2_ip}")
    try:
        response = route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                "Comment": f"Upsert A record for {fqdn_client2}",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": fqdn_client2,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": client_2_ip}]
                        }
                    }
                ]
            }
        )
        status = response['ChangeInfo']['Status']
        log(f"✅  A record created: {fqdn_client2} -> {client_2_ip}")
        log(f"📡  Change status: {status}")

    except Exception as e:
        log(f"❌ Failed to create A record {fqdn_client2}: {e}")
        sys.exit(1)

# ---------------------------
# Create A record for NIOS GM
# ---------------------------
if gm_ip:
    log(f"➡️  Creating A record: {fqdn_gm} -> {gm_ip}")
    try:
        response = route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                "Comment": f"Upsert A record for {fqdn_gm}",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": fqdn_gm,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": gm_ip}]
                        }
                    }
                ]
            }
        )
        status = response['ChangeInfo']['Status']
        log(f"✅  A record created: {fqdn_gm} -> {gm_ip}")
        log(f"📡  Change status: {status}")

    except Exception as e:
        log(f"❌ Failed to create A record {fqdn_gm}: {e}")
        sys.exit(1)

# ---------------------------
# Create A record for NIOS GM2
# ---------------------------
if gm2_ip:
    log(f"➡️  Creating A record: {fqdn_gm2} -> {gm2_ip}")
    try:
        response = route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                "Comment": f"Upsert A record for {fqdn_gm2}",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": fqdn_gm2,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": gm2_ip}]
                        }
                    }
                ]
            }
        )
        status = response['ChangeInfo']['Status']
        log(f"✅  A record created: {fqdn_gm2} -> {gm2_ip}")
        log(f"📡  Change status: {status}")

    except Exception as e:
        log(f"❌ Failed to create A record {fqdn_gm2}: {e}")
        sys.exit(1)

# ---------------------------
# Create A record for Azure Win11 Client
# ---------------------------
if azure_win11_ip:
    log(f"➡️  Creating A record: {fqdn_azure_win11} -> {azure_win11_ip}")
    try:
        response = route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                "Comment": f"Upsert A record for {fqdn_azure_win11}",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": fqdn_azure_win11,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": azure_win11_ip}]
                        }
                    }
                ]
            }
        )
        status = response['ChangeInfo']['Status']
        log(f"✅  A record created: {fqdn_azure_win11} -> {azure_win11_ip}")
        log(f"📡  Change status: {status}")

    except Exception as e:
        log(f"❌ Failed to create A record {fqdn_azure_win11}: {e}")
        sys.exit(1)

# ---------------------------
# Create A record for Azure Win11 Client #2
# ---------------------------
if azure_win11_2_ip:
    log(f"➡️  Creating A record: {fqdn_azure_win11_2} -> {azure_win11_2_ip}")
    try:
        response = route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                "Comment": f"Upsert A record for {fqdn_azure_win11_2}",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": fqdn_azure_win11_2,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": azure_win11_2_ip}]
                        }
                    }
                ]
            }
        )
        status = response['ChangeInfo']['Status']
        log(f"✅  A record created: {fqdn_azure_win11_2} -> {azure_win11_2_ip}")
        log(f"📡  Change status: {status}")

    except Exception as e:
        log(f"❌ Failed to create A record {fqdn_azure_win11_2}: {e}")
        sys.exit(1)

# ---------------------------
# Save FQDNs and IPs to file
# ---------------------------
fqdn_file = "created_fqdn.txt"
with open(fqdn_file, "w") as f:
    f.write(f"{fqdn_dc1} {dc1_ip}\n")
    if client_2_ip:
        f.write(f"{fqdn_client2} {client_2_ip}\n")
    if gm_ip:
        f.write(f"{fqdn_gm} {gm_ip}\n")
    if gm2_ip:
        f.write(f"{fqdn_gm2} {gm2_ip}\n")
    if azure_win11_ip:
        f.write(f"{fqdn_azure_win11} {azure_win11_ip}\n")
    if azure_win11_2_ip:
        f.write(f"{fqdn_azure_win11_2} {azure_win11_2_ip}\n")
log(f"💾 FQDNs and IPs written to {fqdn_file}")

# ---------------------------
# Write log to file
# ---------------------------
with open(log_file, "a") as f:
    f.writelines(log_lines)

log(f"📄 Log written to {log_file}")
