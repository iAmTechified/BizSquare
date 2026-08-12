import { useState, useEffect } from 'react';
import { NetworkOverview } from './components/NetworkOverview';
import { UserManagement } from './components/UserManagement';
import { ContentEngineDashboard } from './components/ContentEngineDashboard';
import { MatchingEngineDashboard } from './components/MatchingEngineDashboard';
import { Shield, Moon, Sun, Sparkles, Users, Zap } from 'lucide-react';
import './index.css';

function App() {
  const [theme, setTheme] = useState(() => {
    return localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
  });

  const [currentSection, setCurrentSection] = useState<'network' | 'content' | 'matching'>('matching');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  return (
    <div className="dashboard-container">
      <header className="header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '2rem' }}>
          <div className="header-title">
            <Shield size={28} color="#0058FF" />
            BizSquare Admin
          </div>

          <nav style={{ display: 'flex', gap: '0.6rem' }}>
            <button
              onClick={() => setCurrentSection('matching')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                padding: '0.5rem 1rem',
                borderRadius: '8px',
                border: 'none',
                cursor: 'pointer',
                fontWeight: 700,
                fontSize: '13px',
                background: currentSection === 'matching' ? 'rgba(0, 88, 255, 0.15)' : 'transparent',
                color: currentSection === 'matching' ? '#0058FF' : 'var(--text-secondary)',
              }}
            >
              <Zap size={16} /> Matching Engine
            </button>
            <button
              onClick={() => setCurrentSection('network')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                padding: '0.5rem 1rem',
                borderRadius: '8px',
                border: 'none',
                cursor: 'pointer',
                fontWeight: 700,
                fontSize: '13px',
                background: currentSection === 'network' ? 'rgba(0, 88, 255, 0.15)' : 'transparent',
                color: currentSection === 'network' ? '#0058FF' : 'var(--text-secondary)',
              }}
            >
              <Users size={16} /> Network & Users
            </button>
            <button
              onClick={() => setCurrentSection('content')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                padding: '0.5rem 1rem',
                borderRadius: '8px',
                border: 'none',
                cursor: 'pointer',
                fontWeight: 700,
                fontSize: '13px',
                background: currentSection === 'content' ? 'rgba(0, 88, 255, 0.15)' : 'transparent',
                color: currentSection === 'content' ? '#0058FF' : 'var(--text-secondary)',
              }}
            >
              <Sparkles size={16} /> Interest & Content Engine
            </button>
          </nav>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <button 
            onClick={toggleTheme}
            style={{
              background: 'transparent',
              border: '1px solid var(--border-color)',
              color: 'var(--text-primary)',
              borderRadius: '0.5rem',
              padding: '0.5rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}
          >
            {theme === 'light' ? <Moon size={20} /> : <Sun size={20} />}
          </button>
          <div style={{
            width: '36px',
            height: '36px',
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #0058FF, #5AFF00)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            fontSize: '14px',
            color: '#FFFFFF',
            boxShadow: '0 0 10px rgba(0, 88, 255, 0.5)'
          }}>
            AD
          </div>
        </div>
      </header>
      
      <main className="main-content">
        {currentSection === 'matching' ? (
          <MatchingEngineDashboard />
        ) : currentSection === 'network' ? (
          <>
            <NetworkOverview />
            <UserManagement />
          </>
        ) : (
          <ContentEngineDashboard />
        )}
      </main>
    </div>
  );
}

export default App;
