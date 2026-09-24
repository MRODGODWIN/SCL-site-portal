# Shining Child Leaders School — SCL V70 Final

This is the final V70 single-file SCL official website package prepared for GitHub Pages deployment.

## Final V70 corrections
- Short Break and Long Break use the same timetable colour.
- Friday ends with the distinct **12:30 PM–1:00 PM Closing Period** colour; no academic content is filled after 1:00 PM on Friday.
- Primary and Secondary timetables are separate and switchable, including a dedicated **Switch Primary / Secondary** control.
- Secondary timetable teacher availability shows active teaching staff only and supports teacher-period highlighting.
- The SCL rotating/quick logo hub is preserved and its Student Leaders, Staff Rank, Medals & Records and Anthem destinations are active.
- The manual Day/Night control is positioned at the extreme upper-right so it no longer blocks the SCL logo hub.
- The supplied SCL admission/school-life poster is integrated into the hero panel with the existing transparent orbit/glow effect layered over it.
- The 38 alphabetically ordered shortcut items are wired to real SCL feature destinations.
- The SCL Staff & School Management Portal exposes the main operational workspaces, including attendance, timetable, staff/workers, fees, results, curriculum, badges, community, service rank, branch/GPS and support tools.
- Student Attendance visibly renders the register table with a separate green **Present** confirmation switch and a two-position **Absent / Late** control.
- Present attendance locks after confirmation. Current-day Absent and Late can transition between those two states; Present cannot be reversed. The backend also rejects changes to a previous school day and requires every student to be called before submission.
- Technical Administrator is recognised by the V70 frontend/backend administrator role checks as `technical_admin`, consistent with the SCL rule that Technical Administrator has unrestricted system authority. Actual credentials are never stored in this static HTML package.

## Supabase backend
The package expects the configured SCL Supabase project and existing Edge Functions. The student-attendance Edge Function was deployed as version 7 during this final pass.

## Deployment
Upload `index.html` to the root of the official GitHub Pages repository. Keep `.nojekyll` in the repository.

No Node.js file is required for this single-file V70 deployment.
