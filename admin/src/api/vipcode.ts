import request from './request';

export interface VipCodeRow {
  id: number;
  code: string;
  packageId: number;
  usedBy: number | null;
  usedAt: string | null;
  status: number; // 0未使用 1已使用
}

export const vipCodeApi = {
  list: (status?: number, current = 1, size = 20) =>
    request.get('/vip-code/list', { params: { status, current, size } }),
  generate: (packageId: number, count: number) =>
    request.post('/vip-code/generate', { packageId, count }),
  remove: (id: number) => request.delete(`/vip-code/${id}`),
};
