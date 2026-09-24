# SCL V70 Final Package

Shining Child Leaders School — V70 website build.

## Included
- `index.html` — the complete V70 single-file frontend, including the public school site, curriculum/calendar, attendance interfaces, timetable/teacher profile integration, staff/worker and vacancy tools, leadership/community features, and the V70 management/automation interfaces.
- `.nojekyll` — recommended GitHub Pages marker (kept in the repository separately).

## Supabase
The SCL Supabase backend is deployed separately. The frontend calls the deployed SCL Edge Functions and must never contain a service-role secret.

## Important role rule
A secondary Class Supervisor may supervise **one secondary class only**. The database trigger enforces this for active assignments. Class Supervisor is a dedicated Workers/Vacancy position, not an assistant role.

## GitHub Pages
Place `index.html` at the repository root. Keep `README.md` and `.nojekyll` in the repository. Replace the old `index.html` with this V70 build rather than creating another nested website folder.
