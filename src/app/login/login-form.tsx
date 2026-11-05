"use client";

import { useActionState } from "react";
import { login, signup, type AuthState } from "./actions";

const initial: AuthState = {};

export function LoginForm() {
  const [loginState, loginAction, loginPending] = useActionState(login, initial);
  const [signupState, signupAction, signupPending] = useActionState(signup, initial);
  const pending = loginPending || signupPending;
  const error = loginState.error ?? signupState.error;
  const message = signupState.message;

  return (
    <form className="space-y-4" action={loginAction}>
      <div>
        <label htmlFor="email" className="block text-sm font-medium">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2"
        />
      </div>
      <div>
        <label htmlFor="password" className="block text-sm font-medium">
          Password
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          minLength={8}
          className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2"
        />
      </div>

      {error && (
        <p role="alert" className="text-sm text-red-600">
          {error}
        </p>
      )}
      {message && (
        <p role="status" className="text-sm text-green-700">
          {message}
        </p>
      )}

      <div className="flex gap-2">
        <button
          type="submit"
          disabled={pending}
          className="flex-1 rounded-md bg-gray-900 px-4 py-2 text-white disabled:opacity-50"
        >
          Login
        </button>
        <button
          type="submit"
          formAction={signupAction}
          disabled={pending}
          className="flex-1 rounded-md border border-gray-300 px-4 py-2 disabled:opacity-50"
        >
          Daftar
        </button>
      </div>
    </form>
  );
}
