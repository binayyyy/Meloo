import fs from 'node:fs/promises';
import path from 'node:path';

const outDir = path.resolve('artifacts');

const colors = {
  bg: '#F6F1E8',
  panel: '#FFF9F1',
  panelSoft: '#F8EFDf',
  border: '#D9C7AF',
  ink: '#16273D',
  muted: '#6B6F73',
  navy: '#102844',
  teal: '#0FA6B8',
  gold: '#D39B3C',
  line: '#7D8CA0',
  white: '#FFFFFF',
  ok: '#0B7C66',
};

function esc(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function writeSvg(fileName, svg) {
  return fs.writeFile(path.join(outDir, fileName), svg, 'utf8');
}

function boxHeight(fields) {
  return 44 + fields.length * 21 + 16;
}

function entityBox(entity, palette, opts = {}) {
  const h = boxHeight(entity.fields);
  const fill = opts.fill ?? colors.panel;
  const stroke = opts.stroke ?? palette;
  const fieldSize = opts.fieldSize ?? 13;
  const titleSize = opts.titleSize ?? 13;
  const lines = entity.fields
    .map(
      (field, index) =>
        `<text x="${entity.x + 16}" y="${entity.y + 66 + index * 21}" fill="${colors.ink}" font-size="${fieldSize}" font-weight="500">${esc(
          field,
        )}</text>`,
    )
    .join('');

  return `
    <g>
      <rect x="${entity.x}" y="${entity.y}" width="${entity.w}" height="${h}" rx="16" fill="${fill}" stroke="${stroke}" stroke-width="1.4"/>
      <rect x="${entity.x}" y="${entity.y}" width="${entity.w}" height="38" rx="16" fill="${stroke}"/>
      <rect x="${entity.x}" y="${entity.y + 20}" width="${entity.w}" height="18" fill="${stroke}"/>
      <text x="${entity.x + entity.w / 2}" y="${entity.y + 24}" fill="${colors.white}" font-size="${titleSize}" font-weight="800" text-anchor="middle">${esc(
        entity.title,
      )}</text>
      ${lines}
    </g>
  `;
}

function domainCard(domain) {
  return `
    <g>
      <rect x="${domain.x}" y="${domain.y}" width="${domain.w}" height="${domain.h}" rx="28" fill="rgba(255,249,241,0.76)" stroke="${domain.color}" stroke-width="1.8"/>
      <rect x="${domain.x + 20}" y="${domain.y - 16}" width="${Math.max(
        160,
        domain.label.length * 13,
      )}" height="34" rx="17" fill="${colors.bg}"/>
      <text x="${domain.x + 38}" y="${domain.y + 7}" fill="${domain.color}" font-size="18" font-weight="800" letter-spacing="1.6">${esc(
        domain.label,
      )}</text>
    </g>
  `;
}

function edgePoint(entity, side) {
  const h = boxHeight(entity.fields);
  switch (side) {
    case 'left':
      return { x: entity.x, y: entity.y + h / 2 };
    case 'right':
      return { x: entity.x + entity.w, y: entity.y + h / 2 };
    case 'top':
      return { x: entity.x + entity.w / 2, y: entity.y };
    case 'bottom':
      return { x: entity.x + entity.w / 2, y: entity.y + h };
    default:
      throw new Error(`Unknown side ${side}`);
  }
}

function relation(entityMap, fromId, fromSide, toId, toSide, mids = [], fromLabel = '', toLabel = '') {
  const fromEntity = entityMap.get(fromId);
  const toEntity = entityMap.get(toId);
  const from = edgePoint(fromEntity, fromSide);
  const to = edgePoint(toEntity, toSide);
  const points = [from, ...mids.map(([x, y]) => ({ x, y })), to];
  const path = points.map((p) => `${p.x},${p.y}`).join(' ');
  const firstMid = points[1] ?? to;
  const lastMid = points.at(-2) ?? from;
  const fromText = fromLabel
    ? `<text x="${(from.x + firstMid.x) / 2}" y="${(from.y + firstMid.y) / 2 - 6}" fill="${colors.muted}" font-size="12" font-weight="700">${esc(
        fromLabel,
      )}</text>`
    : '';
  const toText = toLabel
    ? `<text x="${(to.x + lastMid.x) / 2}" y="${(to.y + lastMid.y) / 2 - 6}" fill="${colors.muted}" font-size="12" font-weight="700">${esc(
        toLabel,
      )}</text>`
    : '';

  return `
    <g>
      <polyline points="${path}" fill="none" stroke="${colors.line}" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
      <circle cx="${from.x}" cy="${from.y}" r="3" fill="${colors.line}"/>
      <circle cx="${to.x}" cy="${to.y}" r="3" fill="${colors.line}"/>
      ${fromText}
      ${toText}
    </g>
  `;
}

function svgShell({ width, height, title, subtitle, body, legend }) {
  return `
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="12" stdDeviation="14" flood-color="#102844" flood-opacity="0.08"/>
    </filter>
  </defs>
  <rect width="100%" height="100%" fill="${colors.bg}"/>
  <circle cx="${width - 220}" cy="140" r="170" fill="rgba(15,166,184,0.08)"/>
  <circle cx="260" cy="${height - 130}" r="190" fill="rgba(211,155,60,0.08)"/>
  <text x="84" y="98" fill="${colors.navy}" font-size="58" font-weight="800" font-family="Georgia, 'Times New Roman', serif">${esc(
    title,
  )}</text>
  <text x="86" y="136" fill="${colors.muted}" font-size="18">${esc(subtitle)}</text>
  <line x1="84" y1="166" x2="680" y2="166" stroke="${colors.gold}" stroke-width="3"/>
  <g filter="url(#shadow)">${body}</g>
  ${legend}
</svg>`.trimStart();
}

function buildReportErd() {
  const width = 2600;
  const height = 1760;

  const domains = [
    { label: 'IDENTITY', x: 900, y: 70, w: 900, h: 430, color: colors.teal },
    { label: 'EVENTS', x: 860, y: 540, w: 940, h: 520, color: colors.navy },
    { label: 'VENDORS', x: 1890, y: 540, w: 600, h: 560, color: colors.teal },
    { label: 'SPONSORS', x: 110, y: 540, w: 660, h: 470, color: colors.gold },
    { label: 'COMMUNICATION', x: 980, y: 1110, w: 840, h: 520, color: colors.teal },
    { label: 'SUPPORT', x: 1910, y: 1170, w: 560, h: 290, color: colors.gold },
    { label: 'PAYMENTS', x: 130, y: 1140, w: 760, h: 360, color: colors.navy },
  ];

  const entities = [
    { id: 'users', title: 'USERS', x: 1190, y: 120, w: 260, fields: ['id (PK)', 'email', 'role', 'status', 'created_at'] },
    { id: 'user_profiles', title: 'USER_PROFILES', x: 1540, y: 120, w: 220, fields: ['id (PK)', 'user_id (FK)', 'full_name', 'avatar_url', 'phone'] },
    { id: 'user_settings', title: 'USER_SETTINGS', x: 1540, y: 290, w: 240, fields: ['id (PK)', 'user_id (FK)', 'notifications_enabled', 'privacy_level', 'ai_assist_enabled'] },
    { id: 'sessions', title: 'SESSIONS', x: 920, y: 130, w: 210, fields: ['id (PK)', 'user_id (FK)', 'created_at', 'expires_at'] },
    { id: 'events', title: 'EVENTS', x: 1210, y: 620, w: 280, fields: ['id (PK)', 'organizer_id (FK)', 'category_id (FK)', 'title', 'city', 'latitude', 'longitude', 'status'] },
    { id: 'event_categories', title: 'EVENT_CATEGORIES', x: 920, y: 650, w: 220, fields: ['id (PK)', 'name', 'slug'] },
    { id: 'ticket_types', title: 'TICKET_TYPES', x: 1210, y: 860, w: 250, fields: ['id (PK)', 'event_id (FK)', 'name', 'price', 'remaining'] },
    { id: 'registrations', title: 'REGISTRATIONS', x: 1540, y: 850, w: 240, fields: ['id (PK)', 'event_id (FK)', 'attendee_id (FK)', 'ticket_type_id (FK)', 'status'] },
    { id: 'vendor_profiles', title: 'VENDOR_PROFILES', x: 1980, y: 640, w: 240, fields: ['id (PK)', 'user_id (FK)', 'business_name', 'service_area', 'travel_radius_km', 'verified'] },
    { id: 'vendor_services', title: 'VENDOR_SERVICES', x: 2280, y: 590, w: 180, fields: ['id (PK)', 'vendor_id (FK)', 'name', 'base_price'] },
    { id: 'vendor_packages', title: 'VENDOR_PACKAGES', x: 2280, y: 780, w: 180, fields: ['id (PK)', 'vendor_id (FK)', 'name', 'price'] },
    { id: 'vendor_requests', title: 'VENDOR_REQUESTS', x: 1980, y: 860, w: 260, fields: ['id (PK)', 'event_id (FK)', 'organizer_id (FK)', 'vendor_id (FK)', 'status'] },
    { id: 'vendor_booking_preferences', title: 'VENDOR_BOOKING_PREFERENCES', x: 2140, y: 1010, w: 300, fields: ['id (PK)', 'vendor_id (FK)', 'allow_direct_booking', 'allow_request_booking'] },
    { id: 'sponsor_profiles', title: 'SPONSOR_PROFILES', x: 180, y: 650, w: 230, fields: ['id (PK)', 'user_id (FK)', 'company_name', 'industries', 'verified'] },
    { id: 'sponsorship_opportunities', title: 'SPONSORSHIP_OPPORTUNITIES', x: 180, y: 840, w: 300, fields: ['id (PK)', 'event_id (FK)', 'organizer_id (FK)', 'title', 'required_amount', 'status'] },
    { id: 'sponsorship_interests', title: 'SPONSORSHIP_INTERESTS', x: 540, y: 860, w: 220, fields: ['id (PK)', 'sponsor_id (FK)', 'opportunity_id (FK)', 'status'] },
    { id: 'conversations', title: 'CONVERSATIONS', x: 1080, y: 1210, w: 220, fields: ['id (PK)', 'type', 'created_at'] },
    { id: 'conversation_participants', title: 'CONVERSATION_PARTICIPANTS', x: 1380, y: 1180, w: 280, fields: ['id (PK)', 'conversation_id (FK)', 'user_id (FK)', 'joined_at'] },
    { id: 'messages', title: 'MESSAGES', x: 1110, y: 1410, w: 220, fields: ['id (PK)', 'conversation_id (FK)', 'sender_id (FK)', 'message_type'] },
    { id: 'notifications', title: 'NOTIFICATIONS', x: 1450, y: 1400, w: 230, fields: ['id (PK)', 'user_id (FK)', 'type', 'resource_type', 'read_at'] },
    { id: 'support_tickets', title: 'SUPPORT_TICKETS', x: 1990, y: 1230, w: 240, fields: ['id (PK)', 'user_id (FK)', 'category', 'status', 'priority'] },
    { id: 'escalations', title: 'ESCALATIONS', x: 2280, y: 1230, w: 180, fields: ['id (PK)', 'source_id', 'status', 'assigned_to'] },
    { id: 'bookings', title: 'BOOKINGS', x: 210, y: 1230, w: 220, fields: ['id (PK)', 'event_id (FK)', 'registration_id (FK)', 'status', 'amount'] },
    { id: 'payments', title: 'PAYMENTS', x: 500, y: 1230, w: 220, fields: ['id (PK)', 'booking_id (FK)', 'payer_id (FK)', 'status', 'amount'] },
    { id: 'refunds', title: 'REFUNDS', x: 560, y: 1410, w: 180, fields: ['id (PK)', 'payment_id (FK)', 'status', 'amount'] },
  ];

  const map = new Map(entities.map((e) => [e.id, e]));
  const edges = [
    relation(map, 'users', 'right', 'user_profiles', 'left', [], '1', '1'),
    relation(map, 'users', 'right', 'user_settings', 'left', [[1490, 350]], '1', '1'),
    relation(map, 'users', 'left', 'sessions', 'right', [], '1', '*'),
    relation(map, 'users', 'bottom', 'events', 'top', [[1330, 560]], '1', '*'),
    relation(map, 'users', 'bottom', 'registrations', 'top', [[1680, 550], [1680, 810]], '1', '*'),
    relation(map, 'users', 'right', 'vendor_profiles', 'left', [[1880, 220], [1880, 760]], '1', '1'),
    relation(map, 'users', 'left', 'sponsor_profiles', 'right', [[840, 220], [840, 720]], '1', '1'),
    relation(map, 'users', 'bottom', 'conversation_participants', 'top', [[1450, 560], [1450, 1140]], '1', '*'),
    relation(map, 'users', 'bottom', 'messages', 'top', [[1280, 560], [1280, 1370]], '1', '*'),
    relation(map, 'users', 'bottom', 'notifications', 'top', [[1560, 560], [1560, 1360]], '1', '*'),
    relation(map, 'users', 'bottom', 'support_tickets', 'top', [[2080, 560], [2080, 1190]], '1', '*'),
    relation(map, 'event_categories', 'right', 'events', 'left', [], '1', '*'),
    relation(map, 'events', 'bottom', 'ticket_types', 'top', [], '1', '*'),
    relation(map, 'events', 'right', 'registrations', 'left', [[1510, 970]], '1', '*'),
    relation(map, 'ticket_types', 'right', 'registrations', 'left', [[1500, 950]], '1', '*'),
    relation(map, 'events', 'right', 'vendor_requests', 'left', [[1870, 760], [1870, 980]], '1', '*'),
    relation(map, 'events', 'left', 'sponsorship_opportunities', 'right', [[820, 760], [820, 920]], '1', '*'),
    relation(map, 'vendor_profiles', 'right', 'vendor_services', 'left', [], '1', '*'),
    relation(map, 'vendor_profiles', 'right', 'vendor_packages', 'left', [[2250, 870]], '1', '*'),
    relation(map, 'vendor_profiles', 'bottom', 'vendor_requests', 'top', [], '1', '*'),
    relation(map, 'vendor_profiles', 'bottom', 'vendor_booking_preferences', 'top', [[2210, 980]], '1', '1'),
    relation(map, 'sponsor_profiles', 'bottom', 'sponsorship_interests', 'top', [[300, 980], [650, 980]], '1', '*'),
    relation(map, 'sponsorship_opportunities', 'right', 'sponsorship_interests', 'left', [], '1', '*'),
    relation(map, 'conversations', 'right', 'conversation_participants', 'left', [], '1', '*'),
    relation(map, 'conversations', 'bottom', 'messages', 'top', [[1190, 1380]], '1', '*'),
    relation(map, 'support_tickets', 'right', 'escalations', 'left', [], '1', '*'),
    relation(map, 'registrations', 'left', 'bookings', 'top', [[1660, 1100], [1660, 1530], [320, 1530]], '1', '1'),
    relation(map, 'bookings', 'right', 'payments', 'left', [], '1', '*'),
    relation(map, 'payments', 'bottom', 'refunds', 'top', [], '1', '*'),
  ];

  const body = `
    ${domains.map(domainCard).join('')}
    ${edges.join('')}
    ${entities.map((entity) => entityBox(entity, domains.find((d) => d.label === (
      entity.id.startsWith('user') || entity.id === 'users' || entity.id.includes('session') ? 'IDENTITY' :
      entity.id.startsWith('event') || entity.id.startsWith('ticket') || entity.id.startsWith('registration') ? 'EVENTS' :
      entity.id.startsWith('vendor') ? 'VENDORS' :
      entity.id.startsWith('sponsor') || entity.id.startsWith('sponsorship') ? 'SPONSORS' :
      entity.id.startsWith('conversation') || entity.id === 'messages' || entity.id === 'notifications' ? 'COMMUNICATION' :
      entity.id.startsWith('support') || entity.id === 'escalations' ? 'SUPPORT' :
      'PAYMENTS'
    )).color)).join('')}
  `;

  const legend = `
    <g>
      <rect x="2140" y="86" width="320" height="96" rx="18" fill="${colors.panel}" stroke="${colors.border}" stroke-width="1.2"/>
      <text x="2170" y="118" fill="${colors.navy}" font-size="17" font-weight="800">Report ERD</text>
      <text x="2170" y="145" fill="${colors.ink}" font-size="13">Clean overview with fewer fields and exact table links.</text>
      <text x="2170" y="167" fill="${colors.muted}" font-size="13">1 = one, * = many</text>
    </g>
  `;

  return svgShell({
    width,
    height,
    title: 'Meloo ERD',
    subtitle: 'Final report version: simplified fields, accurate relationships',
    body,
    legend,
  });
}

function buildTechnicalErd() {
  const width = 3380;
  const height = 2320;
  const domains = [
    { label: 'IDENTITY', x: 980, y: 60, w: 1100, h: 620, color: colors.teal },
    { label: 'EVENTS', x: 1010, y: 720, w: 1040, h: 720, color: colors.navy },
    { label: 'VENDORS', x: 2190, y: 720, w: 930, h: 840, color: colors.teal },
    { label: 'SPONSORS', x: 120, y: 740, w: 800, h: 700, color: colors.gold },
    { label: 'PAYMENTS', x: 120, y: 1600, w: 920, h: 430, color: colors.navy },
    { label: 'COMMUNICATION', x: 1120, y: 1520, w: 1080, h: 650, color: colors.teal },
    { label: 'SUPPORT', x: 2270, y: 1670, w: 840, h: 360, color: colors.gold },
  ];

  const entities = [
    { id: 'users', title: 'USERS', x: 1390, y: 120, w: 300, fields: ['id (PK)', 'email', 'password_hash', 'role', 'status', 'created_at', 'updated_at'] },
    { id: 'sessions', title: 'SESSIONS', x: 1010, y: 120, w: 260, fields: ['id (PK)', 'user_id (FK)', 'refresh_token_hash', 'device_info', 'created_at', 'expires_at'] },
    { id: 'email_tokens', title: 'EMAIL_VERIFICATION_TOKENS', x: 1010, y: 360, w: 330, fields: ['id (PK)', 'user_id (FK)', 'token_hash', 'created_at', 'expires_at', 'consumed_at'] },
    { id: 'reset_tokens', title: 'PASSWORD_RESET_TOKENS', x: 1010, y: 590, w: 330, fields: ['id (PK)', 'user_id (FK)', 'token_hash', 'created_at', 'expires_at', 'consumed_at'] },
    { id: 'user_profiles', title: 'USER_PROFILES', x: 1800, y: 120, w: 260, fields: ['id (PK)', 'user_id (FK)', 'full_name', 'avatar_url', 'phone', 'bio'] },
    { id: 'user_settings', title: 'USER_SETTINGS', x: 1800, y: 360, w: 300, fields: ['id (PK)', 'user_id (FK)', 'notifications_enabled', 'marketing_enabled', 'privacy_level', 'ai_assist_enabled'] },

    { id: 'event_categories', title: 'EVENT_CATEGORIES', x: 1100, y: 800, w: 240, fields: ['id (PK)', 'name', 'slug'] },
    { id: 'events', title: 'EVENTS', x: 1450, y: 770, w: 330, fields: ['id (PK)', 'organizer_id (FK)', 'category_id (FK)', 'title', 'description', 'venue', 'city', 'latitude', 'longitude', 'vendor_match_radius_km', 'start_at', 'end_at', 'status', 'visibility', 'cover_image_url', 'created_at', 'updated_at'] },
    { id: 'event_views', title: 'EVENT_VIEWS', x: 1870, y: 800, w: 260, fields: ['id (PK)', 'user_id (FK)', 'event_id (FK)', 'view_count', 'created_at', 'updated_at'] },
    { id: 'event_favorites', title: 'EVENT_FAVORITES', x: 1100, y: 1170, w: 250, fields: ['id (PK)', 'user_id (FK)', 'event_id (FK)', 'created_at'] },
    { id: 'ticket_types', title: 'TICKET_TYPES', x: 1450, y: 1160, w: 290, fields: ['id (PK)', 'event_id (FK)', 'name', 'price', 'quantity', 'remaining', 'sale_start_at', 'sale_end_at', 'created_at', 'updated_at'] },
    { id: 'registrations', title: 'REGISTRATIONS', x: 1850, y: 1140, w: 280, fields: ['id (PK)', 'event_id (FK)', 'attendee_id (FK)', 'ticket_type_id (FK)', 'quantity', 'status', 'created_at'] },

    { id: 'vendor_profiles', title: 'VENDOR_PROFILES', x: 2280, y: 800, w: 310, fields: ['id (PK)', 'user_id (FK)', 'business_name', 'description', 'category', 'service_area', 'latitude', 'longitude', 'travel_radius_km', 'portfolio_image_url', 'verification_document_url', 'verified', 'rating_average'] },
    { id: 'vendor_services', title: 'VENDOR_SERVICES', x: 2700, y: 780, w: 260, fields: ['id (PK)', 'vendor_id (FK)', 'name', 'description', 'base_price', 'pricing_model'] },
    { id: 'vendor_packages', title: 'VENDOR_PACKAGES', x: 2700, y: 1060, w: 260, fields: ['id (PK)', 'vendor_id (FK)', 'name', 'description', 'price'] },
    { id: 'vendor_requests', title: 'VENDOR_REQUESTS', x: 2280, y: 1200, w: 320, fields: ['id (PK)', 'event_id (FK)', 'organizer_id (FK)', 'vendor_id (FK)', 'status', 'message', 'proposed_budget', 'created_at', 'updated_at'] },
    { id: 'vendor_booking_preferences', title: 'VENDOR_BOOKING_PREFERENCES', x: 2660, y: 1360, w: 360, fields: ['id (PK)', 'vendor_id (FK)', 'allow_direct_booking', 'allow_request_booking'] },

    { id: 'sponsor_profiles', title: 'SPONSOR_PROFILES', x: 180, y: 820, w: 280, fields: ['id (PK)', 'user_id (FK)', 'company_name', 'description', 'industries', 'logo_url', 'website_url', 'verification_document_url', 'verified'] },
    { id: 'sponsorship_opportunities', title: 'SPONSORSHIP_OPPORTUNITIES', x: 180, y: 1170, w: 340, fields: ['id (PK)', 'event_id (FK)', 'organizer_id (FK)', 'title', 'description', 'required_amount', 'target_audience', 'benefits_offered', 'status', 'created_at', 'updated_at'] },
    { id: 'sponsorship_interests', title: 'SPONSORSHIP_INTERESTS', x: 580, y: 1170, w: 280, fields: ['id (PK)', 'sponsor_id (FK)', 'opportunity_id (FK)', 'status', 'message', 'created_at'] },

    { id: 'bookings', title: 'BOOKINGS', x: 210, y: 1700, w: 290, fields: ['id (PK)', 'type', 'requester_id (FK)', 'target_user_id (FK)', 'event_id (FK)', 'registration_id (FK)', 'status', 'amount', 'currency', 'created_at'] },
    { id: 'payments', title: 'PAYMENTS', x: 600, y: 1700, w: 280, fields: ['id (PK)', 'booking_id (FK)', 'payer_id (FK)', 'provider', 'provider_ref', 'amount', 'currency', 'status', 'paid_at', 'created_at'] },
    { id: 'refunds', title: 'REFUNDS', x: 700, y: 1940, w: 240, fields: ['id (PK)', 'payment_id (FK)', 'reason', 'status', 'amount'] },

    { id: 'conversations', title: 'CONVERSATIONS', x: 1230, y: 1640, w: 260, fields: ['id (PK)', 'type', 'created_at'] },
    { id: 'conversation_participants', title: 'CONVERSATION_PARTICIPANTS', x: 1580, y: 1600, w: 330, fields: ['id (PK)', 'conversation_id (FK)', 'user_id (FK)', 'joined_at'] },
    { id: 'messages', title: 'MESSAGES', x: 1260, y: 1920, w: 270, fields: ['id (PK)', 'conversation_id (FK)', 'sender_id (FK)', 'body', 'message_type', 'created_at'] },
    { id: 'notifications', title: 'NOTIFICATIONS', x: 1670, y: 1860, w: 280, fields: ['id (PK)', 'user_id (FK)', 'type', 'title', 'body', 'resource_type', 'resource_id', 'read_at', 'created_at'] },

    { id: 'support_tickets', title: 'SUPPORT_TICKETS', x: 2360, y: 1760, w: 300, fields: ['id (PK)', 'user_id (FK)', 'category', 'subject', 'description', 'status', 'priority', 'assigned_admin_id', 'assistant_suggestion', 'ai_confidence', 'created_at', 'updated_at'] },
    { id: 'escalations', title: 'ESCALATIONS', x: 2760, y: 1780, w: 260, fields: ['id (PK)', 'source_type', 'source_id', 'reason', 'ai_confidence', 'status', 'assigned_to', 'created_at', 'updated_at'] },
  ];

  const map = new Map(entities.map((e) => [e.id, e]));
  const edges = [
    relation(map, 'users', 'right', 'user_profiles', 'left', [], '1', '1'),
    relation(map, 'users', 'right', 'user_settings', 'left', [[1740, 450]], '1', '1'),
    relation(map, 'users', 'left', 'sessions', 'right', [], '1', '*'),
    relation(map, 'users', 'left', 'email_tokens', 'right', [[1330, 320]], '1', '*'),
    relation(map, 'users', 'left', 'reset_tokens', 'right', [[1320, 410], [1320, 680]], '1', '*'),
    relation(map, 'users', 'bottom', 'events', 'top', [[1520, 720]], '1', '*'),
    relation(map, 'users', 'bottom', 'event_views', 'top', [[1940, 720]], '1', '*'),
    relation(map, 'users', 'bottom', 'event_favorites', 'top', [[1250, 720], [1250, 1130]], '1', '*'),
    relation(map, 'users', 'bottom', 'registrations', 'top', [[1910, 720], [1910, 1090]], '1', '*'),
    relation(map, 'users', 'right', 'vendor_profiles', 'left', [[2190, 220], [2190, 930]], '1', '1'),
    relation(map, 'users', 'left', 'sponsor_profiles', 'right', [[900, 220], [900, 930]], '1', '1'),
    relation(map, 'users', 'bottom', 'conversation_participants', 'top', [[1740, 720], [1740, 1560]], '1', '*'),
    relation(map, 'users', 'bottom', 'messages', 'top', [[1460, 720], [1460, 1880]], '1', '*'),
    relation(map, 'users', 'bottom', 'notifications', 'top', [[1840, 720], [1840, 1820]], '1', '*'),
    relation(map, 'users', 'bottom', 'support_tickets', 'top', [[2540, 720], [2540, 1710]], '1', '*'),
    relation(map, 'users', 'left', 'bookings', 'top', [[980, 250], [980, 1640], [350, 1640]], '1', '*'),
    relation(map, 'users', 'left', 'payments', 'top', [[930, 280], [930, 1640], [740, 1640]], '1', '*'),
    relation(map, 'event_categories', 'right', 'events', 'left', [], '1', '*'),
    relation(map, 'events', 'right', 'event_views', 'left', [], '1', '*'),
    relation(map, 'events', 'left', 'event_favorites', 'top', [[1230, 1090]], '1', '*'),
    relation(map, 'events', 'bottom', 'ticket_types', 'top', [], '1', '*'),
    relation(map, 'events', 'bottom', 'registrations', 'top', [[1710, 1090]], '1', '*'),
    relation(map, 'ticket_types', 'right', 'registrations', 'left', [[1800, 1280]], '1', '*'),
    relation(map, 'events', 'right', 'vendor_requests', 'left', [[2170, 960], [2170, 1320]], '1', '*'),
    relation(map, 'events', 'left', 'sponsorship_opportunities', 'right', [[980, 900], [980, 1280]], '1', '*'),
    relation(map, 'vendor_profiles', 'right', 'vendor_services', 'left', [], '1', '*'),
    relation(map, 'vendor_profiles', 'right', 'vendor_packages', 'left', [[2650, 1120]], '1', '*'),
    relation(map, 'vendor_profiles', 'bottom', 'vendor_requests', 'top', [[2430, 1170]], '1', '*'),
    relation(map, 'vendor_profiles', 'bottom', 'vendor_booking_preferences', 'top', [[2790, 1320]], '1', '1'),
    relation(map, 'sponsor_profiles', 'bottom', 'sponsorship_interests', 'top', [[320, 1120], [720, 1120]], '1', '*'),
    relation(map, 'sponsorship_opportunities', 'right', 'sponsorship_interests', 'left', [], '1', '*'),
    relation(map, 'conversations', 'right', 'conversation_participants', 'left', [], '1', '*'),
    relation(map, 'conversations', 'bottom', 'messages', 'top', [[1360, 1880]], '1', '*'),
    relation(map, 'support_tickets', 'right', 'escalations', 'left', [], '1', '*'),
    relation(map, 'registrations', 'left', 'bookings', 'top', [[1800, 1360], [1800, 1615], [360, 1615]], '1', '1'),
    relation(map, 'bookings', 'right', 'payments', 'left', [], '1', '*'),
    relation(map, 'payments', 'bottom', 'refunds', 'top', [[740, 1910]], '1', '*'),
  ];

  const domainColorFor = (id) => {
    if (['users', 'sessions', 'email_tokens', 'reset_tokens', 'user_profiles', 'user_settings'].includes(id)) return colors.teal;
    if (['event_categories', 'events', 'event_views', 'event_favorites', 'ticket_types', 'registrations'].includes(id)) return colors.navy;
    if (id.startsWith('vendor')) return colors.teal;
    if (id.startsWith('sponsor') || id.startsWith('sponsorship')) return colors.gold;
    if (['bookings', 'payments', 'refunds'].includes(id)) return colors.navy;
    if (['conversations', 'conversation_participants', 'messages', 'notifications'].includes(id)) return colors.teal;
    return colors.gold;
  };

  const body = `
    ${domains.map(domainCard).join('')}
    ${edges.join('')}
    ${entities.map((entity) => entityBox(entity, domainColorFor(entity.id), { fieldSize: 13 })).join('')}
  `;

  const legend = `
    <g>
      <rect x="2760" y="98" width="470" height="112" rx="18" fill="${colors.panel}" stroke="${colors.border}" stroke-width="1.2"/>
      <text x="2790" y="130" fill="${colors.navy}" font-size="17" font-weight="800">Technical ERD</text>
      <text x="2790" y="157" fill="${colors.ink}" font-size="13">Complete schema view for implementation and documentation.</text>
      <text x="2790" y="181" fill="${colors.muted}" font-size="13">Labels are taken from the current TypeORM entity model.</text>
    </g>
  `;

  return svgShell({
    width,
    height,
    title: 'Meloo ERD',
    subtitle: 'Technical version: full entity view with schema-verified fields',
    body,
    legend,
  });
}

function buildArchitecture() {
  const width = 2500;
  const height = 1460;

  const body = `
    <g>
      <rect x="90" y="220" width="650" height="1020" rx="30" fill="rgba(255,249,241,0.78)" stroke="${colors.teal}" stroke-width="2"/>
      <rect x="920" y="160" width="690" height="1080" rx="30" fill="rgba(255,249,241,0.78)" stroke="${colors.navy}" stroke-width="2"/>
      <rect x="1790" y="220" width="600" height="1020" rx="30" fill="rgba(255,249,241,0.78)" stroke="${colors.gold}" stroke-width="2"/>

      <text x="130" y="212" fill="${colors.teal}" font-size="20" font-weight="800" letter-spacing="1.8">CLIENTS</text>
      <text x="960" y="152" fill="${colors.navy}" font-size="20" font-weight="800" letter-spacing="1.8">APPLICATION CORE</text>
      <text x="1830" y="212" fill="${colors.gold}" font-size="20" font-weight="800" letter-spacing="1.8">DATA AND INTEGRATIONS</text>

      ${archCard(170, 300, 470, 'Flutter App', colors.teal, [
        'Attendee, organizer, vendor, sponsor, admin mobile flows',
        'Maps-based location selection',
        'Auth, tickets, support, chat, vendor matching',
      ])}
      ${archCard(170, 650, 470, 'Next.js Admin', colors.teal, [
        'Internal Meloo platforms console',
        'User state, verification, support, moderation, uploads',
        'Operational snapshot and system health',
      ])}

      ${archCard(1010, 240, 500, 'NestJS API', colors.navy, [
        'REST controllers and auth guards',
        'TypeORM domain services',
        'Validation, uploads, admin actions',
      ])}
      ${archCard(1010, 540, 500, 'Core Domains', colors.navy, [
        'Users and auth',
        'Events and registrations',
        'Vendors and sponsors',
        'Chat, notifications, support, payments',
      ])}
      ${archCard(1010, 850, 500, 'Platform Services', colors.navy, [
        'Distance-based vendor matching',
        'Upload pipeline',
        'Admin moderation and trust flows',
        'Optional AI and payment adapters',
      ])}

      ${archCard(1860, 300, 430, 'PostgreSQL / PostGIS', colors.gold, [
        'Primary relational data store',
        'Transaction-safe operational records',
        'PostGIS-ready path for geospatial querying',
      ])}
      ${archCard(1860, 590, 430, 'Uploads Storage', colors.gold, [
        'Profile images',
        'Verification documents',
        'Event and sponsor media',
      ])}
      ${archCard(1860, 880, 430, 'External Services', colors.gold, [
        'Stripe optional',
        'AI provider optional',
        'Browser maps and tile services',
      ])}

      ${arrow(640, 460, 1010, 460, colors.line, 'HTTPS / JSON')}
      ${arrow(640, 810, 1010, 810, colors.line, 'HTTPS / JSON')}
      ${arrow(1510, 390, 1860, 390, colors.line, 'TypeORM')}
      ${arrow(1510, 710, 1860, 710, colors.line, 'Files')}
      ${arrow(1510, 1000, 1860, 1000, colors.line, 'Provider APIs')}

      <rect x="960" y="1280" width="1320" height="94" rx="18" fill="${colors.panel}" stroke="${colors.border}" stroke-width="1.2"/>
      <text x="996" y="1315" fill="${colors.navy}" font-size="16" font-weight="800">Primary runtime path</text>
      <text x="996" y="1347" fill="${colors.ink}" font-size="14">Flutter App / Next.js Admin → NestJS API → PostgreSQL/PostGIS, with uploads storage and optional Stripe / AI integrations.</text>
    </g>
  `;

  const legend = `
    <g>
      <rect x="1940" y="88" width="360" height="72" rx="18" fill="${colors.panel}" stroke="${colors.border}" stroke-width="1.2"/>
      <text x="1970" y="117" fill="${colors.navy}" font-size="17" font-weight="800">System Architecture</text>
      <text x="1970" y="142" fill="${colors.muted}" font-size="13">Meloo deployment and service interaction view</text>
    </g>
  `;

  return svgShell({
    width,
    height,
    title: 'Meloo Architecture',
    subtitle: 'System view aligned to the current application structure',
    body,
    legend,
  });
}

function archCard(x, y, w, title, color, bullets) {
  const h = 126 + bullets.length * 26;
  const bulletLines = bullets
    .map(
      (item, index) =>
        `<text x="${x + 20}" y="${y + 78 + index * 26}" fill="${colors.ink}" font-size="14">• ${esc(
          item,
        )}</text>`,
    )
    .join('');

  return `
    <g>
      <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="20" fill="${colors.panel}" stroke="${color}" stroke-width="1.6"/>
      <rect x="${x}" y="${y}" width="${w}" height="42" rx="20" fill="${color}"/>
      <rect x="${x}" y="${y + 24}" width="${w}" height="18" fill="${color}"/>
      <text x="${x + 20}" y="${y + 27}" fill="${colors.white}" font-size="16" font-weight="800">${esc(title)}</text>
      ${bulletLines}
    </g>
  `;
}

function arrow(x1, y1, x2, y2, stroke, label) {
  return `
    <g>
      <line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${stroke}" stroke-width="2.3"/>
      <polygon points="${x2 - 14},${y2 - 7} ${x2},${y2} ${x2 - 14},${y2 + 7}" fill="${stroke}"/>
      <rect x="${(x1 + x2) / 2 - 60}" y="${y1 - 20}" width="120" height="24" rx="12" fill="${colors.bg}"/>
      <text x="${(x1 + x2) / 2}" y="${y1 - 4}" fill="${colors.muted}" font-size="12" font-weight="700" text-anchor="middle">${esc(
        label,
      )}</text>
    </g>
  `;
}

await fs.mkdir(outDir, { recursive: true });
await writeSvg('meloo-erd-report.svg', buildReportErd());
await writeSvg('meloo-erd-technical.svg', buildTechnicalErd());
await writeSvg('meloo-system-architecture.svg', buildArchitecture());
console.log('Generated diagrams in artifacts/');
