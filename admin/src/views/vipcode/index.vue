<template>
  <div>
    <div class="toolbar">
      <el-radio-group v-model="statusFilter" @change="reload">
        <el-radio-button :value="''">全部</el-radio-button>
        <el-radio-button :value="0">未使用</el-radio-button>
        <el-radio-button :value="1">已使用</el-radio-button>
      </el-radio-group>
      <el-button type="primary" @click="openGen">批量生成</el-button>
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="90" />
      <el-table-column prop="code" label="兑换码" width="180" />
      <el-table-column label="对应套餐" width="160">
        <template #default="{ row }">{{ pkgName(row.packageId) }}</template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="row.status === 0 ? 'success' : 'info'">{{ row.status === 0 ? '未使用' : '已使用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="usedBy" label="使用者ID" width="110" />
      <el-table-column prop="usedAt" label="使用时间" width="180" />
      <el-table-column label="操作" width="100">
        <template #default="{ row }">
          <el-button link type="danger" :disabled="row.status === 1" @click="onDelete(row)">作废</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, prev, pager, next"
      :total="total" :current-page="current" :page-size="size" @current-change="onPage" />

    <el-dialog v-model="genDialog" title="批量生成兑换码" width="420px">
      <el-form label-width="90px">
        <el-form-item label="套餐">
          <el-select v-model="genPackageId" style="width: 100%">
            <el-option v-for="p in packages" :key="p.id" :label="p.name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="数量">
          <el-input-number v-model="genCount" :min="1" :max="500" style="width: 100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="genDialog = false">取消</el-button>
        <el-button type="primary" @click="onGenerate">生成</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { vipCodeApi, type VipCodeRow } from '@/api/vipcode';
import { packageApi, type PackageRow } from '@/api/package';

const rows = ref<VipCodeRow[]>([]);
const loading = ref(false);
const total = ref(0);
const current = ref(1);
const size = ref(20);
const statusFilter = ref<number | ''>('');

const packages = ref<PackageRow[]>([]);
const genDialog = ref(false);
const genPackageId = ref<number>();
const genCount = ref(10);

function pkgName(id: number) {
  return packages.value.find((p) => p.id === id)?.name || `套餐#${id}`;
}
async function reload() {
  current.value = 1;
  await load();
}
async function load() {
  loading.value = true;
  try {
    const data: any = await vipCodeApi.list(
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
function openGen() {
  genPackageId.value = packages.value[0]?.id;
  genCount.value = 10;
  genDialog.value = true;
}
async function onGenerate() {
  if (!genPackageId.value) return ElMessage.warning('请选择套餐');
  await vipCodeApi.generate(genPackageId.value, genCount.value);
  ElMessage.success('已生成');
  genDialog.value = false;
  await load();
}
async function onDelete(row: VipCodeRow) {
  await ElMessageBox.confirm(`确认作废兑换码「${row.code}」？`, '提示', { type: 'warning' });
  await vipCodeApi.remove(row.id);
  ElMessage.success('已作废');
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
</style>
