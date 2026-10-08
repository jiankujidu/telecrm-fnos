import request from './request';

export interface FollowUpRow {
  id: number;
  customerId: number | null;
  customerName: string;
  phone: string;
  content: string;
  tag: string;
  createdAt: string;
}

export const followupApi = {
  // 列表：传 customerId 查该客户，否则查本人全部回访
  list: (customerId?: number) =>
    request.get('/follow-up/list', { params: customerId ? { customerId } : {} }),
  add: (customerId: number, content: string, tag?: string) =>
    request.post('/follow-up/add', { customerId, content, tag }),
  remove: (id: number) => request.delete(`/follow-up/${id}`),
};
