import axios from 'axios';
import { ElMessage } from 'element-plus';

const request = axios.create({
  baseURL: '/api',
  timeout: 15000,
});

request.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

request.interceptors.response.use(
  (resp) => {
    const body = resp.data;
    if (body.code !== 0) {
      ElMessage.error(body.message || '请求失败');
      return Promise.reject(body);
    }
    return body.data;
  },
  (err) => {
    ElMessage.error(err.message || '网络错误');
    return Promise.reject(err);
  },
);

export default request;
