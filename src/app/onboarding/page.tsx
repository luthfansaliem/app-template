import { OnboardingForm } from "./onboarding-form";

export default function OnboardingPage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-sm flex-col justify-center px-4">
      <h1 className="mb-2 text-2xl font-semibold">Buat organisasi</h1>
      <p className="mb-6 text-sm text-gray-600">Anda belum tergabung di organisasi mana pun.</p>
      <OnboardingForm />
    </main>
  );
}
