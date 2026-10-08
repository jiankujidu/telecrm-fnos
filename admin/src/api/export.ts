import axios from 'axios';

/**
 * 导出接口独立实例：不走统一拦截器（拦截器会把二进制响应当成 JSON 判错），
 * 只负责带 token 并以 blob 形式接收文件流。
 */
const raw = axios.create({ baseURL: '/api', timeout: 60000 });

raw.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

function saveFile(res: any, fallback: string) {
  const disposition: string = res.headers?.['content-disposition'] || '';
  let filename = fallback;
  const mStar = /filename\*=UTF-8''([^;]+)/.exec(disposition);
  const mPlain = /filename="([^"]+)"/.exec(disposition);
  if (mStar) filename = decodeURIComponent(mStar[1]);
  else if (mPlain) filename = decodeURIComponent(mPlain[1]);

  const url = window.URL.createObjectURL(new Blob([res.data]));
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  window.URL.revokeObjectURL(url);
  return filename;
}

export const exportApi = {
  /** 导出客户（跟随当前 tab 的权限范围与搜索关键词） */
  async customers(scope: string, keyword?: string) {
    const res = await raw.get('/export/customers', {
      params: { scope, keyword },
      responseType: 'blob',
    });
    return saveFile(res, '客户导出.xlsx');
  },

  /** 导出通话记录 */
  async callRecords(scope: string, result?: string) {
    const res = await raw.get('/export/call-records', {
      params: { scope, result },
      responseType: 'blob',
    });
    return saveFile(res, '通话记录导出.xlsx');
  },
};
