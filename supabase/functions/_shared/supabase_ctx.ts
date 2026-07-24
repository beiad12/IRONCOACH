import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

/**
 * Builds two Supabase clients for an incoming request:
 *  - `userClient`: scoped to the caller's JWT, so any query through it is
 *    subject to RLS exactly as if the client had made it directly. Used to
 *    verify identity and read data the function needs on the user's behalf.
 *  - `adminClient`: the service-role client, used only for writes that must
 *    bypass RLS by design (e.g. inserting assistant messages, appending to
 *    `ai_insights`). Never returned to or influenced by client input beyond
 *    the authenticated user id.
 *
 * Throws a 401-flavored error if the JWT is missing/invalid — callers
 * should catch and return `401` themselves so behavior is explicit in each
 * function's `index.ts`.
 */
export async function buildRequestContext(req: Request): Promise<{
  userId: string;
  userClient: SupabaseClient;
  adminClient: SupabaseClient;
}> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    throw new Response(JSON.stringify({ error: "Invalid or expired session" }), {
      status: 401,
    });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  return { userId: data.user.id, userClient, adminClient };
}
