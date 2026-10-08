import request from './request';

export interface TeamMemberVO {
  userId: number;
  nickname: string;
  role: string;
  phone: string;
}

export const teamApi = {
  list: () => request.get('/team/members'),
  add: (phone: string, nickname: string, role = 'member') =>
    request.post('/team/member', { phone, nickname, role }),
  remove: (userId: number) => request.delete(`/team/member/${userId}`),
};
