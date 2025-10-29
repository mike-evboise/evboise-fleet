import Image from "next/image";

export default function Header() {
  return (
    <header className="flex items-center justify-between p-4 bg-white shadow-sm">
      {/* EVBoise Logo */}
      <Image
        src="/EVBoise_Optimized.svg"
        alt="EVBoise Logo"
        width={180}
        height={60}
        priority
      />

      {/* Navigation */}
      <nav className="flex gap-6 text-gray-700 font-medium">
        <a href="/repair" className="hover:text-evboise-green">Repair Rentals</a>
        <a href="/fleet" className="hover:text-evboise-green">Fleet</a>
        <a href="/contact" className="hover:text-evboise-green">Contact</a>
      </nav>
    </header>
  );
}
