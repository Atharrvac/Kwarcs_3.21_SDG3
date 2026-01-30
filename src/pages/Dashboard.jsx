import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";

const Dashboard = () => {
  const stats = [
    { name: 'Total Users', value: '2,543', change: '+12.5%', type: 'increase' },
    { name: 'Active Sessions', value: '432', change: '+18.2%', type: 'increase' },
    { name: 'Revenue', value: '$12,402', change: '-3.2%', type: 'decrease' },
    { name: 'Conversion Rate', value: '4.8%', change: '+2.4%', type: 'increase' },
  ];

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">Welcome back to your dashboard summary.</p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <div key={stat.name} className="p-6 rounded-xl border bg-card text-card-foreground shadow">
            <p className="text-sm font-medium text-muted-foreground">{stat.name}</p>
            <div className="flex items-baseline justify-between mt-2">
              <h2 className="text-2xl font-bold">{stat.value}</h2>
              <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                stat.type === 'increase' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {stat.change}
              </span>
            </div>
          </div>
        ))}
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <div className="md:col-span-4 p-6 rounded-xl border bg-card text-card-foreground shadow">
          <h3 className="text-lg font-semibold mb-4">Recent Activity</h3>
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="flex items-center gap-4">
                <div className="w-9 h-9 rounded-full bg-muted flex items-center justify-center font-bold text-sm">
                  JD
                </div>
                <div className="flex-1 space-y-1">
                  <p className="text-sm font-medium leading-none">User #{i} connected</p>
                  <p className="text-xs text-muted-foreground">2 minutes ago</p>
                </div>
                <Button variant="ghost" size="sm">View</Button>
              </div>
            ))}
          </div>
        </div>

        <div className="md:col-span-3 p-6 rounded-xl border bg-card text-card-foreground shadow">
          <h3 className="text-lg font-semibold mb-4">Quick Actions</h3>
          <div className="grid gap-2">
            <Button className="w-full justify-start text-left font-normal" variant="outline">
              Create New Project
            </Button>
            <Button className="w-full justify-start text-left font-normal" variant="outline">
              Invite Team Member
            </Button>
            <Button className="w-full justify-start text-left font-normal" variant="outline">
              Generate Report
            </Button>
            <Button className="w-full justify-start text-left font-normal" variant="outline">
              System Settings
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
