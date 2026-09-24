# SCL V70 Final Package

Shining Child Leaders School — V70 integrated frontend and Supabase automation layer.

## Included
- `index.html` — V70 website build with student attendance + timetable/teacher profile integration + Automation Center.
- `supabase/functions/scl-automation-center/index.ts` — authenticated admin automation dashboard endpoint (already deployed to the SCL Supabase project).
- `supabase/migrations/automation_and_class_supervisor_rules.sql` — reproducible schema/constraint foundation for automation tasks and one-class secondary Class Supervisor enforcement.

## Important role rule
A secondary Class Supervisor may supervise **one secondary class only**. The database trigger enforces this for active assignments. Class Supervisor is also available in the Workers / Vacancy role list.

## Supabase deployment
The live Edge Function name is `scl-automation-center`.

## GitHub Pages
Use `index.html` as the repository root entry file. Keep the Supabase backend deployment separate from GitHub Pages; never put service-role secrets in the HTML.
