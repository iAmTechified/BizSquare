export interface NetworkStats {
  activeUsers: number;
  totalMatches: number;
  pointsInCirculation: number;
}

export interface User {
  id: string;
  username: string;
  email: string;
  status: 'active' | 'suspended';
  joinedAt: string;
}

export const fetchNetworkStats = async (): Promise<NetworkStats> => {
  // In a real app, this would hit http://localhost:8080/api/v1/admin/analytics/network
  // Mock implementation for now
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        activeUsers: 14285,
        totalMatches: 89340,
        pointsInCirculation: 1250000,
      });
    }, 500);
  });
};

export const fetchUsers = async (): Promise<User[]> => {
  // In a real app, this would hit http://localhost:8080/api/v1/admin/users
  // Mock implementation for now
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve([
        { id: 'usr_1', username: 'john_doe', email: 'john@example.com', status: 'active', joinedAt: '2026-01-15' },
        { id: 'usr_2', username: 'jane_smith', email: 'jane@example.com', status: 'active', joinedAt: '2026-02-20' },
        { id: 'usr_3', username: 'hacker_boy', email: 'hax0r@example.com', status: 'suspended', joinedAt: '2026-03-01' },
        { id: 'usr_4', username: 'alice_wonder', email: 'alice@example.com', status: 'active', joinedAt: '2026-04-10' },
        { id: 'usr_5', username: 'bob_builder', email: 'bob@example.com', status: 'active', joinedAt: '2026-05-05' },
      ]);
    }, 500);
  });
};

export const suspendUser = async (_userId: string): Promise<boolean> => {
  // Mock implementation of suspend action
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(true);
    }, 300);
  });
};
