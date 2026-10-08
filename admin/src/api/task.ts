import request from './request';

export interface CallTaskRow {
  id: number;
  name: string;
  sourceType: string;
  status: string;
  totalCount: number;
  calledCount: number;
  validCount: number;
  createdAt: string;
}

export interface CallTaskItemRow {
  id: number;
  taskId: number;
  name: string;
  phone: string;
  company: string;
  address: string;
  remark: string;
  status: string;
  callResult: string;
  callCount: number;
  lastCallAt: string;
}

export const taskApi = {
  /** 文件导入生成任务 */
  importFile: (file: File, name?: string, sourceType = 'file') => {
    const form = new FormData();
    form.append('file', file);
    if (name) form.append('name', name);
    form.append('sourceType', sourceType);
    return request.post('/call-task/import', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
  /** 任务列表（分页） */
  list: (current = 1, size = 20) =>
    request.get('/call-task/list', { params: { current, size } }),
  /** 任务明细（分页） */
  items: (taskId: number, current = 1, size = 50) =>
    request.get(`/call-task/${taskId}/items`, { params: { current, size } }),
  /** 删除任务 */
  remove: (id: number) => request.delete(`/call-task/${id}`),
};
