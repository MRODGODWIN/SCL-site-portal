// Supabase Edge Function: scl-notify  — sends parent/staff emails (Resend) and SMS (Termii).
// Deploy:  supabase functions deploy scl-notify
// Secrets: supabase secrets set RESEND_API_KEY=... TERMII_API_KEY=... TERMII_SENDER_ID=SCLSchool \
//          SCL_MAIL_FROM="Shining Child Leaders School <notices@YOURDOMAIN>" SCL_SCHOOL_EMAIL=shiningchildleader@gmail.com
// (Resend needs a verified sending domain; without TERMII_API_KEY only emails are sent.)
// The website calls this automatically after attendance, CBT results and assignment posts/grades.
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
const phone = (p: string) => String(p || "").replace(/\D/g, "").replace(/^0/, "234");
const esc = (s: string) => String(s).replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c] as string));

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { messages = [], summary = "", school_email } = await req.json();
    const RESEND = Deno.env.get("RESEND_API_KEY"), TERMII = Deno.env.get("TERMII_API_KEY");
    const FROM = Deno.env.get("SCL_MAIL_FROM") || "Shining Child Leaders School <onboarding@resend.dev>";
    const SCHOOL = Deno.env.get("SCL_SCHOOL_EMAIL") || school_email || "shiningchildleader@gmail.com";
    const SENDER = Deno.env.get("TERMII_SENDER_ID") || "SCLSchool";
    let email = 0, sms = 0, failed = 0;
    const sendMail = async (to: string, subject: string, text: string) => {
      if (!RESEND) { failed++; return; }
      const r = await fetch("https://api.resend.com/emails", { method: "POST",
        headers: { Authorization: `Bearer ${RESEND}`, "Content-Type": "application/json" },
        body: JSON.stringify({ from: FROM, to: [to], subject, html: `<p>${esc(text).replace(/\n/g, "<br>")}</p>` }) });
      r.ok ? email++ : failed++;
    };
    for (const m of messages.slice(0, 300)) {
      if (m.email) await sendMail(m.email, m.subject || "School notice", m.text || "");
      if (m.phone && TERMII) {
        const r = await fetch("https://api.ng.termii.com/api/sms/send", { method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ to: phone(m.phone), from: SENDER, sms: m.text, type: "plain", channel: "generic", api_key: TERMII }) });
        r.ok ? sms++ : failed++;
      }
    }
    // one summary copy to the school email, which has full access
    await sendMail(SCHOOL, "[Copy] " + (summary || messages.length + " notice(s)"), (summary ? summary + "\n\n" : "") + messages.map((m: any) => `${m.email || m.phone}: ${m.text}`).join("\n"));
    const ok = RESEND ? failed < Math.max(1, messages.length) : false;
    return new Response(JSON.stringify({ ok, sent: { email, sms }, failed }), { headers: { ...cors, "Content-Type": "application/json" }, status: ok ? 200 : 500 });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), { headers: { ...cors, "Content-Type": "application/json" }, status: 500 });
  }
});
