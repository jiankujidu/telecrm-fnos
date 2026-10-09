<template>
  <el-container class="layout">
    <el-aside width="200px" class="aside">
      <div class="logo">电销CRM</div>
      <el-menu :default-active="activeMenu" router background-color="#001529" text-color="#fff">
        <el-menu-item index="/team"><el-icon><User /></el-icon>团队管理</el-menu-item>
        <el-menu-item index="/customer"><el-icon><Phone /></el-icon>客户管理</el-menu-item>
        <el-menu-item index="/task"><el-icon><List /></el-icon>任务管理</el-menu-item>
        <el-menu-item index="/records"><el-icon><Tickets /></el-icon>通话记录</el-menu-item>
        <el-menu-item index="/package"><el-icon><Goods /></el-icon>套餐管理</el-menu-item>
        <el-menu-item index="/vipcode"><el-icon><Key /></el-icon>兑换码管理</el-menu-item>
        <el-menu-item index="/order"><el-icon><List /></el-icon>订单管理</el-menu-item>
        <el-menu-item index="/report"><el-icon><DataLine /></el-icon>报表统计</el-menu-item>
        <el-menu-item index="/profile"><el-icon><Postcard /></el-icon>客户画像</el-menu-item>
        <el-menu-item index="/dialpush"><el-icon><PhoneFilled /></el-icon>云端自动外呼</el-menu-item>
        <el-menu-item index="/backup"><el-icon><FolderOpened /></el-icon>数据备份</el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="header">
        <span>{{ title }}</span>
        <div class="user">
          <el-tag v-if="userStore.role" size="small">{{ roleText(userStore.role) }}</el-tag>
          <span class="nick">{{ userStore.nickname || '未登录' }}</span>
          <el-button text @click="logout">退出登录</el-button>
        </div>
      </el-header>
      <el-main><router-view /></el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router';
import { computed } from 'vue';
import { useUserStore } from '@/store/user';

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();

const activeMenu = computed(() => route.path);
const title = computed(() => (route.meta.title as string) || '');

function roleText(r: string) {
  return { owner: '团队主', admin: '管理员', group_leader: '组长', member: '坐席' }[r] || r;
}
function logout() {
  userStore.logout();
  router.push('/login');
}
</script>

<style scoped>
.layout { height: 100vh; }
.aside { background: #001529; }
.logo { color: #fff; text-align: center; line-height: 60px; font-size: 18px; font-weight: bold; }
.header { display: flex; align-items: center; justify-content: space-between; background: #fff; border-bottom: 1px solid #eee; }
.user { display: flex; align-items: center; gap: 10px; }
.nick { color: #333; }
</style>
