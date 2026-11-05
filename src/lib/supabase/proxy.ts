import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import type { Database } from "@/lib/types/database";
import { getSupabaseEnv } from "./env";

const PUBLIC_PATHS = ["/login", "/auth"];

export function isPublicPath(pathname: string): boolean {
  return PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(`${p}/`));
}

/** Where an unauthenticated / authenticated request should be sent, or null to continue. */
export function resolveRedirect(pathname: string, isAuthenticated: boolean): string | null {
  if (!isAuthenticated && !isPublicPath(pathname)) return "/login";
  if (isAuthenticated && pathname === "/login") return "/";
  return null;
}

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });
  const { url, anonKey } = getSupabaseEnv();

  const supabase = createServerClient<Database>(url, anonKey, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
      },
    },
  });

  // getUser() validates the token with Supabase Auth; never trust getSession() here.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const target = resolveRedirect(request.nextUrl.pathname, Boolean(user));
  if (target) {
    const redirect = NextResponse.redirect(new URL(target, request.url));
    response.cookies.getAll().forEach((c) => redirect.cookies.set(c));
    return redirect;
  }
  return response;
}
