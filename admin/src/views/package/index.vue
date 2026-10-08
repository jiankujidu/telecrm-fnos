<template>
  <div>
    <div class="toolbar">
      <el-radio-group v-model="statusFilter" @change="load">
        <el-radio-button :value="''">全部</el-radio-button>
        <el-radio-button :value="0">已上架</el-radio-button>
        <el-radio-button :value="1">已下架</el-radio-button>
      </el-radio-group>
      <el-button type="primary" @click="openAdd">新增套餐</el-button>
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="90" />
      <el-table-column prop="name" label="套餐名称" />
      <el-table-column prop="type" label="类型" width="110">
        <template #default="{ row }">{{ row.type === 'vip' ? 'VIP会员' : '通话分钟' }}</template>
      </el-table-column>
      <el-table-column prop="price" label="价格" width="110">
        <template #default="{ row }">¥{{ (row.price / 100).toFixed(2) }}</template>
      </el-table-column>
      <el-table-column prop="minutes" label="分钟数" width="90" />
      <el-table-column prop="durationDays" label="有效天数" width="100" />
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="row.status === 0 ? 'success' : 'info'">{{ row.status === 0 ? '已上架' : '已下架' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="150">
        <template #default="{ row }">
          <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
          <el-button link type="danger" @click="onDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialog" :title="form.id ? '编辑套餐' : '新增套餐'" width="480px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="form.type" style="width: 100%">
            <el-option label="VIP会员" value="vip" />
            <el-option label="通话分钟" value="minutes" />
          </el-select>
        </el-form-item>
        <el-form-item label="价格(元)"><el-input-number v-model="priceYuan" :min="0" :precision="2" :step="10" style="width: 100%" /></el-form-item>
        <el-form-item label="分钟数"><el-input-number v-model="form.minutes" :min="0" style="width: 100%" /></el-form-item>
        <el-form-item label="有效天数"><el-input-number v-model="form.durationDays" :min="1" style="width: 100%" /></el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="0">上架</el-radio>
            <el-radio :value="1">下架</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialog = false">取消</el-button>
        <el-button type="primary" @click="onSubmit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { packageApi, type PackageRow } from '@/api/package';

const rows = ref<PackageRow[]>([]);
const loading = ref(false);
const statusFilter = ref<number | ''>('');
const dialog = ref(false);
const priceYuan = ref(0);
const form = reactive<Partial<PackageRow>>({ name: '', type: 'vip', minutes: 0, durationDays: 30, status: 0 });

async function load() {
  loading.value = true;
  try {
    const res: any = await packageApi.list(statusFilter.value === '' ? undefined : statusFilter.value);
    rows.value = res || [];
  } finally {
    loading.value = false;
  }
}
function openAdd() {
  Object.assign(form, { id: undefined, name: '', type: 'vip', minutes: 0, durationDays: 30, status: 0 });
  priceYuan.value = 0;
  dialog.value = true;
}
function openEdit(row: PackageRow) {
  Object.assign(form, { ...row });
  priceYuan.value = row.price / 100;
  dialog.value = true;
}
async function onSubmit() {
  const payload = { ...form, price: Math.round(priceYuan.value * 100) };
  if (form.id) await packageApi.update(form.id, payload);
  else await packageApi.add(payload);
  ElMessage.success('已保存');
  dialog.value = false;
  await load();
}
async function onDelete(row: PackageRow) {
  await ElMessageBox.confirm(`确认删除套餐「${row.name}」？`, '提示', { type: 'warning' });
  await packageApi.remove(row.id);
  ElMessage.success('已删除');
  await load();
}

onMounted(load);
</script>

<style scoped>
.toolbar { display: flex; gap: 12px; margin-bottom: 12px; }
</style>
