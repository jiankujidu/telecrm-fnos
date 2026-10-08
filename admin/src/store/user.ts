import { defineStore } from 'pinia';

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    nickname: localStorage.getItem('nickname') || '',
    role: localStorage.getItem('role') || '',
    userId: localStorage.getItem('userId') || '',
  }),
  actions: {
    setToken(token: string) {
      this.token = token;
      localStorage.setItem('token', token);
    },
    setUser(user: { nickname?: string; role?: string; id?: number | string }) {
      if (user.nickname) {
        this.nickname = user.nickname;
        localStorage.setItem('nickname', user.nickname);
      }
      if (user.role) {
        this.role = user.role;
        localStorage.setItem('role', user.role);
      }
      if (user.id !== undefined) {
        this.userId = String(user.id);
        localStorage.setItem('userId', String(user.id));
      }
    },
    logout() {
      this.token = '';
      this.nickname = '';
      this.role = '';
      this.userId = '';
      localStorage.removeItem('token');
      localStorage.removeItem('nickname');
      localStorage.removeItem('role');
      localStorage.removeItem('userId');
    },
  },
});
