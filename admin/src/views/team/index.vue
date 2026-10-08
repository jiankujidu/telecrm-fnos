<template>
  <div>
    <div class="toolbar">
      <el-button type="primary" @click="openAdd">添加成员</el-button>
    </div>
    <el-table :data="members" border v-loading="loading">
      <el-table-column prop="nickname" label="昵称" />
      <el-table-column prop="phone" label="账号(手机号)" />
      <el-table-column prop="role" label="角色">
        <template #default="{ row }">
          <el-tag>{{ roleText(row.role) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200">
        <template #default="{ row }">
          <el-button link type="danger" @click="onRemove(row)">踢出</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialog" title="添加成员" width="420px">
      <el-form :model="form" label-width="70px">
        <el-form-item label="手机号"><el-input v-model="form.phone" placeholder="已注册用户的手机号" /></el-form-item>
        <el-form-item label="昵称"><el-input v-model="form.nickname" placeholder="团队内昵称" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="form.role">
            <el-option label="管理员" value="admin" />
            <el-option label="组长" value="group_leader" />
            <el-option label="坐席" value="member" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialog = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="onAdd">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';
import { teamApi, type TeamMemberVO } from '@/api/team';
import { ElMessage, ElMessageBox } from 'element-plus';

const members = ref<TeamMemberVO[]>([]);
const loading = ref(false);
const dialog = ref(false);
const saving = ref(false);
const form = reactive({ phone: '', nickname: '', role: 'member' });

function roleText(r: string) {
  return { owner: '团队主', admin: '管理员', group_leader: '组长', member: '坐席' }[r] || r;
}

async function load() {
  loading.value = true;
  try {
    members.value = await teamApi.list();
  } finally {
    loading.value = false;
  }
}

function openAdd() {
  form.phone = '';
  form.nickname = '';
  form.role = 'member';
  dialog.value = true;
}

async function onAdd() {
  if (!form.phone) return ElMessage.warning('请输入手机号');
  saving.value = true;
  try {
    await teamApi.add(form.phone, form.nickname, form.role);
    ElMessage.success('已添加');
    dialog.value = false;
    await load();
  } finally {
    saving.value = false;
  }
}

async function onRemove(row: TeamMemberVO) {
  await ElMessageBox.confirm(`确认将「${row.nickname}」移出团队？`, '提示', { type: 'warning' });
  await teamApi.remove(row.userId);
  ElMessage.success('已移出');
  await load();
}

onMounted(load);
</script>

<style scoped>
.toolbar { margin-bottom: 12px; }
</style>
