<template>
  <div>
    <div class="toolbar">
      <el-button type="primary" @click="onImportFile">文件导入</el-button>
    </div>
    <el-table :data="tasks" border v-loading="loading">
      <el-table-column prop="name" label="任务名称" />
      <el-table-column prop="sourceType" label="来源">
        <template #default="{ row }">{{ sourceText(row.sourceType) }}</template>
      </el-table-column>
      <el-table-column prop="totalCount" label="总数" />
      <el-table-column prop="calledCount" label="已拨打" />
      <el-table-column prop="validCount" label="有效客户" />
      <el-table-column prop="status" label="状态">
        <template #default="{ row }">
          <el-tag :type="row.status === 'finished' ? 'success' : row.status === 'running' ? 'warning' : 'info'">
            {{ statusText(row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180">
        <template #default="{ row }">
          <el-button link type="primary" @click="onDetail(row)">拨打详情</el-button>
          <el-button link type="danger" @click="onDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      class="pager"
      background
      layout="total, prev, pager, next"
      :total="total"
      :current-page="current"
      :page-size="size"
      @current-change="onPage" />

    <input ref="fileInput" type="file" accept=".xls,.xlsx,.csv,.txt" style="display:none" @change="onFileChange" />

    <!-- 导入对话框 -->
    <el-dialog v-model="importDialog" title="文件导入生成任务" width="460px">
      <el-upload drag :auto-upload="false" :limit="1" :on-change="onPickFile" :show-file-list="true">
        <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
        <div>拖入或点击选择 xls/xlsx/csv/txt 文件</div>
        <template #tip><div class="el-upload__tip">单次最多 5000 条，系统自动识别手机号列</div></template>
      </el-upload>
      <el-input v-model="importName" placeholder="任务名称（可选，默认文件名）" style="margin-top: 12px" />
      <template #footer>
        <el-button @click="importDialog = false">取消</el-button>
        <el-button type="primary" :loading="importing" :disabled="!pickedFile" @click="submitImport">开始导入</el-button>
      </template>
    </el-dialog>

    <!-- 明细对话框 -->
    <el-dialog v-model="detailDialog" :title="`拨打详情 - ${detailName}`" width="760px">
      <el-table :data="items" border v-loading="detailLoading" max-height="420">
        <el-table-column prop="name" label="姓名" />
        <el-table-column prop="phone" label="电话" />
        <el-table-column prop="company" label="公司" />
        <el-table-column prop="callCount" label="拨打次数" width="90" />
        <el-table-column prop="callResult" label="结果">
          <template #default="{ row }">{{ resultText(row.callResult) }}</template>
        </el-table-column>
        <el-table-column prop="status" label="状态">
          <template #default="{ row }">{{ itemStatusText(row.status) }}</template>
        </el-table-column>
      </el-table>
      <el-pagination
        class="pager"
        small
        background
        layout="prev, pager, next"
        :total="itemTotal"
        :current-page="itemCurrent"
        :page-size="itemSize"
        @current-change="onItemPage" />
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { taskApi, type CallTaskRow, type CallTaskItemRow } from '@/api/task';
import { ElMessage, ElMessageBox } from 'element-plus';
import type { UploadFile } from 'element-plus';

const tasks = ref<CallTaskRow[]>([]);
const loading = ref(false);
const total = ref(0);
const current = ref(1);
const size = ref(20);

const fileInput = ref<HTMLInputElement>();
const importDialog = ref(false);
const importing = ref(false);
const importName = ref('');
const pickedFile = ref<File | null>(null);

const detailDialog = ref(false);
const detailName = ref('');
const detailId = ref<number | null>(null);
const items = ref<CallTaskItemRow[]>([]);
const detailLoading = ref(false);
const itemTotal = ref(0);
const itemCurrent = ref(1);
const itemSize = ref(50);

function sourceText(s: string) {
  return { file: '文件导入', bigdata: '大数据拓客', nearby: '附近企业', public_sea: '号码公海' }[s] || s;
}
function statusText(s: string) {
  return { pending: '待开始', running: '进行中', finished: '已完成' }[s] || s;
}
function resultText(s: string) {
  return { empty: '空号', connected: '已接通', not_answered: '未接通', add_customer: '添加客户' }[s] || '—';
}
function itemStatusText(s: string) {
  return { pending: '待拨打', called: '已拨打', invalid: '空号', no_answer: '未接通', follow_up: '跟进中' }[s] || s;
}

async function load() {
  loading.value = true;
  try {
    const data: any = await taskApi.list(current.value, size.value);
    tasks.value = data.records || [];
    total.value = data.total || 0;
  } finally {
    loading.value = false;
  }
}
function onPage(p: number) {
  current.value = p;
  load();
}

function onImportFile() {
  importName.value = '';
  pickedFile.value = null;
  importDialog.value = true;
}
function onPickFile(_: UploadFile, fileList: UploadFile[]) {
  pickedFile.value = (fileList[fileList.length - 1]?.raw as File) || null;
}
function onFileChange(e: Event) {
  const f = (e.target as HTMLInputElement).files?.[0];
  if (f) pickedFile.value = f;
}
async function submitImport() {
  if (!pickedFile.value) return ElMessage.warning('请选择文件');
  importing.value = true;
  try {
    const taskId: number = await taskApi.importFile(pickedFile.value, importName.value || undefined);
    ElMessage.success(`导入成功，任务ID：${taskId}`);
    importDialog.value = false;
    await load();
  } finally {
    importing.value = false;
  }
}

async function onDetail(row: CallTaskRow) {
  detailId.value = row.id;
  detailName.value = row.name;
  itemCurrent.value = 1;
  detailDialog.value = true;
  await loadItems();
}
async function loadItems() {
  if (!detailId.value) return;
  detailLoading.value = true;
  try {
    const data: any = await taskApi.items(detailId.value, itemCurrent.value, itemSize.value);
    items.value = data.records || [];
    itemTotal.value = data.total || 0;
  } finally {
    detailLoading.value = false;
  }
}
function onItemPage(p: number) {
  itemCurrent.value = p;
  loadItems();
}

async function onDelete(row: CallTaskRow) {
  await ElMessageBox.confirm(`确认删除任务「${row.name}」？`, '提示', { type: 'warning' });
  await taskApi.remove(row.id);
  ElMessage.success('已删除');
  await load();
}

onMounted(load);
</script>

<style scoped>
.toolbar { margin-bottom: 12px; }
.pager { margin-top: 12px; justify-content: flex-end; }
.el-icon--upload { font-size: 50px; color: #c0c4cc; }
</style>
