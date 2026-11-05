import { describe, expect, it } from "vitest";
import { parseCredentials } from "@/lib/auth/validate";

function form(data: Record<string, string>) {
  const fd = new FormData();
  Object.entries(data).forEach(([k, v]) => fd.set(k, v));
  return fd;
}

describe("parseCredentials", () => {
  it("returns trimmed credentials when valid", () => {
    expect(parseCredentials(form({ email: " a@b.co ", password: "12345678" }))).toEqual({
      email: "a@b.co",
      password: "12345678",
    });
  });
  it("rejects empty fields", () => {
    expect(parseCredentials(form({ email: "", password: "" }))).toHaveProperty("error");
  });
  it("rejects invalid email", () => {
    expect(parseCredentials(form({ email: "nope", password: "12345678" }))).toHaveProperty("error");
  });
  it("rejects short password", () => {
    expect(parseCredentials(form({ email: "a@b.co", password: "123" }))).toHaveProperty("error");
  });
});
