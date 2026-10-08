<template>
  <div>
    <div class="toolbar">
      <el-radio-group v-model="scope" @change="reload">
        <el-radio-button value="mine">我的话单</el-radio-button>
        <el-radio-button value="team">团队话单</el-radio-button>
      </el-radio-group>
      <el-select v-model="result" placeholder="全部结果" clearable style="width: 150px" @change="reload">
        <el-option label="已接通" value="connected" />
        <el-option label="添加客户" value="add_customer" />
        <el-option label="未接通" value="not_answered" />
        <el-option label="空号" value="empty" />
      </el-select>
      <el-button :loading="exporting" @click="onExport">导出 Excel</el-button>
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="phone" label="号码" width="140" />
      <el-table-column prop="result" label="结果" width="100">
        <template #default="{ row }">
          <el-tag :type="resultType(row.result)">{{ resultText(row.result) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="duration" label="时长" width="90">
        <template #default="{ row }">{{ formatDuration(row.duration) }}</template>
      </el-table-column>
      <el-table-column prop="tag" label="快捷备注" width="120" />
      <el-table-column prop="remark" label="备注" show-overflow-tooltip />
      <el-table-column label="录音" min-width="240">
        <template #default="{ row }">
          <audio v-if="row.recordingUrl" :src="audioSrc(row.recordingUrl)" controls style="height: 32px; width: 220px" />
          <el-button v-else link type="primary" @click="pickFile(row)">上传录音</el-button>
        </template>
      </el-table-column>
      <el-table-column prop="calledAt" label="拨打时间" width="180" />
    </el-table>

    <el-pagination
      class="pager"
      background
      layout="total, prev, pager, next"
      :total="total"
      :current-page="current"
      :page-size="size"
      @current-change="onPage" />

    <input ref="fileInput" type="file" accept="audio/*" style="display: none" @change="onFileChange" />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { ElMessage } from 'element-plus';
import { recordsApi, type CallRecordRow, type RecordScope } from '@/api/records';
import { exportApi } from '@/api/export';

const scope = ref<RecordScope>('mine');
const result = ref('');
const exporting = ref(false);
const rows = ref<CallRecordRow[]>([]);
const loading = ref(false);
const total = ref(0);
const current = ref(1);
const size = ref(20);

const fileInput = ref<HTMLInputElement | null>(null);
let uploadRowId: number | null = null;

function resultText(s: string) {
  return { empty: '空号', connected: '已接通', not_answered: '未接通', add_customer: '添加客户' }[s] || '—';
}

async function onExport() {
  exporting.value = true;
  try {
    const name = await exportApi.callRecords(scope.value, result.value || undefined);
    ElMessage.success(`已导出：${name}`);
  } catch (e: any) {
    ElMessage.error(`导出失败：${e?.message || '请稍后重试'}`);
  } finally {
    exporting.value = false;
  }
}
function resultType(s: string) {
  return { connected: 'success', add_customer: 'success', not_answered: 'warning', empty: 'info' }[s] || '';
}
function formatDuration(sec: number) {
  if (!sec) return '0″';
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return m > 0 ? `${m}′${s}″` : `${s}″`;
}
// 录音 URL 为相对 context-path(/api) 的路径，前端拼接 /api 后由代理转发
function audioSrc(url: string) {
  if (!url) return '';
  return url.startsWith('http') ? url : '/api' + url;
}

function pickFile(row: CallRecordRow) {
  uploadRowId = row.id;
  fileInput.value?.click();
}
async function onFileChange(e: Event) {
  const target = e.target as HTMLInputElement;
  const file = target.files?.[0];
  target.value = '';
  if (!file || uploadRowId == null) return;
  try {
    const up: any = await recordsApi.upload(file);
    const url = up?.data?.url || up?.url;
    if (!url) throw new Error('上传未返回地址');
    await recordsApi.attachRecording(uploadRowId, url);
    ElMessage.success('录音已关联');
    await load();
  } catch (err: any) {
    ElMessage.error('上传失败：' + (err?.message || err));
  } finally {
    uploadRowId = null;
  }
}

async function reload() {
  current.value = 1;
  await load();
}
async function load() {
  loading.value = true;
  try {
    const data: any = await recordsApi.list(scope.value, result.value, current.value, size.value);
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

onMounted(load);
</script>

<style scoped>
.toolbar { display: flex; gap: 12px; margin-bottom: 12px; }
.pager { margin-top: 12px; justify-content: flex-end; }
</style>
