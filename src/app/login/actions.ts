"use server";

import { redirect } from "next/navigation";
import { parseCredentials } from "@/lib/auth/validate";
import { createClient } from "@/lib/supabase/server";

export type AuthState = { error?: string; message?: string };

export async function login(_prev: AuthState, formData: FormData): Promise<AuthState> {
  const parsed = parseCredentials(formData);
  if ("error" in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(parsed);
  if (error) return { error: "Email atau password salah." };

  redirect("/");
}

export async function signup(_prev: AuthState, formData: FormData): Promise<AuthState> {
  const parsed = parseCredentials(formData);
  if ("error" in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp(parsed);
  if (error) return { error: error.message };

  // With email confirmation enabled there is no session until the link is clicked.
  if (!data.session) return { message: "Pendaftaran berhasil. Cek email untuk konfirmasi, lalu login." };
  redirect("/");
}

export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
