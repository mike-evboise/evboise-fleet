export default function Hero() {
  return (
    <section className="w-full bg-gray-50 py-16 px-6 text-center">
      {/* Headline */}
      <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-4">
        Keep Driving a Tesla While Yours Is Being Repaired
      </h1>

      {/* Subheadline */}
      <p className="text-lg text-gray-600 max-w-2xl mx-auto mb-8">
        EVBoise provides Idaho’s only dedicated Tesla rental service—delivered
        directly to Cope Collision or your home. Insurance-friendly, local, and
        stress-free.
      </p>

      {/* Call to Action */}
      <a
        href="/repair"
        className="inline-block bg-evboise-green text-white font-semibold py-3 px-8 rounded-lg shadow-md hover:bg-green-700 transition"
      >
        Get My Tesla Quote
      </a>
    </section>
  );
}
