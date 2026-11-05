import { describe, expect, it } from "vitest";
import { isPublicPath, resolveRedirect } from "@/lib/supabase/proxy";

describe("resolveRedirect", () => {
  it("sends anonymous users to /login", () => {
    expect(resolveRedirect("/acme/dashboard", false)).toBe("/login");
    expect(resolveRedirect("/", false)).toBe("/login");
  });
  it("lets anonymous users reach public paths", () => {
    expect(resolveRedirect("/login", false)).toBeNull();
    expect(resolveRedirect("/auth/callback", false)).toBeNull();
  });
  it("sends authenticated users away from /login", () => {
    expect(resolveRedirect("/login", true)).toBe("/");
  });
  it("lets authenticated users through", () => {
    expect(resolveRedirect("/acme/dashboard", true)).toBeNull();
  });
});

describe("isPublicPath", () => {
  it("does not match lookalike prefixes", () => {
    expect(isPublicPath("/login-help")).toBe(false);
    expect(isPublicPath("/authors")).toBe(false);
  });
});
