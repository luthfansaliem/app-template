"use client";

import { useActionState } from "react";
import { createOrganization, type OnboardingState } from "./actions";

const initial: OnboardingState = {};

export function OnboardingForm() {
  const [state, action, pending] = useActionState(createOrganization, initial);

  return (
    <form action={action} className="space-y-4">
      <div>
        <label htmlFor="name" className="block text-sm font-medium">
          Nama organisasi
        </label>
        <input id="name" name="name" required className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2" />
      </div>
      <div>
        <label htmlFor="slug" className="block text-sm font-medium">
          Slug (opsional)
        </label>
        <input
          id="slug"
          name="slug"
          placeholder="acme-inc"
          className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2"
        />
      </div>
      {state.error && (
        <p role="alert" className="text-sm text-red-600">
          {state.error}
        </p>
      )}
      <button type="submit" disabled={pending} className="w-full rounded-md bg-gray-900 px-4 py-2 text-white disabled:opacity-50">
        Buat organisasi
      </button>
    </form>
  );
}
