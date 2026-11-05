export type Credentials = { email: string; password: string };

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function parseCredentials(formData: FormData): Credentials | { error: string } {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) return { error: "Email dan password wajib diisi." };
  if (!EMAIL_RE.test(email)) return { error: "Format email tidak valid." };
  if (password.length < 8) return { error: "Password minimal 8 karakter." };
  return { email, password };
}
