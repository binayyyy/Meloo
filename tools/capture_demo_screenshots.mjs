import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);
const repoRoot = process.cwd();
const demoDataPath = path.join(repoRoot, '.tooling/demo/demo-data.json');
const screenshotsDir = path.join(repoRoot, 'artifacts/screenshots');
const chromiumPath = process.env.CHROMIUM_BIN ?? '/usr/bin/chromium';
const mobileBaseUrl = process.env.MOBILE_WEB_URL ?? 'http://127.0.0.1:8081';
const adminBaseUrl = process.env.ADMIN_WEB_URL ?? 'http://127.0.0.1:3001';
const screenshotProfileSuffix = process.env.SCREENSHOT_PROFILE_SUFFIX ?? '';

async function main() {
  if (process.env.SKIP_DEMO_SEED !== '1') {
    await execFileAsync(process.execPath, [path.join(repoRoot, 'tools/seed_demo.mjs')], {
      cwd: repoRoot,
    });
  }
  await mkdir(screenshotsDir, { recursive: true });
  const demoData = JSON.parse(await readFile(demoDataPath, 'utf8'));

  const mobileShots = [
    {
      name: 'mobile-login.png',
      url: `${mobileBaseUrl}/?demo_route=login`,
      size: '430,932',
    },
    {
      name: 'mobile-sign-up.png',
      url: `${mobileBaseUrl}/?demo_route=signup`,
      size: '430,932',
    },
    {
      name: 'mobile-forgot-password.png',
      url: `${mobileBaseUrl}/?demo_route=forgot-password`,
      size: '430,932',
    },
    {
      name: 'mobile-attendee-home.png',
      role: 'attendee',
      size: '430,932',
    },
    {
      name: 'mobile-organizer-home.png',
      role: 'organizer',
      size: '430,932',
    },
    {
      name: 'mobile-vendor-home.png',
      role: 'vendor',
      size: '430,932',
    },
    {
      name: 'mobile-sponsor-home.png',
      role: 'sponsor',
      size: '430,932',
    },
    {
      name: 'mobile-attendee-event-detail.png',
      role: 'attendee',
      size: '430,932',
      demoRoute: 'event-detail',
      eventId: demoData.eventId,
      manageMode: false,
    },
    {
      name: 'mobile-attendee-register-ticket-sheet.png',
      role: 'attendee',
      size: '430,932',
      demoRoute: 'event-detail',
      eventId: demoData.eventId,
      manageMode: false,
      demoSheet: 'register-ticket',
      ticketKind: 'paid',
    },
    {
      name: 'mobile-attendee-support-ticket-sheet.png',
      role: 'attendee',
      size: '430,932',
      demoSheet: 'support-ticket',
    },
    {
      name: 'mobile-organizer-event-manage.png',
      role: 'organizer',
      size: '430,932',
      demoRoute: 'event-detail',
      eventId: demoData.eventId,
      manageMode: true,
    },
    {
      name: 'mobile-organizer-create-event-sheet.png',
      role: 'organizer',
      size: '430,932',
      demoSheet: 'create-event',
    },
    {
      name: 'mobile-organizer-create-ticket-sheet.png',
      role: 'organizer',
      size: '430,932',
      demoRoute: 'event-detail',
      eventId: demoData.eventId,
      manageMode: true,
      demoSheet: 'create-ticket',
    },
    {
      name: 'mobile-organizer-vendor-request-sheet.png',
      role: 'organizer',
      size: '430,932',
      demoSheet: 'vendor-request',
    },
    {
      name: 'mobile-organizer-sponsorship-opportunity-sheet.png',
      role: 'organizer',
      size: '430,932',
      demoSheet: 'sponsor-opportunity',
    },
    {
      name: 'mobile-organizer-opportunity-interests-sheet.png',
      role: 'organizer',
      size: '430,932',
      demoSheet: 'opportunity-interests',
    },
    {
      name: 'mobile-organizer-planning-assistant-sheet.png',
      role: 'organizer',
      size: '430,932',
      demoSheet: 'planning-assistant',
    },
    {
      name: 'mobile-organizer-chat-sheet.png',
      role: 'organizer',
      size: '430,932',
      demoSheet: 'conversation',
    },
    {
      name: 'mobile-vendor-profile-sheet.png',
      role: 'vendor',
      size: '430,932',
      demoSheet: 'vendor-profile',
    },
    {
      name: 'mobile-vendor-service-sheet.png',
      role: 'vendor',
      size: '430,932',
      demoSheet: 'vendor-service',
    },
    {
      name: 'mobile-vendor-package-sheet.png',
      role: 'vendor',
      size: '430,932',
      demoSheet: 'vendor-package',
    },
    {
      name: 'mobile-vendor-chat-sheet.png',
      role: 'vendor',
      size: '430,932',
      demoSheet: 'conversation',
    },
    {
      name: 'mobile-sponsor-profile-sheet.png',
      role: 'sponsor',
      size: '430,932',
      demoSheet: 'sponsor-profile',
    },
    {
      name: 'mobile-sponsor-interest-sheet.png',
      role: 'sponsor',
      size: '430,932',
      demoSheet: 'sponsor-interest',
    },
    {
      name: 'mobile-sponsor-chat-sheet.png',
      role: 'sponsor',
      size: '430,932',
      demoSheet: 'conversation',
    },
  ];

  for (const shot of mobileShots) {
    const url = shot.url ?? buildMobileBootstrapUrl(demoData, shot);
    await captureScreenshot({
      url,
      outputPath: path.join(screenshotsDir, shot.name),
      size: shot.size,
      profileDir: path.join(
        repoRoot,
        '.tooling/demo',
        `chromium-${shot.name.replace(/\.png$/, '')}${screenshotProfileSuffix}`,
      ),
    });
  }

  const adminToken = demoData.roles.admin.tokens.accessToken;
  const adminTokenB64 = Buffer.from(adminToken, 'utf8').toString('base64');
  const adminUrl = `${adminBaseUrl}/bootstrap-admin.html?token_b64=${encodeURIComponent(
    adminTokenB64,
  )}&redirect=${encodeURIComponent('/')}`;
  await captureScreenshot({
    url: adminUrl,
    outputPath: path.join(screenshotsDir, 'admin-operations-dashboard.png'),
    size: '1440,1100',
    profileDir: path.join(
      repoRoot,
      `.tooling/demo/chromium-admin${screenshotProfileSuffix}`,
    ),
  });

  await writeFile(
    path.join(screenshotsDir, 'manifest.json'),
    JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        files: [
          ...mobileShots.map((item) => item.name),
          'admin-operations-dashboard.png',
        ],
      },
      null,
      2,
    ),
  );

  console.log(`Screenshots written to ${screenshotsDir}`);
}

function buildMobileBootstrapUrl(demoData, shot) {
  const sessionJson = JSON.stringify(demoData.roles[shot.role]);
  const sessionB64 = Buffer.from(sessionJson, 'utf8').toString('base64');
  const params = new URLSearchParams();
  params.set('demo_session_b64', sessionB64);
  if (shot.demoRoute) {
    params.set('demo_route', shot.demoRoute);
  }
  if (shot.demoSheet) {
    params.set('demo_sheet', shot.demoSheet);
  }
  if (shot.eventId) {
    params.set('eventId', shot.eventId);
  }
  if (shot.manageMode != null) {
    params.set('manageMode', String(shot.manageMode));
  }
  if (shot.ticketKind) {
    params.set('ticket_kind', shot.ticketKind);
  }
  return `${mobileBaseUrl}/?${params.toString()}`;
}

async function captureScreenshot({ url, outputPath, size, profileDir }) {
  await mkdir(profileDir, { recursive: true });
  await execFileAsync(chromiumPath, [
    '--headless',
    '--no-sandbox',
    '--disable-gpu',
    '--hide-scrollbars',
    '--run-all-compositor-stages-before-draw',
    '--virtual-time-budget=8000',
    `--user-data-dir=${profileDir}`,
    `--window-size=${size}`,
    `--screenshot=${outputPath}`,
    url,
  ]);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
