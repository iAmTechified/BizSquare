import { useState, useEffect } from 'react';
import { NetworkOverview } from './components/NetworkOverview';
import { UserManagement } from './components/UserManagement';
import { ContentEngineDashboard } from './components/ContentEngineDashboard';
import { MatchingEngineDashboard } from './components/MatchingEngineDashboard';
import { SpotlightDashboard } from './components/SpotlightDashboard';
import { PointsLedger } from './components/PointsLedger';
import { LoginPage } from './components/LoginPage';
import { getToken, clearToken } from './api/adminApi';
import {
  Shield, Moon, Sun, Zap, Users, Sparkles,
  Star, Coins, LayoutDashboard, LogOut, Activity
} from 'lucide-react';
import './index.css';

// ─── Section Types ─────────────────────────────────────────────────────────

type Section = 'overview' | 'users' | 'matching' | 'content' | 'spotlight' | 'ledger';

interface NavItem {
  id: Section;
  label: string;
  icon: typeof Shield;
  badge?: string;
  badgeType?: 'default' | 'danger';
}

const NAV_GROUPS: { label: string; items: NavItem[] }[] = [
  {
    label: 'Analytics',
    items: [
      { id: 'overview', label: 'Network Overview', icon: LayoutDashboard },
    ],
  },
  {
    label: 'Engine',
    items: [
      { id: 'matching', label: 'Matching Engine', icon: Zap },
      { id: 'content', label: 'Interest & Content', icon: Sparkles },
    ],
  },
  {
    label: 'Users & Economy',
    items: [
      { id: 'users', label: 'User Management', icon: Users },
      { id: 'spotlight', label: 'Spotlight Economy', icon: Star },
      { id: 'ledger', label: 'Points Ledger', icon: Coins },
    ],
  },
];

// ─── Sidebar ──────────────────────────────────────────────────────────────

function Sidebar({
  current,
  onNavigate,
  onLogout,
}: {
  current: Section;
  onNavigate: (s: Section) => void;
  onLogout: () => void;
}) {
  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="sidebar-logo-icon">
          <Shield size={17} color="#fff" />
        </div>
        <span className="sidebar-logo-text">BizSquare</span>
        <span className="sidebar-logo-badge">Admin</span>
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        {NAV_GROUPS.map((group) => (
          <div className="sidebar-section" key={group.label} style={{ padding: '0.75rem 0 0.25rem' }}>
            <div className="sidebar-section-label">{group.label}</div>
            {group.items.map((item) => {
              const Icon = item.icon;
              return (
                <button
                  key={item.id}
                  className={`nav-item ${current === item.id ? 'active' : ''}`}
                  onClick={() => onNavigate(item.id)}
                >
                  <Icon size={15} />
                  {item.label}
                  {item.badge && (
                    <span className={`nav-item-badge ${item.badgeType === 'danger' ? 'danger' : ''}`}>
                      {item.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className="sidebar-footer">
        <div className="sidebar-user">
          <div className="sidebar-avatar">AD</div>
          <div className="sidebar-user-info">
            <div className="sidebar-user-name">Super Admin</div>
            <div className="sidebar-user-role">Full Access</div>
          </div>
          <button
            onClick={onLogout}
            title="Sign out"
            style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--text-tertiary)', display: 'flex', alignItems: 'center', padding: 4 }}
          >
            <LogOut size={14} />
          </button>
        </div>
      </div>
    </aside>
  );
}

// ─── Top Bar ──────────────────────────────────────────────────────────────

const SECTION_TITLES: Record<Section, { label: string; desc: string }> = {
  overview: { label: 'Network Overview', desc: 'Real-time health of the Akawo network' },
  matching: { label: 'Matching Engine', desc: 'Weekly contact-gain cycles & explainability' },
  content: { label: 'Interest & Content', desc: 'Scenario cards, taxonomy, and content bank' },
  users: { label: 'User Management', desc: 'Manage accounts, suspend users, adjust points' },
  spotlight: { label: 'Spotlight Economy', desc: 'Daily campaigns, participants & point rewards' },
  ledger: { label: 'Points Ledger', desc: 'Full audit log of all Akawo Points transactions' },
};

function Topbar({
  section,
  theme,
  onToggleTheme,
}: {
  section: Section;
  theme: string;
  onToggleTheme: () => void;
}) {
  const { label, desc } = SECTION_TITLES[section];

  return (
    <header className="topbar">
      <div className="topbar-breadcrumb">
        <span className="topbar-breadcrumb-root">Admin</span>
        <span className="topbar-breadcrumb-sep">/</span>
        <span className="topbar-breadcrumb-current">{label}</span>
      </div>

      <div className="topbar-actions">
        {/* Live indicator */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6,
          fontSize: 12, fontWeight: 600, color: 'var(--success)',
          background: 'var(--success-dim)', padding: '4px 10px',
          borderRadius: 99,
        }}>
          <Activity size={11} />
          Live
        </div>

        <button className="topbar-btn" onClick={onToggleTheme} title="Toggle theme">
          {theme === 'light' ? <Moon size={16} /> : <Sun size={16} />}
        </button>
      </div>
    </header>
  );
}

// ─── Page Content Renderer ────────────────────────────────────────────────

function PageContent({ section }: { section: Section }) {
  switch (section) {
    case 'overview':
      return (
        <>
          <div className="page-header fade-up">
            <div className="page-header-left">
              <h1 className="page-title">Network Overview</h1>
              <p className="page-subtitle">Real-time snapshot of the Akawo network health.</p>
            </div>
          </div>
          <NetworkOverview />
        </>
      );

    case 'users':
      return (
        <>
          <div className="page-header fade-up">
            <div className="page-header-left">
              <h1 className="page-title">User Management</h1>
              <p className="page-subtitle">View all users, manage status, and adjust Akawo Points.</p>
            </div>
          </div>
          <UserManagement />
        </>
      );

    case 'matching':
      return <MatchingEngineDashboard />;

    case 'content':
      return <ContentEngineDashboard />;

    case 'spotlight':
      return <SpotlightDashboard />;

    case 'ledger':
      return <PointsLedger />;

    default:
      return null;
  }
}

// ─── App Root ─────────────────────────────────────────────────────────────

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(() => !!getToken());
  const [section, setSection] = useState<Section>('overview');
  const [theme, setTheme] = useState(() =>
    localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
  );

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const handleLogout = () => {
    clearToken();
    setIsAuthenticated(false);
  };

  if (!isAuthenticated) {
    return <LoginPage onLogin={() => setIsAuthenticated(true)} />;
  }

  return (
    <div className="app-shell">
      <Sidebar
        current={section}
        onNavigate={setSection}
        onLogout={handleLogout}
      />

      <div className="main-wrapper">
        <Topbar
          section={section}
          theme={theme}
          onToggleTheme={() => setTheme(t => t === 'light' ? 'dark' : 'light')}
        />

        <main className="page-content" key={section}>
          <PageContent section={section} />
        </main>
      </div>
    </div>
  );
}

export default App;
