import { Button } from "@/components/ui/button";

const Home = () => {
  return (
    <div className="flex flex-col items-center gap-8 py-12 md:py-24">
      <div className="flex flex-col items-center gap-4 text-center">
        <h1 className="text-4xl font-extrabold tracking-tight lg:text-5xl">
          Welcome to CIH App
        </h1>
        <p className="max-w-[700px] text-lg text-muted-foreground">
          A production-ready full-stack starter template built with React, Tailwind CSS, Shadcn UI, and Express.
        </p>
      </div>
      <div className="flex gap-4">
        <Button size="lg">Documentation</Button>
        <Button variant="outline" size="lg">GitHub</Button>
      </div>


      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-16 w-full">
        {[
          {
            title: "Fast Development",
            description: "Built with Vite for lightning-fast HMR and optimized builds."
          },
          {
            title: "Beautiful UI",
            description: "Integrated with Tailwind CSS and Shadcn UI for stunning designs."
          },
          {
            title: "Scalable Backend",
            description: "Express backend with a clean architecture ready for production."
          }
        ].map((feature, i) => (
          <div key={i} className="rounded-xl border bg-card text-card-foreground shadow p-6">
            <h3 className="font-semibold text-xl mb-2">{feature.title}</h3>
            <p className="text-muted-foreground">{feature.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Home;
