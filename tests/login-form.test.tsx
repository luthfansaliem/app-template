import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("@/app/login/actions", () => ({
  login: vi.fn(async () => ({})),
  signup: vi.fn(async () => ({})),
}));

import { LoginForm } from "@/app/login/login-form";

describe("LoginForm", () => {
  it("renders email, password and both buttons", () => {
    render(<LoginForm />);
    expect(screen.getByLabelText("Email")).toBeInTheDocument();
    expect(screen.getByLabelText("Password")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Login" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Daftar" })).toBeInTheDocument();
  });
});
