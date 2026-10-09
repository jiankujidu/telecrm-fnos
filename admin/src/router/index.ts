import { createRouter, createWebHistory } from 'vue-router';
import Layout from '@/views/layout/index.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', name: 'Login', component: () => import('@/views/login/index.vue') },
    {
      path: '/',
      component: Layout,
      redirect: '/team',
      children: [
        { path: 'team', name: 'Team', component: () => import('@/views/team/index.vue'), meta: { title: '团队管理' } },
        { path: 'customer', name: 'Customer', component: () => import('@/views/customer/index.vue'), meta: { title: '客户管理' } },
        { path: 'task', name: 'Task', component: () => import('@/views/task/index.vue'), meta: { title: '任务管理' } },
        { path: 'records', name: 'Records', component: () => import('@/views/records/index.vue'), meta: { title: '通话记录' } },
        { path: 'package', name: 'Package', component: () => import('@/views/package/index.vue'), meta: { title: '套餐管理' } },
        { path: 'vipcode', name: 'VipCode', component: () => import('@/views/vipcode/index.vue'), meta: { title: '兑换码管理' } },
        { path: 'order', name: 'Order', component: () => import('@/views/order/index.vue'), meta: { title: '订单管理' } },
        { path: 'report', name: 'Report', component: () => import('@/views/report/index.vue'), meta: { title: '报表统计' } },
        { path: 'profile', name: 'Profile', component: () => import('@/views/profile/index.vue'), meta: { title: '客户画像' } },
        { path: 'dialpush', name: 'DialPush', component: () => import('@/views/dialpush/index.vue'), meta: { title: '云端自动外呼' } },
        { path: 'backup', name: 'Backup', component: () => import('@/views/backup/index.vue'), meta: { title: '数据备份与恢复' } },
      ],
    },
  ],
});

router.beforeEach((to) => {
  const token = localStorage.getItem('token');
  if (!token && to.path !== '/login') {
    return { path: '/login' };
  }
  if (token && to.path === '/login') {
    return { path: '/' };
  }
});

export default router;
