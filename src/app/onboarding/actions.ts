"use server";

import { redirect } from "next/navigation";
import { isValidSlug, slugify } from "@/lib/slug";
import { createClient } from "@/lib/supabase/server";

export type OnboardingState = { error?: string };

export async function createOrganization(_prev: OnboardingState, formData: FormData): Promise<OnboardingState> {
  const name = String(formData.get("name") ?? "").trim();
  if (!name) return { error: "Nama organisasi wajib diisi." };

  const slug = slugify(String(formData.get("slug") ?? "") || name);
  if (!isValidSlug(slug)) {
    return { error: "Slug harus 3-40 karakter (huruf kecil, angka, tanda hubung) dan bukan kata yang dicadangkan." };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("create_organization", { p_name: name, p_slug: slug });
  if (error) {
    return { error: error.code === "23505" ? "Slug sudah dipakai." : "Gagal membuat organisasi." };
  }

  redirect(`/${slug}/dashboard`);
}
