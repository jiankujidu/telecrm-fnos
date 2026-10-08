import request from './request';

export type RecordScope = 'mine' | 'team';

export interface CallRecordRow {
  id: number;
  phone: string;
  duration: number;
  result: string;
  recordingUrl: string;
  remark: string;
  tag: string;
  calledAt: string;
}

export const recordsApi = {
  list: (scope: RecordScope, result: string, current = 1, size = 20) =>
    request.get('/call-record/list', { params: { scope, result, current, size } }),
  // 上传录音文件，返回访问 URL
  upload: (file: File) => {
    const form = new FormData();
    form.append('file', file);
    return request.post('/file/upload', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
  // 关联录音到通话记录
  attachRecording: (id: number, recordingUrl: string) =>
    request.post(`/call-record/${id}/recording`, { recordingUrl }),
  // 某客户的通话记录（客户详情抽屉用）
  byCustomer: (customerId: number) =>
    request.get('/call-record/by-customer', { params: { customerId } }),
};
