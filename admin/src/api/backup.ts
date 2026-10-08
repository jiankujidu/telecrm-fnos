import axios from 'axios';
import { ElMessage } from 'element-plus';

/**
 * 备份文件下载不走统一的 JSON 拦截器（返回的是文件流）
 */
const raw = axios.create({ baseURL: '/api', timeout: 60000 });

raw.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

function saveFile(resp: any, fallback: string): string {
  const disp: string = resp.headers?.['content-disposition'] || '';
  let name = fallback;
  const star = /filename\*=UTF-8''([^;]+)/i.exec(disp);
  if (star) {
    name = decodeURIComponent(star[1]);
  } else {
    const plain = /filename="([^"]+)"/i.exec(disp);
    if (plain) name = plain[1];
  }
  const url = URL.createObjectURL(resp.data);
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  return name;
}

export const backupApi = {
  /** 导出全库备份 JSON */
  async export() {
    const resp = await raw.get('/backup/export', { responseType: 'blob' });
    return saveFile(resp, 'telecrm-backup.json');
  },
  /** 预览备份文件内容（不写库） */
  preview(file: File) {
    const fd = new FormData();
    fd.append('file', file);
    return raw.post('/backup/preview', fd).then((r) => r.data.data);
  },
  /** 恢复备份；mode = overwrite | append */
  restore(file: File, mode: 'overwrite' | 'append' = 'overwrite') {
    const fd = new FormData();
    fd.append('file', file);
    return raw
      .post(`/backup/import?mode=${mode}`, fd, { timeout: 300000 })
      .then((r) => {
        if (r.data?.code !== 0) {
          ElMessage.error(r.data?.message || '恢复失败');
          return Promise.reject(r.data);
        }
        return r.data.data;
      });
  },
};
