import { describe, expect, it } from "vitest";
import { isValidSlug, slugify } from "@/lib/slug";

describe("slugify", () => {
  it("lowercases and hyphenates", () => {
    expect(slugify("Acme Inc.")).toBe("acme-inc");
  });
  it("strips accents and edge hyphens", () => {
    expect(slugify("  Café Été!! ")).toBe("cafe-ete");
  });
  it("caps length at 40 without trailing hyphen", () => {
    const s = slugify("a".repeat(39) + " b");
    expect(s.length).toBeLessThanOrEqual(40);
    expect(s.endsWith("-")).toBe(false);
  });
});

describe("isValidSlug", () => {
  it("accepts normal slugs", () => expect(isValidSlug("acme-inc")).toBe(true));
  it("rejects too short, bad chars and reserved words", () => {
    expect(isValidSlug("ab")).toBe(false);
    expect(isValidSlug("Acme")).toBe(false);
    expect(isValidSlug("a--b")).toBe(false);
    expect(isValidSlug("login")).toBe(false);
  });
});
