import request from './request';

export const authApi = {
  login: (phone: string, password: string) =>
    request.post('/auth/login', { phone, password }),
  logout: () => request.post('/auth/logout'),
};
