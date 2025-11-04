import Link from "next/link";

export const metadata = {
  title: "Replacement Tesla Rentals for Cope Collision Customers | EV Boise",
  description:
    "Your Tesla’s in the shop — but you don’t have to drive gas. EV Boise delivers a Model 3 or Model Y directly to Cope Collision or your home.",
  robots: "noindex, nofollow", // Prevents SEO indexing
};

export default function CopeCollisionPage() {
  return (
    <main className="min-h-screen flex flex-col bg-gray-50 text-gray-800">
      {/* Header / Hero Section */}
      <section className="bg-white shadow-sm text-center px-6 py-12">
        <h1 className="text-3xl font-semibold text-gray-900">
          Your Tesla’s in the shop — but you don’t have to drive gas.
        </h1>
        <p className="mt-4 text-gray-600 max-w-2xl mx-auto">
          EV Boise provides temporary Tesla rentals for{" "}
          <strong>Cope Collision</strong> customers. Stay electric while your
          car is being repaired — we deliver directly to the shop or your home.
        </p>
        <button className="mt-6 px-8 py-3 bg-green-600 text-white text-lg font-medium rounded-xl hover:bg-green-700 transition">
          Check Availability
        </button>
      </section>

      {/* Value Proposition Section */}
      <section className="bg-gray-100 py-12">
        <div className="max-w-5xl mx-auto grid sm:grid-cols-3 gap-8 text-center">
          <div className="bg-white rounded-xl shadow p-6">
            <div className="text-4xl mb-3">⚡</div>
            <h3 className="font-semibold text-gray-900">
              Insurance-Friendly Rates
            </h3>
            <p className="text-sm text-gray-600 mt-2">
              We work directly with major insurance providers to streamline your
              rental coverage and billing.
            </p>
          </div>
          <div className="bg-white rounded-xl shadow p-6">
            <div className="text-4xl mb-3">🚗</div>
            <h3 className="font-semibold text-gray-900">Fast Delivery</h3>
            <p className="text-sm text-gray-600 mt-2">
              We’ll have your replacement Tesla ready at Cope Collision or
              delivered to your driveway — often the same day.
            </p>
          </div>
          <div className="bg-white rounded-xl shadow p-6">
            <div className="text-4xl mb-3">🧾</div>
            <h3 className="font-semibold text-gray-900">Simple Agreement</h3>
            <p className="text-sm text-gray-600 mt-2">
              All paperwork is digital and quick — no Turo logins or lengthy
              forms. One signature and you’re set.
            </p>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="bg-white py-16 border-t text-center">
        <h2 className="text-2xl font-semibold text-gray-900 mb-8">
          How It Works
        </h2>
        <div className="max-w-4xl mx-auto grid sm:grid-cols-3 gap-8">
          <div>
            <div className="text-3xl mb-2">1️⃣</div>
            <p className="font-medium text-gray-800">Scan & Reserve</p>
            <p className="text-sm text-gray-600 mt-1">
              Scan the QR code on your Cope Collision card or flyer to visit
              this page and request your Tesla.
            </p>
          </div>
          <div>
            <div className="text-3xl mb-2">2️⃣</div>
            <p className="font-medium text-gray-800">We Deliver Your Tesla</p>
            <p className="text-sm text-gray-600 mt-1">
              Delivery to Cope Collision or your preferred address within hours.
            </p>
          </div>
          <div>
            <div className="text-3xl mb-2">3️⃣</div>
            <p className="font-medium text-gray-800">Return Made Easy</p>
            <p className="text-sm text-gray-600 mt-1">
              When your car’s repaired, we’ll pick up the rental — no extra
              steps required.
            </p>
          </div>
        </div>
      </section>

      {/* Partner Branding */}
      <section className="bg-gray-50 py-12 text-center">
        <p className="text-sm uppercase tracking-wide text-gray-500 mb-2">
          In partnership with
        </p>
        <h3 className="text-lg font-semibold text-gray-900">
          Cope Collision Meridian
        </h3>
        <p className="text-gray-600 mt-2 text-sm">
          Tesla-Approved Collision Center | Meridian, Idaho
        </p>
      </section>

      {/* Footer */}
      <footer className="bg-white py-6 border-t text-center text-sm text-gray-500">
        <p>Boise-owned. EV Boise LLC © {new Date().getFullYear()}.</p>
        <p className="mt-1">
          Questions?{" "}
          <Link
            href="mailto:info@evboise.com"
            className="text-green-600 hover:underline"
          >
            info@evboise.com
          </Link>
        </p>
      </footer>
    </main>
  );
}
