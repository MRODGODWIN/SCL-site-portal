# SCL V89 — Single Source Deployment Package

## Decision
Do NOT delete the SCL Supabase project or its database. The current project already contains the
V89-compatible tables and Edge Functions. The correct operation is to make GitHub match this V89
frontend package and keep Supabase as the persistent backend.

## GitHub package
Upload/replace the website files with:
- index.html
- manifest.webmanifest
- sw.js
- assets/*
- backend/scl-backend-contract.json
- this guide

The public GitHub Pages root must serve `index.html`.

## Supabase project
Project ref: `eypdoeqiojopkbzckjor`
Project URL: https://eypdoeqiojopkbzckjor.supabase.co

The V89 page calls these Edge Functions:
- scl-public-api
- scl-educational-intelligence
- scl-community
- scl-attendance
- scl-worker-api
- scl-service-rank-api
- scl-rank-archive-api
- scl-student-attendance
- scl-leadership

The project also contains `scl-automation-center`, which is an authenticated admin automation
function.

## Important security rule
The browser contains only the Supabase publishable key. Never place the Supabase service-role/secret
key in index.html, GitHub Pages, the app bundle, or any other client-side file.

## Authentication / passkeys
V89 explicitly opts into Supabase experimental passkey support. The frontend has therefore been
pinned to `@supabase/supabase-js@2.105.0`, which is the minimum version documented by Supabase for
passkeys.

For production passkeys, configure the final HTTPS app origin and stable WebAuthn relying-party ID
in Supabase Authentication → Passkeys. Do this before enrolling users, because changing the relying
party ID invalidates existing passkeys.

## PWA / app readiness
The package includes a manifest and service worker. API/auth traffic is deliberately not cached.
Navigation uses network-first behavior so GitHub Pages updates are not permanently trapped in an old
cache.

## V89 frontend optimization performed
- Extracted embedded images from the monolithic HTML into `assets/`.
- Reused identical embedded assets instead of storing duplicate base64 copies.
- Pinned the Supabase JS client version.
- Corrected the authoritative embedded website-version constant to V89.
- Added installable PWA metadata and real SCL logo icons.
- Added a safe service worker that does not cache Supabase API/auth responses.

## Existing Supabase audit findings
The project is ACTIVE_HEALTHY and the public tables inspected are RLS-enabled.
Two performance advisories concern unindexed foreign keys on `student_leadership_badges`.
There is also an Auth security advisory: leaked-password protection is disabled. Enable it in
Supabase Authentication settings; this is an account/project security setting rather than a
frontend file change.

## Final deployment order
1. Keep the existing Supabase project/data.
2. Replace the GitHub Pages site with this V89 package.
3. Configure the final GitHub Pages/custom-domain URL in Supabase Auth URL settings.
4. Configure Google OAuth only if Google sign-in is intended.
5. Configure Passkeys with the final HTTPS origin.
6. Open the deployed site and test: login, registration, fees/payment, results, attendance,
   profile, service rank, student attendance, leadership badges, community, and Educational Intelligence.
7. Only after those tests should the website be wrapped as the Android/iOS app.

## App conversion rule
The mobile app should use the same Supabase project and the same backend contracts. Do not create a
second database for the app. Native app authentication should use the same Supabase Auth identity
system; WebAuthn/passkey configuration must additionally include the final native-app origin when
the chosen app framework requires it.
