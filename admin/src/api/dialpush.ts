import request from './request';

export interface DialPushTask {
  id: number;
  teamId: number;
  userId: number;
  targetUserId: number | null;
  name: string;
  scope: string;
  keyword: string;
  startCustomerId: number | null;
  intervalSeconds: number;
  status: 'pending' | 'running' | 'paused' | 'finished' | 'cancelled';
  totalCount: number;
  dialedCount: number;
  connectedCount: number;
  currentItemId: number | null;
  startedAt: string | null;
  finishedAt: string | null;
  createdAt: string;
}

export interface DialPushItem {
  id: number;
  taskId: number;
  seq: number;
  customerId: number | null;
  name: string;
  phone: string;
  company: string;
  status: 'pending' | 'dialing' | 'dialed' | 'skipped' | 'failed';
  result: string;
  duration: number;
  remark: string;
  executorId: number | null;
  finishedAt: string | null;
}

export interface DialProgress {
  id: number;
  name: string;
  status: string;
  total: number;
  dialed: number;
  connected: number;
  intervalSeconds: number;
  startedAt: string | null;
  finishedAt: string | null;
  current?: {
    itemId: number;
    customerId: number | null;
    name: string;
    phone: string;
    company: string;
    status: string;
    result: string;
    seq: number;
  } | null;
}

export const dialPushApi = {
  create: (data: {
    scope?: string;
    keyword?: string;
    name?: string;
    startCustomerId?: number | null;
    limit?: number;
    intervalSeconds?: number;
    targetUserId?: number | null;
  }) => request.post('/dial-push/create', data),

  list: () => request.get('/dial-push/list') as Promise<DialPushTask[]>,

  detail: (id: number) => request.get(`/dial-push/${id}`) as Promise<DialPushTask>,

  progress: (id: number) => request.get(`/dial-push/${id}/progress`) as Promise<DialProgress>,

  items: (id: number) => request.get(`/dial-push/${id}/items`) as Promise<DialPushItem[]>,

  control: (id: number, action: 'start' | 'pause' | 'resume' | 'stop' | 'cancel') =>
    request.post(`/dial-push/${id}/control`, { action }),

  skip: (id: number, itemId: number) => request.post(`/dial-push/${id}/skip`, { itemId }),

  remove: (id: number) => request.delete(`/dial-push/${id}`),
};

export const STATUS_TEXT: Record<string, string> = {
  pending: '待开始',
  running: '进行中',
  paused: '已暂停',
  finished: '已完成',
  cancelled: '已取消',
};

export const STATUS_TYPE: Record<string, string> = {
  pending: 'info',
  running: 'success',
  paused: 'warning',
  finished: '',
  cancelled: 'danger',
};

export const ITEM_STATUS_TEXT: Record<string, string> = {
  pending: '待拨打',
  dialing: '拨打中',
  dialed: '已拨打',
  skipped: '已跳过',
  failed: '失败',
};

export const RESULT_TEXT: Record<string, string> = {
  connected: '已接通',
  no_answer: '未接听',
  refused: '拒接/挂断',
  shutdown: '关机/停机',
  empty: '空号',
  add_customer: '已加客户',
};
