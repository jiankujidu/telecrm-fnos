import request from './request';

export type CustomerScope = 'mine' | 'team' | 'public';

export interface CustomerRow {
  id: number;
  name: string;
  phone: string;
  company: string;
  address: string;
  remark: string;
  source: string;
  status: string;
  tags: string;
  ownerUserId: number | null;
}

/** 客户画像（打电话时整理的客户详细信息） */
export interface CustomerProfile {
  id?: number;
  customerId?: number;
  gender: string;
  age: number | null;
  birthday: string;
  industry: string;
  position: string;
  wechat: string;
  email: string;
  secondPhone: string;
  province: string;
  city: string;
  intentLevel: string;
  budget: string;
  isDecision: number;
  channel: string;
  productInterest: string;
  painPoint: string;
  competitor: string;
  nextFollowAt: string | null;
  callCount?: number;
  lastCalledAt?: string | null;
  profileTags: string;
  summary: string;
}

export const emptyProfile = (): CustomerProfile => ({
  gender: '',
  age: null,
  birthday: '',
  industry: '',
  position: '',
  wechat: '',
  email: '',
  secondPhone: '',
  province: '',
  city: '',
  intentLevel: '',
  budget: '',
  isDecision: 0,
  channel: '',
  productInterest: '',
  painPoint: '',
  competitor: '',
  nextFollowAt: null,
  profileTags: '',
  summary: '',
});

export const customerApi = {
  list: (scope: CustomerScope, keyword: string, current = 1, size = 20) =>
    request.get('/customer/list', { params: { scope, keyword, current, size } }),
  transfer: (customerId: number, toUserId: number) =>
    request.post('/customer/transfer', { customerId, toUserId }),
  assign: (customerId: number, toUserId: number) =>
    request.post('/customer/assign', { customerId, toUserId }),
  abandon: (customerId: number) => request.post('/customer/abandon', { customerId }),
  detail: (id: number) => request.get(`/customer/${id}`),

  // ---- 新增 / 编辑 / 删除 ----
  create: (data: Partial<CustomerRow>) => request.post('/customer/create', data),
  update: (data: Partial<CustomerRow> & { id: number }) => request.post('/customer/update', data),
  remove: (id: number) => request.post('/customer/delete', { id }),
  removeBatch: (ids: number[]) => request.post('/customer/delete', { ids }),

  // ---- 画像 ----
  getProfile: (id: number) => request.get(`/customer/${id}/profile`),
  saveProfile: (id: number, data: Partial<CustomerProfile>) =>
    request.post(`/customer/${id}/profile`, data),
  profiles: (ids: number[]) =>
    request.get('/customer/profiles', { params: { ids: ids.join(',') } }),
  /** 画像表：客户 + 画像联表分页 */
  profileList: (scope: CustomerScope, keyword: string, intentLevel: string, current = 1, size = 20) =>
    request.get('/customer/profile/list', {
      params: { scope, keyword, intentLevel, current, size },
    }),
};
