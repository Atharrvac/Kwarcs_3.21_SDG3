const About = () => {
  return (
    <div className="flex flex-col gap-8 py-12 md:py-24">
      <div className="flex flex-col gap-4">
        <h1 className="text-4xl font-extrabold tracking-tight lg:text-5xl">
          About the Project
        </h1>
        <p className="max-w-[800px] text-lg text-muted-foreground">
          This project was designed by a senior developer to provide a solid foundation for building modern web applications.
        </p>
      </div>

      <div className="prose prose-slate dark:prose-invert max-w-none">
        <h2 className="text-2xl font-bold mt-8 mb-4">Our Mission</h2>
        <p className="text-muted-foreground mb-6">
          To simplify the full-stack development process by providing a pre-configured, batteries-included starter kit that follows all best practices in safety, scalability, and performance.
        </p>

        <h2 className="text-2xl font-bold mt-8 mb-4">Tech Stack</h2>
        <ul className="list-disc pl-6 space-y-2 text-muted-foreground">
          <li><strong>Frontend:</strong> React 19, React Router, Tailwind CSS, Shadcn UI</li>
          <li><strong>Backend:</strong> Express.js, Helmet, Morgan, Axios</li>
          <li><strong>Tools:</strong> Vite, ESLint, Prettier, Husky, Vitest</li>
          <li><strong>Standards:</strong> Semantic HTML, SEO Optimization, Dynamic Design</li>
        </ul>
      </div>
    </div>
  );
};

export default About;
