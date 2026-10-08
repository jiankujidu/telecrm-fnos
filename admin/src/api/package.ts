import request from './request';

export interface PackageRow {
  id: number;
  name: string;
  type: string; // vip / minutes
  price: number; // 分
  minutes: number;
  durationDays: number;
  status: number; // 0上架 1下架
}

export const packageApi = {
  list: (status?: number) => request.get('/package/list', { params: { status } }),
  add: (data: Partial<PackageRow>) => request.post('/package', data),
  update: (id: number, data: Partial<PackageRow>) => request.put(`/package/${id}`, data),
  remove: (id: number) => request.delete(`/package/${id}`),
};
