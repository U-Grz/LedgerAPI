#!/bin/bash

API_URL="http://206.189.112.225:3000"
NAME="Test User3"
EMAIL="testuser$(date +%s)@example.com"
PASSWORD="password123"

echo "=== Testing LedgerAPI ==="

# 1. Signup with properly formatted JSON
echo -e "\n1. Creating new user..."
SIGNUP_RESPONSE=$(curl -s -X POST $API_URL/signup \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"password_confirmation\":\"${PASSWORD}\"}")
echo $SIGNUP_RESPONSE

# 2. Login
echo -e "\n2. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST $API_URL/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")
echo $LOGIN_RESPONSE

# Extract token using jq (better) or sed (if jq not available)
if command -v jq &> /dev/null; then
    TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token // empty')
else
    TOKEN=$(echo $LOGIN_RESPONSE | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
fi

echo "Extracted Token: $TOKEN"

if [ -z "$TOKEN" ]; then
    echo "ERROR: Failed to get token. Cannot continue."
    exit 1
fi

# 3. Create Transaction
echo -e "\n3. Creating transaction..."
CREATE_RESPONSE=$(curl -s -X POST $API_URL/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amount": 50.00,
    "description": "Coffee",
    "category": "Food",
    "transaction_type": "expense"
  }')
echo $CREATE_RESPONSE

# 4. Get All Transactions
echo -e "\n4. Getting all transactions..."
curl -s -X GET $API_URL/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN"

# 5. Get Balance
echo -e "\n\n5. Getting balance..."
curl -s -X GET $API_URL/transactions/balance \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN"

# 6. Get Summary
echo -e "\n\n6. Getting summary..."
curl -s -X GET $API_URL/transactions/summary \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n=== Test Complete ==="
#!/bin/bash

API_URL="http://206.189.112.225:3000"
NAME="Test User"
EMAIL="testuser$(date +%s)@example.com"
PASSWORD="password123"

echo "=== Testing LedgerAPI ==="
echo "API URL: $API_URL"
echo "Email: $EMAIL"

# 1. Signup with properly formatted JSON
echo -e "\n=========================================="
echo "1. Creating new user..."
echo "=========================================="
SIGNUP_RESPONSE=$(curl -s -X POST $API_URL/signup \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"password_confirmation\":\"${PASSWORD}\"}")
echo "$SIGNUP_RESPONSE" | jq '.' 2>/dev/null || echo "$SIGNUP_RESPONSE"

# 2. Login
echo -e "\n=========================================="
echo "2. Logging in..."
echo "=========================================="
LOGIN_RESPONSE=$(curl -s -X POST $API_URL/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

# Extract token using jq (better) or sed (if jq not available)
if command -v jq &> /dev/null; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty')
else
    TOKEN=$(echo "$LOGIN_RESPONSE" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
fi

echo -e "\nExtracted Token: $TOKEN"

if [ -z "$TOKEN" ]; then
    echo "ERROR: Failed to get token. Cannot continue."
    echo "This might mean:"
    echo "  - Signup failed (check the signup response above)"
    echo "  - Login failed (check credentials)"
    echo "  - API returned unexpected JSON format"
    exit 1
fi

# 3. Create Transaction
echo -e "\n=========================================="
echo "3. Creating transaction..."
echo "=========================================="
TODAY=$(date +%Y-%m-%d)
CREATE_RESPONSE=$(curl -s -X POST $API_URL/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"amount\": 50.00,
    \"description\": \"Coffee\",
    \"category\": \"Food\",
    \"transaction_type\": \"expense\",
    \"date\": \"$TODAY\"
  }")
echo "$CREATE_RESPONSE" | jq '.' 2>/dev/null || echo "$CREATE_RESPONSE"

# 4. Get All Transactions
echo -e "\n=========================================="
echo "4. Getting all transactions..."
echo "=========================================="
TRANSACTIONS=$(curl -s -X GET $API_URL/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")
echo "$TRANSACTIONS" | jq '.' 2>/dev/null || echo "$TRANSACTIONS"

# 5. Get Balance
echo -e "\n=========================================="
echo "5. Getting balance..."
echo "=========================================="
BALANCE=$(curl -s -X GET $API_URL/transactions/balance \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")
echo "$BALANCE" | jq '.' 2>/dev/null || echo "$BALANCE"

# 6. Get Summary
echo -e "\n=========================================="
echo "6. Getting summary..."
echo "=========================================="
SUMMARY=$(curl -s -X GET $API_URL/transactions/summary \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")
echo "$SUMMARY" | jq '.' 2>/dev/null || echo "$SUMMARY"

# 7. Create another transaction
echo -e "\n=========================================="
echo "7. Creating another transaction (Income)..."
echo "=========================================="
CREATE_RESPONSE2=$(curl -s -X POST $API_URL/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"amount\": 1500.00,
    \"description\": \"Salary\",
    \"category\": \"Income\",
    \"transaction_type\": \"income\",
    \"date\": \"$TODAY\"
  }")
echo "$CREATE_RESPONSE2" | jq '.' 2>/dev/null || echo "$CREATE_RESPONSE2"

# 8. Get updated balance
echo -e "\n=========================================="
echo "8. Getting updated balance..."
echo "=========================================="
BALANCE2=$(curl -s -X GET $API_URL/transactions/balance \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")
echo "$BALANCE2" | jq '.' 2>/dev/null || echo "$BALANCE2"

echo -e "\n=========================================="
echo "=== Test Complete ==="
echo "=========================================="
echo "Summary:"
echo "  User: $EMAIL"
echo "  Token: ${TOKEN:0:20}..."
echo "  Transactions created: 2 (1 expense, 1 income)"
