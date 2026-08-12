import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { adminAuthApi, AdminUser, getAdminToken, clearAdminToken, ApiError } from '../api/adminAuthApi';

export type AuthStatus = 'INITIALIZING' | 'AUTHENTICATED' | 'UNAUTHENTICATED' | 'ACCESS_DENIED' | 'NETWORK_ERROR';

interface AdminAuthContextType {
  adminUser: AdminUser | null;
  status: AuthStatus;
  isLoading: boolean;
  error: string | null;
  permissions: string[];
  login: (phone_number: string, access_code?: string) => Promise<void>;
  logout: () => Promise<void>;
  verifySession: () => Promise<void>;
  hasPermission: (permission: string) => boolean;
}

const AdminAuthContext = createContext<AdminAuthContextType | undefined>(undefined);

export const AdminAuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [status, setStatus] = useState<AuthStatus>('INITIALIZING');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const verifySession = useCallback(async () => {
    const token = getAdminToken();
    if (!token) {
      setAdminUser(null);
      setStatus('UNAUTHENTICATED');
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);
    try {
      const res = await adminAuthApi.verifySession();
      setAdminUser(res.user);
      setStatus('AUTHENTICATED');
    } catch (err: any) {
      console.warn('Session verification failed:', err);
      if (err instanceof ApiError) {
        if (err.status === 401) {
          clearAdminToken();
          setAdminUser(null);
          setStatus('UNAUTHENTICATED');
          setError('Session expired. Please sign in again.');
        } else if (err.status === 403) {
          setStatus('ACCESS_DENIED');
          setError(err.message || 'Access Denied. Account lacks administrative privileges.');
        } else {
          setStatus('NETWORK_ERROR');
          setError(err.message || 'Server error during authentication check.');
        }
      } else {
        setStatus('NETWORK_ERROR');
        setError('Network connectivity issue. Failed to connect to server.');
      }
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    verifySession();
  }, [verifySession]);

  const login = async (phone_number: string, access_code?: string) => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await adminAuthApi.login(phone_number, access_code);
      setAdminUser(res.user);
      setStatus('AUTHENTICATED');
    } catch (err: any) {
      if (err instanceof ApiError) {
        if (err.status === 403) {
          setStatus('ACCESS_DENIED');
          setError(err.message || 'Access Denied. User does not have administrative access.');
        } else {
          setStatus('UNAUTHENTICATED');
          setError(err.message || 'Authentication failed.');
        }
      } else {
        setError(err.message || 'Login failed.');
      }
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    setIsLoading(true);
    try {
      await adminAuthApi.logout();
    } catch (err) {
      console.warn('Logout API warning:', err);
    } finally {
      clearAdminToken();
      setAdminUser(null);
      setStatus('UNAUTHENTICATED');
      setError(null);
      setIsLoading(false);
    }
  };

  const hasPermission = useCallback(
    (permission: string): boolean => {
      if (!adminUser) return false;
      const userPermissions = adminUser.permissions || [];
      return userPermissions.includes('*') || userPermissions.includes(permission);
    },
    [adminUser]
  );

  return (
    <AdminAuthContext.Provider
      value={{
        adminUser,
        status,
        isLoading,
        error,
        permissions: adminUser?.permissions || [],
        login,
        logout,
        verifySession,
        hasPermission,
      }}
    >
      {children}
    </AdminAuthContext.Provider>
  );
};

export const useAdminAuth = (): AdminAuthContextType => {
  const context = useContext(AdminAuthContext);
  if (!context) {
    throw new Error('useAdminAuth must be used within an AdminAuthProvider');
  }
  return context;
};
