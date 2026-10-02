// Deploy: supabase functions deploy scl-student-attendance-notify
// Writes a parent notice ONLY for students marked Present (P) or Late (L). Absence details are never pushed to anyone else.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type" };
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const user = await createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } }).auth.getUser();
  const roles: string[] = user.data.user?.app_metadata?.roles ?? [];
  if (!roles.some(r => ["teacher","staff","developer","technical_admin","management_admin","affairs_admin"].includes(r))) return new Response("forbidden", { status: 403, headers: cors });
  const { keys } = await req.json();
  const { data: recs } = await sb.from("student_attendance").select("*").in("att_key", keys ?? []);
  let made = 0;
  for (const r of recs ?? []) {
    const ids = Object.keys(r.marks).filter(k => k !== "__k" && ["P","L"].includes(r.marks[k]));
    // ADAPT column names to your students table:
    const { data: kids } = await sb.from("students").select("id, full_name, parent_email").in("id", ids);
    for (const k of kids ?? []) {
      if (!k.parent_email) continue;
      const st = r.marks[k.id] === "L" ? "late" : "present";
      const { error } = await sb.from("student_attendance_notices").upsert({ att_key: r.att_key, student_id: String(k.id), parent_email: k.parent_email, att_date: r.att_date, status: st, message: `${k.full_name} arrived at school (${st}) on ${r.att_date}.` }, { onConflict: "att_key,student_id", ignoreDuplicates: true });
      if (!error) made++;
    }
  }
  // Delivery hook: connect your email/SMS/push provider here and set sent_at after sending.
  return new Response(JSON.stringify({ notices: made }), { headers: { ...cors, "Content-Type": "application/json" } });
});
