import { Link, Outlet } from 'react-router-dom';
import { Button } from '@/components/ui/button';

const Layout = () => {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
        <div className="container flex h-16 items-center justify-between">
          <div className="flex items-center gap-6 md:gap-10">
            <Link to="/" className="flex items-center space-x-2">
              <span className="inline-block font-bold text-xl">CIH App</span>
            </Link>
            <nav className="flex gap-6">
              <Link
                to="/"
                className="flex items-center text-sm font-medium text-muted-foreground hover:text-primary"
              >
                Home
              </Link>
              <Link
                to="/about"
                className="flex items-center text-sm font-medium text-muted-foreground hover:text-primary"
              >
                About
              </Link>
            </nav>
          </div>
          <div className="flex items-center gap-4">
            <Button size="sm">Get Started</Button>
          </div>
        </div>
      </header>

      <main className="flex-1">
        <div className="container py-6">
          <Outlet />
        </div>
      </main>
      <footer className="border-t py-6 md:px-8 md:py-0">
        <div className="container flex flex-col items-center justify-between gap-4 md:h-24 md:flex-row">
          <p className="text-balance text-center text-sm leading-loose text-muted-foreground md:text-left">
            Built by Your Team. The source code is available on{" "}
            <a
              href="#"
              target="_blank"
              rel="noreferrer"
              className="font-medium underline underline-offset-4"
            >
              GitHub
            </a>
            .
          </p>
        </div>
      </footer>
    </div>
  );
};

export default Layout;
