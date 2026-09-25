# SCL V86 — Gate + Loader + Attendance Sign-In

Shining Child Leaders School (SCL) official website package.

## V86 behavior
- The branded SCL loader is displayed first on every page load.
- After the loader completes, unauthenticated visitors see the secure public Gate.
- LOGIN is for normal SCL platform access for all users.
- SIGN IN is reserved for staff/teacher/worker and admin/management attendance.
- Attendance Sign-In window: 7:00 AM–4:00 PM Africa/Lagos.
- A person who has signed attendance remains in the platform during the workday; they do not repeatedly sign in/out to use site features.
- Sign-out is a separate attendance action and does not log the user out of SCL.
- In-app/browser sign-out reminders are issued near/after 4:00 PM while the authenticated site session is active. Browser notification display depends on the device/browser permission state.
- After 4:00 PM, new attendance Sign-In entries are closed, while normal LOGIN remains available. An already signed-in worker can still open attendance to record their Sign Out.
- First Term resumption is 7 September 2026; the public calendar also contains the 2026/2027 term dates.
- Profile double-tap/double-click closes the profile without logging the user out.

## Deployment
Upload the package contents to the root of the official SCL GitHub Pages repository:
https://github.com/MRODGODWIN/SCL-site-portal

Do not rename the repository.
