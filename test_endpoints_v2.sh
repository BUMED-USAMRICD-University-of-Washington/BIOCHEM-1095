#!/bin/bash
SERVER="http://127.0.0"

echo "====================================================================="
echo "VIRUSTC OAUTH2/JWT AUTHENTICATION TESTING MATRIX"
echo "====================================================================="

# 1. Test unauthenticated request rejection safety barriers
echo "Step 1: Attempting to pull map arrays without security parameters (Expect 401 Rejection):"
curl -s -o /dev/null -w "%{http_code}" -X GET "${SERVER}/maps/vector-exposure"
echo -e "\n"

# 2. Acquire a cryptographically signed access token from the security database layer
echo "Step 2: Requesting Bearer Access Token using command credentials..."
TOKEN_RESPONSE=$(curl -s -X 'POST' \
  "${SERVER}/auth/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=vtc_command_admin&password=SecureCryptoPass2026')

# Extract token text parameter safely from JSON string chunk
TOKEN=$(echo $TOKEN_RESPONSE | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')

echo "Acquired Token Payload Signature: ${TOKEN:0:15}...[ENCRYPTED]"
echo ""

# 3. Pull protected information payload utilizing valid Bearer authorization injection
echo "Step 3: Accessing Protected Mapping Data Streams using acquired Authorization token:"
curl -X GET "${SERVER}/maps/vector-exposure" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json"
echo -e "\n"
