# SCL Platform — Audit & Repair Report (V99 patch)

Base file used: the V89 "IMAGE-FIX" build from your zip (external image assets,
not the older base64-embedded `index-8.html`). All 7 images you re-uploaded
were checked byte-for-byte and are already the same files embedded in that
build — nothing was missing there.

## Method
- Extracted and `node --check`'d all 78 inline `<script>` blocks individually,
  before and after every edit. All pass (no syntax errors).
- Read the actual runtime code for auth, scroll behavior, the bottom-nav "+"
  button, and the payment/receipt flow before touching anything — not guessed.
- Every change below is additive or a surgical in-place edit to the exact
  function involved. Nothing was deleted. No script block was rewritten wholesale.

## What was actually fixed (verified in the source, not assumed)

**1. Payment verification (spec #4)**
The receipt flow already did in-browser OCR (Tesseract.js) but only pulled a
reference number and showed a wall of raw text; it never structured amount/date,
never reduced its own retention of the receipt image, and had no confirm/reject
functions at all. Fixed:
- OCR now extracts reference, amount, and date as separate fields, not just text.
- After a payment is submitted, the local file input, the image preview, and any
  `blob:` object URL are cleared/revoked immediately, and in-memory references
  are dropped — the browser stops holding onto the image right after submit.
- The payload sent to your backend now carries `extractedFields`, plus
  `notifyRoles:['management_admin','technical_admin']` and
  `notifyExcludeRoles:['affairs_admin']`, and a `retentionPolicy` hint asking the
  server to delete the stored receipt image after verification.
- **Important limit:** your Edge Functions (`scl-public-api` etc.) are not in
  anything you've given me. I cannot see or edit them, so I cannot *guarantee*
  the server actually deletes the image, filters notifications by role, or
  enforces "first confirmation wins." I've built the frontend to send the right
  signals and to behave correctly locally; someone still needs to make the
  server-side function honor `retentionPolicy` / `notifyRoles` / `notifyExcludeRoles`.
- Added `window.sclAdminConfirmPayment(id)` and `window.sclAdminRejectPayment(id, reason)`:
  role-gated (management_admin / technical_admin / developer only — never
  affairs_admin), first confirmation flips status to CONFIRMED immediately,
  further confirmations are recorded but change nothing, rejecting removes the
  pending record and requires the payer to resubmit. These update the local
  ledger now and best-effort call `/api/payments/:id/confirm` and `/reject` if
  your backend exposes them — if it doesn't yet, wire those two routes up.
- Payments already started as PENDING and already don't block other modules —
  that part was correct before and is unchanged.

**2. Bottom-bar "+" button (spec #8)**
It previously did exactly one thing for every user: open student registration.
Replaced with a real Quick Actions sheet, reusing your existing `.modal`
pattern (no new modal system introduced): Profile / Pay / Announcements /
Support for everyone, plus Register Student / Attendance / Payment
Verification / Create Announcement for admins only, gated by role. The
original function is wrapped, not replaced — every other nav button
(profile/comments/posts/support) behaves exactly as before.

**3. Top logo-coin + middle-left shortcut bar scroll behavior (spec #7)**
This didn't exist at all before — only the bottom bar had scroll-hide logic.
Added one new, independent scroll listener (your existing bottom-bar listener
was left untouched) that hides the top coin and the shortcut toggle on scroll
**up** and shows them on scroll **down** — the deliberate mirror of the bottom
bar, so some navigation is always on screen no matter which way the user
scrolls.

## What I looked at hard and did *not* touch, and why

- **Multiple auth implementations (15 separate `auth()`/session helpers across
  different script blocks).** All 29 references to the session key agree on
  using `sessionStorage.getItem('sclAuthSession')` — that part is actually
  consistent, not broken. What differs is how each closure interprets the
  `roles`/`permissions` array. Rewriting all of this into one canonical module
  is exactly the kind of change your own brief warns about ("do not fix one
  feature by breaking another") — I cannot verify 15 independent call sites
  against a live Supabase backend from here. I did not touch it. If this is
  actually causing visible bugs (e.g. an admin sometimes not seeing admin
  options), tell me the specific screen and I'll fix that one call site.
- **Title/heading contrast (spec #6).** I checked the actual CSS: night mode
  already has thorough light-on-dark rules; day mode's core components
  (`.scl-role-panel`, `.scl-att-card`, `.modal .card`, `.hero`) already set
  explicit, correctly-contrasted colors with `!important`. I could not find a
  concretely broken selector by reading the CSS alone, and I have no way to
  render this file in a browser here to see an actual invisible title. Rather
  than guess and risk breaking a component that already works, I left this
  alone. **If you can screenshot the specific screen/modal where a title
  disappears, I can fix that exact selector precisely.**
- **`manifest.webmanifest` and `sw.js`** are referenced by `index.html` but
  were not in your zip — you likely already have them in your GitHub repo. I
  added minimal fallback versions to this delivery, clearly marked: **only use
  them if you don't already have your own.** Don't overwrite a working service
  worker with the generic one included here.

## Honest quality assessment
This is not a 9/10 or 10/10 platform yet, and I'm not going to claim it is.
What I can stand behind: the four items above are real, evidenced fixes,
syntax-checked, and non-destructive. What I can't stand behind, because I
can't see or test it: your Supabase Edge Functions, Row Level Security rules,
real device/browser rendering, and the other 17 items in your brief that touch
backend/auth architecture. Anything backend-shaped needs either your Edge
Function source pasted in, or a live staging link, before it can honestly be
called "fixed" rather than "designed for."

## If you want the next pass to go further
Most useful things you could hand me next, in order of impact:
1. The Supabase Edge Function source (`scl-public-api` at minimum).
2. A screenshot of any screen where text is actually hard to read.
3. Confirmation of whether `manifest.webmanifest`/`sw.js` already exist in your
   GitHub repo (so I know whether to keep or discard the fallbacks here).
