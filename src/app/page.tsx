import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

// Entry point: send the user to their first organization, or to onboarding.
export default async function Home() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: memberships } = await supabase
    .from("members")
    .select("organizations(slug)")
    .eq("user_id", user.id)
    .order("created_at", { ascending: true })
    .limit(1);

  const slug = memberships?.[0]?.organizations?.slug;
  redirect(slug ? `/${slug}/dashboard` : "/onboarding");
}
