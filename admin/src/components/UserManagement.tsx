import React, { useEffect, useState } from 'react';
import { fetchUsers, suspendUser, type User } from '../api/adminApi';
import { Users as UsersIcon, ShieldAlert } from 'lucide-react';

export const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    const loadUsers = async () => {
      try {
        const data = await fetchUsers();
        setUsers(data);
      } catch (error) {
        console.error('Failed to load users', error);
      } finally {
        setLoading(false);
      }
    };
    loadUsers();
  }, []);

  const handleSuspend = async (userId: string) => {
    setActionLoading(userId);
    try {
      await suspendUser(userId);
      setUsers(users.map(u => u.id === userId ? { ...u, status: 'suspended' } : u));
    } catch (error) {
      console.error('Failed to suspend user', error);
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <section className="animate-fade-in delay-300">
      <h2 className="section-title">
        <UsersIcon size={24} color="var(--accent-primary)" />
        User Management
      </h2>
      <div className="table-container">
        <table>
          <thead>
            <tr>
              <th>User ID</th>
              <th>Username</th>
              <th>Email</th>
              <th>Joined Date</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <tr key={i}>
                  <td colSpan={6}>
                    <div className="skeleton skeleton-text"></div>
                  </td>
                </tr>
              ))
            ) : users.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-secondary)' }}>
                  No users found.
                </td>
              </tr>
            ) : (
              users.map(user => (
                <tr key={user.id}>
                  <td>
                    <span style={{ fontFamily: 'monospace', color: 'var(--text-secondary)' }}>
                      {user.id}
                    </span>
                  </td>
                  <td style={{ fontWeight: 500 }}>{user.username}</td>
                  <td>{user.email}</td>
                  <td>{user.joinedAt}</td>
                  <td>
                    <span className={`status-badge ${user.status === 'active' ? 'status-active' : 'status-suspended'}`}>
                      {user.status}
                    </span>
                  </td>
                  <td>
                    <button 
                      className="btn-suspend"
                      onClick={() => handleSuspend(user.id)}
                      disabled={user.status === 'suspended' || actionLoading === user.id}
                    >
                      <ShieldAlert size={16} />
                      {actionLoading === user.id ? 'Suspending...' : 'Suspend'}
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
};
