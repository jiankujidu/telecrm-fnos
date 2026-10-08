<template>
  <div>
    <div class="toolbar">
      <el-radio-group v-model="statusFilter" @change="reload">
        <el-radio-button :value="''">全部</el-radio-button>
        <el-radio-button :value="0">待支付</el-radio-button>
        <el-radio-button :value="1">已支付</el-radio-button>
        <el-radio-button :value="2">已取消</el-radio-button>
      </el-radio-group>
      <el-button type="primary" @click="openCreate">创建订单</el-button>
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="订单号" width="110" />
      <el-table-column prop="userId" label="用户ID" width="100" />
      <el-table-column label="套餐" width="160">
        <template #default="{ row }">{{ pkgName(row.packageId) }}</template>
      </el-table-column>
      <el-table-column prop="amount" label="金额" width="110">
        <template #default="{ row }">¥{{ (row.amount / 100).toFixed(2) }}</template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="statusType(row.status)">{{ statusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="payTime" label="支付时间" width="180" />
      <el-table-column label="操作" width="100">
        <template #default="{ row }">
          <el-button v-if="row.status === 0" link type="primary" @click="onPay(row)">支付</el-button>
          <span v-else class="muted">—</span>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, prev, pager, next"
      :total="total" :current-page="current" :page-size="size" @current-change="onPage" />

    <el-dialog v-model="createDialog" title="创建订单" width="420px">
      <el-form label-width="90px">
        <el-form-item label="套餐">
          <el-select v-model="createPackageId" style="width: 100%">
            <el-option v-for="p in packages" :key="p.id" :label="`${p.name}（¥${(p.price/100).toFixed(2)}）`" :value="p.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createDialog = false">取消</el-button>
        <el-button type="primary" @click="onCreate">创建</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { orderApi, type OrderRow } from '@/api/order';
import { packageApi, type PackageRow } from '@/api/package';

const rows = ref<OrderRow[]>([]);
const loading = ref(false);
const total = ref(0);
const current = ref(1);
const size = ref(20);
const statusFilter = ref<number | ''>('');

const packages = ref<PackageRow[]>([]);
const createDialog = ref(false);
const createPackageId = ref<number>();

function pkgName(id: number) {
  return packages.value.find((p) => p.id === id)?.name || `套餐#${id}`;
}
function statusText(s: number) {
  return { 0: '待支付', 1: '已支付', 2: '已取消' }[s] || '—';
}
function statusType(s: number) {
  return { 0: 'warning', 1: 'success', 2: 'info' }[s] || '';
}
async function reload() {
  current.value = 1;
  await load();
}
async function load() {
  loading.value = true;
  try {
    const data: any = await orderApi.list(
      statusFilter.value === '' ? undefined : statusFilter.value,
      current.value,
      size.value,
    );
    rows.value = data.records || [];
    total.value = data.total || 0;
  } finally {
    loading.value = false;
  }
}
function onPage(p: number) {
  current.value = p;
  load();
}
function openCreate() {
  createPackageId.value = packages.value[0]?.id;
  createDialog.value = true;
}
async function onCreate() {
  if (!createPackageId.value) return ElMessage.warning('请选择套餐');
  await orderApi.create(createPackageId.value);
  ElMessage.success('订单已创建');
  createDialog.value = false;
  await load();
}
async function onPay(row: OrderRow) {
  await ElMessageBox.confirm(`确认将订单 #${row.id} 标记为已支付？`, '提示', { type: 'warning' });
  await orderApi.pay(row.id);
  ElMessage.success('已支付');
  await load();
}

onMounted(async () => {
  const res: any = await packageApi.list();
  packages.value = res || [];
  await load();
});
</script>

<style scoped>
.toolbar { display: flex; gap: 12px; margin-bottom: 12px; }
.pager { margin-top: 12px; justify-content: flex-end; }
.muted { color: #c0c4cc; }
</style>
