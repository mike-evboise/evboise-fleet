// app/layout.tsx
import Image from "next/image";
import Link from "next/link";
import "./styles/globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "EV Boise – Tesla Rentals & EV Services",
  description:
    "Locally owned Tesla Model 3 rentals and EV support services in Boise, Idaho.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/favicon.ico" />
      </head>
      <body className="bg-gray-50 text-gray-800">
        {/* HEADER */}
        <header className="bg-white shadow-sm sticky top-0 z-50">
          <div className="max-w-6xl mx-auto px-4 py-4 flex justify-between items-center">
            {/* ✅ Logo link uses Next.js Link */}
            <Link href="/" className="flex items-center gap-3" passHref>
              <Image
                src="/EVBoise_Optimized.svg"
                alt="/EVBoise_Optimized copy.svg"
                width={140}
                height={40}
                priority
              />
            </Link>

            {/* Navigation Links */}
            <nav className="hidden sm:flex gap-6 text-sm">
              <Link
                href="/fleet"
                className="text-gray-700 hover:text-green-600 font-medium transition"
              >
                Fleet
              </Link>
              <Link
                href="/pricing"
                className="text-gray-700 hover:text-green-600 font-medium transition"
              >
                Pricing
              </Link>
              <Link
                href="/contact"
                className="text-gray-700 hover:text-green-600 font-medium transition"
              >
                Contact
              </Link>
            </nav>
          </div>
        </header>

        {/* MAIN CONTENT */}
        <main className="min-h-screen">{children}</main>

        {/* FOOTER */}
        <footer className="bg-white border-t mt-12">
          <div className="max-w-6xl mx-auto px-4 py-6 text-center text-sm text-gray-500">
            <p>
              © {new Date().getFullYear()} EV Boise — All rights reserved.
            </p>
            <p className="mt-1">
              {/* ✅ External link — allowed */}
              <a
                href="mailto:info@evboise.com"
                className="text-green-600 hover:underline"
              >
                info@evboise.com
              </a>
            </p>
          </div>
        </footer>
      </body>
    </html>
  );
}