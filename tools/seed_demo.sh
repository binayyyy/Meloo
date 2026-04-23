#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${1:-http://127.0.0.1:3000/api}"
ROOT_DIR="$(pwd)"
DEMO_DIR="$ROOT_DIR/.tooling/demo"
TOKENS_FILE="$DEMO_DIR/demo_tokens.json"
LOCAL_SETUP_KEY="${LOCAL_SETUP_KEY:-change-this-local-setup-key}"

mkdir -p "$DEMO_DIR"

request_json() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local auth_header="${4:-}"

  if [[ -n "$body" ]]; then
    curl -fsS -X "$method" "$url" \
      -H "Content-Type: application/json" \
      ${auth_header:+-H "$auth_header"} \
      -d "$body"
  else
    curl -fsS -X "$method" "$url" \
      ${auth_header:+-H "$auth_header"}
  fi
}

extract_json() {
  local expr="$1"
  node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const o=JSON.parse(s);const v=$expr;process.stdout.write(typeof v==='string'?v:JSON.stringify(v));});"
}

signup_user() {
  local email="$1"
  local password="$2"
  local role="$3"
  local payload
  payload=$(printf '{"email":"%s","password":"%s","role":"%s"}' "$email" "$password" "$role")
  request_json POST "$API_BASE_URL/auth/signup" "$payload" >/dev/null || true
}

login_user() {
  local email="$1"
  local password="$2"
  local payload
  payload=$(printf '{"email":"%s","password":"%s"}' "$email" "$password")
  request_json POST "$API_BASE_URL/auth/login" "$payload"
}

PASSWORD="Passw0rd!23"

request_json POST "$API_BASE_URL/auth/bootstrap-local-admin" "{\"email\":\"admin@meloo.local\",\"password\":\"$PASSWORD\",\"fullName\":\"Amina Admin\"}" "x-setup-key: $LOCAL_SETUP_KEY" >/dev/null
signup_user "organizer@meloo.local" "$PASSWORD" "organizer"
signup_user "vendor@meloo.local" "$PASSWORD" "vendor"
signup_user "sponsor@meloo.local" "$PASSWORD" "sponsor"
signup_user "attendee@meloo.local" "$PASSWORD" "attendee"

admin_login=$(login_user "admin@meloo.local" "$PASSWORD")
organizer_login=$(login_user "organizer@meloo.local" "$PASSWORD")
vendor_login=$(login_user "vendor@meloo.local" "$PASSWORD")
sponsor_login=$(login_user "sponsor@meloo.local" "$PASSWORD")
attendee_login=$(login_user "attendee@meloo.local" "$PASSWORD")

ADMIN_TOKEN=$(printf '%s' "$admin_login" | extract_json "o.tokens.accessToken")
ORGANIZER_TOKEN=$(printf '%s' "$organizer_login" | extract_json "o.tokens.accessToken")
VENDOR_TOKEN=$(printf '%s' "$vendor_login" | extract_json "o.tokens.accessToken")
SPONSOR_TOKEN=$(printf '%s' "$sponsor_login" | extract_json "o.tokens.accessToken")
ATTENDEE_TOKEN=$(printf '%s' "$attendee_login" | extract_json "o.tokens.accessToken")

categories_json=$(request_json GET "$API_BASE_URL/event-categories")
CATEGORY_ID=$(printf '%s' "$categories_json" | extract_json "o[0].id")

event_payload=$(cat <<JSON
{"title":"Smart Event Showcase","description":"A live demo event for the platform covering tickets, sponsors, vendors, and support workflows.","categoryId":"$CATEGORY_ID","venue":"Civic Center","city":"Kathmandu","latitude":27.7172,"longitude":85.3240,"vendorMatchRadiusKm":60,"startAt":"2026-05-01T10:00:00.000Z","endAt":"2026-05-01T16:00:00.000Z","status":"published","visibility":"public"}
JSON
)
event_json=$(request_json POST "$API_BASE_URL/events" "$event_payload" "Authorization: Bearer $ORGANIZER_TOKEN")
EVENT_ID=$(printf '%s' "$event_json" | extract_json "o.id")

free_ticket_payload='{"name":"General Admission","price":"0.00","quantity":50,"saleStartAt":"2026-04-01T00:00:00.000Z","saleEndAt":"2026-05-01T09:30:00.000Z"}'
paid_ticket_payload='{"name":"VIP Pass","price":"49.99","quantity":20,"saleStartAt":"2026-04-01T00:00:00.000Z","saleEndAt":"2026-05-01T09:30:00.000Z"}'
free_ticket_json=$(request_json POST "$API_BASE_URL/events/$EVENT_ID/ticket-types" "$free_ticket_payload" "Authorization: Bearer $ORGANIZER_TOKEN")
paid_ticket_json=$(request_json POST "$API_BASE_URL/events/$EVENT_ID/ticket-types" "$paid_ticket_payload" "Authorization: Bearer $ORGANIZER_TOKEN")
FREE_TICKET_ID=$(printf '%s' "$free_ticket_json" | extract_json "o.id")
PAID_TICKET_ID=$(printf '%s' "$paid_ticket_json" | extract_json "o.id")

request_json PATCH "$API_BASE_URL/vendors/me/profile" '{"businessName":"Northwind Events","description":"Full-service event production vendor covering staging, logistics, and on-site operations.","category":"Event Production","serviceArea":"Kathmandu Valley","latitude":27.7103,"longitude":85.3206,"travelRadiusKm":80}' "Authorization: Bearer $VENDOR_TOKEN" >/dev/null
request_json PATCH "$API_BASE_URL/vendors/me/booking-preference" '{"allowDirectBooking":true,"allowRequestBooking":true}' "Authorization: Bearer $VENDOR_TOKEN" >/dev/null
request_json POST "$API_BASE_URL/vendors/me/services" '{"name":"Stage setup","description":"Stage design, install, and breakdown for conferences and showcases.","basePrice":"1200.00","pricingModel":"fixed"}' "Authorization: Bearer $VENDOR_TOKEN" >/dev/null
request_json POST "$API_BASE_URL/vendors/me/packages" '{"name":"Launch package","description":"Production support, staffing, and day-of coordination.","price":"2500.00"}' "Authorization: Bearer $VENDOR_TOKEN" >/dev/null

vendor_profile_json=$(request_json GET "$API_BASE_URL/vendors/me/profile" "" "Authorization: Bearer $VENDOR_TOKEN")
VENDOR_PROFILE_ID=$(printf '%s' "$vendor_profile_json" | extract_json "o.id")

request_json PATCH "$API_BASE_URL/sponsors/me/profile" '{"companyName":"Blue Peak Capital","description":"A regional sponsor focused on technology, youth communities, and startup ecosystems.","industries":"technology, startups, education"}' "Authorization: Bearer $SPONSOR_TOKEN" >/dev/null
sponsor_profile_json=$(request_json GET "$API_BASE_URL/sponsors/me/profile" "" "Authorization: Bearer $SPONSOR_TOKEN")
SPONSOR_PROFILE_ID=$(printf '%s' "$sponsor_profile_json" | extract_json "o.id")

opportunity_payload='{"title":"Title Sponsor","description":"Headline placement across event assets and stage moments.","requiredAmount":"5000.00","targetAudience":"Founders, students, and operators","benefitsOffered":"Main stage recognition, branded booth, and social promotion","status":"open"}'
opportunity_json=$(request_json POST "$API_BASE_URL/events/$EVENT_ID/sponsorship-opportunities" "$opportunity_payload" "Authorization: Bearer $ORGANIZER_TOKEN")
OPPORTUNITY_ID=$(printf '%s' "$opportunity_json" | extract_json "o.id")
request_json POST "$API_BASE_URL/sponsorship-opportunities/$OPPORTUNITY_ID/interests" '{"message":"We are interested in the audience and would like to discuss fit and deliverables."}' "Authorization: Bearer $SPONSOR_TOKEN" >/dev/null

request_json POST "$API_BASE_URL/vendors/$VENDOR_PROFILE_ID/requests" "{\"eventId\":\"$EVENT_ID\",\"message\":\"We need staging and operations support for this showcase.\",\"proposedBudget\":\"1800.00\",\"directBookingPreferred\":true}" "Authorization: Bearer $ORGANIZER_TOKEN" >/dev/null

request_json POST "$API_BASE_URL/events/$EVENT_ID/registrations" "{\"ticketTypeId\":\"$FREE_TICKET_ID\",\"quantity\":1}" "Authorization: Bearer $ATTENDEE_TOKEN" >/dev/null
if [[ -n "${STRIPE_SECRET_KEY:-}" ]]; then
  return_url="${PAYMENT_RETURN_URL:-http://127.0.0.1:8081}"
  request_json POST "$API_BASE_URL/events/$EVENT_ID/payments/checkout-session" "{\"ticketTypeId\":\"$PAID_TICKET_ID\",\"quantity\":1,\"returnUrl\":\"$return_url\"}" "Authorization: Bearer $ATTENDEE_TOKEN" >/dev/null
fi

request_json POST "$API_BASE_URL/support/tickets" '{"category":"payment","subject":"Checkout readiness follow-up","description":"Please confirm the paid VIP checkout path is configured correctly before it goes live."}' "Authorization: Bearer $ATTENDEE_TOKEN" >/dev/null

cat >"$TOKENS_FILE" <<JSON
{
  "apiBaseUrl": "$API_BASE_URL",
  "password": "$PASSWORD",
  "adminEmail": "admin@meloo.local",
  "organizerEmail": "organizer@meloo.local",
  "vendorEmail": "vendor@meloo.local",
  "sponsorEmail": "sponsor@meloo.local",
  "attendeeEmail": "attendee@meloo.local",
  "adminToken": "$ADMIN_TOKEN",
  "organizerToken": "$ORGANIZER_TOKEN",
  "vendorToken": "$VENDOR_TOKEN",
  "sponsorToken": "$SPONSOR_TOKEN",
  "attendeeToken": "$ATTENDEE_TOKEN",
  "eventId": "$EVENT_ID",
  "vendorProfileId": "$VENDOR_PROFILE_ID",
  "sponsorProfileId": "$SPONSOR_PROFILE_ID",
  "opportunityId": "$OPPORTUNITY_ID"
}
JSON

printf 'Seeded demo data at %s\n' "$TOKENS_FILE"
