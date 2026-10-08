import request from './request';

export interface OrderRow {
  id: number;
  userId: number;
  teamId: number;
  packageId: number;
  amount: number; // 分
  status: number; // 0待支付 1已支付 2已取消
  payTime: string | null;
}

export const orderApi = {
  list: (status?: number, current = 1, size = 20) =>
    request.get('/order/list', { params: { status, current, size } }),
  create: (packageId: number) => request.post('/order', { packageId }),
  pay: (id: number) => request.post(`/order/${id}/pay`),
};
