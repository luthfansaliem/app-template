import { notFound, redirect } from "next/navigation";
import { logout } from "@/app/login/actions";
import { createClient } from "@/lib/supabase/server";

export default async function OrgLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ orgSlug: string }>;
}) {
  const { orgSlug } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // RLS only returns organizations the user belongs to, so a miss means 404 (no tenant leak).
  const { data: org } = await supabase.from("organizations").select("id, name, slug").eq("slug", orgSlug).maybeSingle();
  if (!org) notFound();

  return (
    <div className="min-h-screen">
      <header className="flex items-center justify-between border-b border-gray-200 bg-white px-6 py-3">
        <span className="font-semibold">{org.name}</span>
        <div className="flex items-center gap-4 text-sm">
          <span className="text-gray-600">{user.email}</span>
          <form action={logout}>
            <button type="submit" className="rounded-md border border-gray-300 px-3 py-1">
              Logout
            </button>
          </form>
        </div>
      </header>
      {children}
    </div>
  );
}
