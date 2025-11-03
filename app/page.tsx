// app/page.tsx

export const metadata = {
  title: "EV Boise",
  description: "Tesla rentals and EV services in Boise, Idaho",
};

export default function HomePage() {
  return (
    <main className="p-4 text-center">
      <h1 className="text-3xl font-bold">Welcome to EVBoise</h1>
      <p className="text-gray-700 mt-2">Tesla rentals and EV services in Boise, Idaho.</p>
    </main>
  );
}
