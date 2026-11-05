export const RESERVED_SLUGS = ["login", "auth", "onboarding", "api", "dashboard", "_next"];

const SLUG_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/;

export function slugify(input: string): string {
  return input
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40)
    .replace(/-+$/g, "");
}

export function isValidSlug(slug: string): boolean {
  return slug.length >= 3 && slug.length <= 40 && SLUG_RE.test(slug) && !RESERVED_SLUGS.includes(slug);
}
