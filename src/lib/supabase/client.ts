import { createBrowserClient } from "@supabase/ssr";
import type { Database } from "@/lib/types/database";

// NEXT_PUBLIC_* must be referenced literally so Next inlines them in the browser bundle.
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
