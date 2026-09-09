#!/bin/bash

# Configuration settings matching the server boundaries
SERVER="http://127.0.0"

echo "====================================================================="
echo "VIRUSTC APPLICATION VERIFICATION PROTOCOLS"
echo "====================================================================="
echo ""

# 1. Fetch the primary Vector Exposure point matrices
echo "Step 1: Auditing Environmental Vector Incident Tracking Map JSON Output:"
curl -X GET "${SERVER}/maps/vector-exposure" -H "Accept: application/json"
echo -e "\n\n"

# 2. Ingest real-time telemetry from an active transport vault
echo "Step 2: Simulating Onboard Cellular Telemetry Ingestion from Transit Vault:"
curl -X 'POST' \
  "${SERVER}/telemetry/vault-update" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "device_id": "CELL-LOG-404",
  "lat": 47.6062,
  "lng": -122.3321,
  "thermal_status_celsius": -2.45,
  "sensors_active": true
}'
echo -e "\n\n"

# 3. Fire the automated geofenced exposure hook to test perimeter isolation logic
echo "Step 3: Firing Exposure Webhook Alert Trigger (Testing Auto-Quarantine Matrix):"
curl -X 'POST' \
  "${SERVER}/webhooks/exposure-alert" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "incident_id": "EXP-2026-X9",
  "incident_lat": 47.605,
  "incident_lng": -122.330,
  "radius_threshold_km": 1.5
}'
echo -e "\n\n"

# 4. Check inventory to ensure the automatic geofence quarantine changed status correctly
echo "Step 4: Verification Check - Pulling Master Inventory Ledger Status:"
curl -X GET "${SERVER}/logistics/inventory-status" -H "Accept: application/json"
echo -e "\n"
