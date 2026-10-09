<template>
  <div>
    <el-alert type="success" :closable="false" show-icon
      title="云端自动外呼：电脑端建任务并控制节奏，手机 App 打开「自动外呼」页自动接单，按顺序一通一通拨出去。" />

    <!-- 当前任务状态卡 -->
    <el-card v-if="current" shadow="never" class="live">
      <template #header>
        <div class="live-head">
          <span class="live-title">{{ current.name }}</span>
          <el-tag :type="tagType(current.status)" effect="dark">{{ STATUS_TEXT[current.status] }}</el-tag>
          <span class="live-gap" />
          <el-button v-if="current.status === 'running'" type="warning" size="small" @click="ctrl('pause')">暂停</el-button>
          <el-button v-if="current.status === 'paused'" type="success" size="small" @click="ctrl('resume')">继续</el-button>
          <el-button v-if="current.status === 'running' || current.status === 'paused'" type="danger" size="small" @click="ctrl('stop')">结束</el-button>
        </div>
      </template>

      <el-row :gutter="24" class="live-body">
        <el-col :span="7">
          <div class="big">{{ progress.dialed }} <span class="unit">/ {{ progress.total }}</span></div>
          <div class="cap">已拨打 / 总数</div>
        </el-col>
        <el-col :span="7">
          <div class="big green">{{ progress.connected }}</div>
          <div class="cap">已接通</div>
        </el-col>
        <el-col :span="10">
          <div class="now">
            <template v-if="progress.current">
              <div class="now-name">{{ progress.current.name || '未命名' }} · 第 {{ progress.current.seq }} 条</div>
              <div class="now-phone">{{ progress.current.phone }}</div>
              <div class="now-company">{{ progress.current.company || '-' }}</div>
            </template>
            <template v-else>
              <div class="now-name">等待手机取号…</div>
              <div class="now-phone">--</div>
            </template>
          </div>
        </el-col>
      </el-row>

      <el-progress :percentage="percent" :stroke-width="14" striped :striped-flow="current.status === 'running'" />
      <div class="live-foot">
        <span>间隔 {{ current.intervalSeconds }} 秒</span>
        <span v-if="current.targetUserId">指定手机：{{ targetName }}</span>
        <span v-else>任意手机可执行</span>
        <span class="live-gap" />
        <el-button link type="primary" size="small" @click="openItems(current.id)">查看明细</el-button>
        <el-button v-if="progress.current" link type="warning" size="small"
          @click="skipItem(progress.current.itemId)">跳过当前</el-button>
      </div>
    </el-card>

    <div class="toolbar">
      <el-button type="primary" @click="createVisible = true">新建外呼任务</el-button>
      <el-button :loading="loading" @click="reload">刷新</el-button>
      <el-checkbox v-model="autoRefresh" style="margin-left:12px">自动刷新（2 秒）</el-checkbox>
      <span class="hint">提示：手机端打开「自动外呼」页保持前台，就会自动按顺序拨号。</span>
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="name" label="任务名称" min-width="180" show-overflow-tooltip />
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="tagType(row.status)" size="small">{{ STATUS_TEXT[row.status] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="进度" width="200">
        <template #default="{ row }">
          <el-progress :percentage="row.totalCount ? Math.floor(row.dialedCount / row.totalCount * 100) : 0"
            :stroke-width="10" />
          <span class="mini">{{ row.dialedCount }} / {{ row.totalCount }}（接通 {{ row.connectedCount }}）</span>
        </template>
      </el-table-column>
      <el-table-column label="范围" width="110">
        <template #default="{ row }">
          {{ scopeText(row.scope) }}<span v-if="row.keyword"> · {{ row.keyword }}</span>
        </template>
      </el-table-column>
      <el-table-column label="间隔" width="80">
        <template #default="{ row }">{{ row.intervalSeconds }} 秒</template>
      </el-table-column>
      <el-table-column prop="createdAt" label="创建时间" width="170" />
      <el-table-column label="操作" width="300" fixed="right">
        <template #default="{ row }">
          <el-button v-if="row.status === 'pending' || row.status === 'cancelled'" link type="success"
            @click="start(row)">开始</el-button>
          <el-button v-if="row.status === 'running'" link type="warning" @click="ctrl2(row, 'pause')">暂停</el-button>
          <el-button v-if="row.status === 'paused'" link type="success" @click="ctrl2(row, 'resume')">继续</el-button>
          <el-button v-if="row.status === 'running' || row.status === 'paused'" link type="danger"
            @click="ctrl2(row, 'stop')">结束</el-button>
          <el-button v-if="row.status === 'pending'" link type="danger" @click="ctrl2(row, 'cancel')">取消</el-button>
          <el-button link type="primary" @click="openItems(row.id)">明细</el-button>
          <el-button link type="danger" @click="onRemove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 新建任务 -->
    <el-dialog v-model="createVisible" title="新建云端外呼任务" width="640px">
      <el-form :model="form" label-width="130px">
        <el-form-item label="任务名称">
          <el-input v-model="form.name" placeholder="留空自动生成，如：自动外呼 2026-01-01 10:00" />
        </el-form-item>
        <el-form-item label="客户范围">
          <el-radio-group v-model="form.scope">
            <el-radio-button value="mine">我的客户</el-radio-button>
            <el-radio-button value="team">团队客户</el-radio-button>
            <el-radio-button value="public">公海</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="关键词筛选">
          <el-input v-model="form.keyword" placeholder="按姓名/电话/公司过滤，留空不过滤" clearable />
        </el-form-item>
        <el-form-item label="从哪个客户开始">
          <el-select v-model="form.startCustomerId" filterable remote clearable reserve-keyword
            :remote-method="searchCustomer" :loading="custLoading" placeholder="不选=从第 1 条开始；可输入姓名/电话搜索"
            style="width:100%">
            <el-option v-for="c in customers" :key="c.id" :label="`${c.name} ${c.phone}`" :value="c.id" />
          </el-select>
          <div class="tip">顺序与列表一致（最新导入的在前）。选定后从这一条开始，按顺序往后拨。</div>
        </el-form-item>
        <el-form-item label="拨打条数">
          <el-input-number v-model="form.limit" :min="1" :max="2000" />
          <span class="tip-inline">从起点开始最多取多少条</span>
        </el-form-item>
        <el-form-item label="间隔秒数">
          <el-input-number v-model="form.intervalSeconds" :min="0" :max="600" />
          <span class="tip-inline">上一通拨出后等多久再给下一通（0 = 挂断立刻给下一个，建议 10~30 秒）</span>
        </el-form-item>
        <el-form-item label="指定手机">
          <el-select v-model="form.targetUserId" clearable placeholder="不选=任意手机都能接单" style="width:100%">
            <el-option v-for="m in members" :key="m.userId" :label="`${m.nickname}（${m.phone}）`" :value="m.userId" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createVisible = false">取消</el-button>
        <el-button @click="submitCreate">只创建</el-button>
        <el-button type="primary" :loading="saving" @click="submitAndStart">创建并立即开始</el-button>
      </template>
    </el-dialog>

    <!-- 明细 -->
    <el-drawer v-model="itemsVisible" :title="`任务明细（共 ${items.length} 条）`" size="70%">
      <el-table :data="items" border size="small" height="100%">
        <el-table-column prop="seq" label="#" width="60" />
        <el-table-column prop="name" label="姓名" width="110" />
        <el-table-column prop="phone" label="电话" width="130" />
        <el-table-column prop="company" label="公司" min-width="150" show-overflow-tooltip />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag size="small" :type="row.status === 'dialed' ? 'success' : row.status === 'dialing' ? 'warning' : 'info'">
              {{ ITEM_STATUS_TEXT[row.status] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="结果" width="100">
          <template #default="{ row }">{{ RESULT_TEXT[row.result] || row.result || '-' }}</template>
        </el-table-column>
        <el-table-column prop="duration" label="时长(秒)" width="90" />
        <el-table-column prop="remark" label="备注" min-width="140" show-overflow-tooltip />
        <el-table-column label="操作" width="110" fixed="right">
          <template #default="{ row }">
            <el-button link type="warning" :disabled="row.status === 'dialed'"
              @click="skipItem(row.id)">跳过</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { customerApi } from '@/api/customer';
import { teamApi } from '@/api/team';
import {
  dialPushApi, STATUS_TEXT, STATUS_TYPE, ITEM_STATUS_TEXT, RESULT_TEXT,
  type DialPushTask, type DialPushItem, type DialProgress,
} from '@/api/dialpush';

const rows = ref<DialPushTask[]>([]);
const loading = ref(false);
const autoRefresh = ref(true);
let timer: any = null;

const current = ref<DialPushTask | null>(null);
const progress = ref<DialProgress>({
  id: 0, name: '', status: 'pending', total: 0, dialed: 0,
  connected: 0, intervalSeconds: 15, startedAt: null, finishedAt: null,
});

const percent = computed(() =>
  progress.value.total ? Math.floor((progress.value.dialed / progress.value.total) * 100) : 0);

const tagType = (s: string) => STATUS_TYPE[s] || 'info';
const scopeText = (s: string) => ({ mine: '我的客户', team: '团队客户', public: '公海' } as any)[s] || s;

// ---------- 列表 ----------
async function reload() {
  loading.value = true;
  try {
    rows.value = await dialPushApi.list();
    const running = rows.value.find(
      (r) => r.status === 'running' || r.status === 'paused');
    current.value = running || null;
    if (running) await loadProgress(running.id);
  } finally {
    loading.value = false;
  }
}

async function loadProgress(id: number) {
  try {
    progress.value = await dialPushApi.progress(id);
    const t = rows.value.find((r) => r.id === id);
    if (t) {
      t.dialedCount = progress.value.dialed;
      t.connectedCount = progress.value.connected;
      t.status = progress.value.status as any;
    }
  } catch {
    /* ignore */
  }
}

watch(autoRefresh, (v) => {
  if (v) {
    timer = setInterval(() => {
      const c = current.value;
      if (c && (c.status === 'running' || c.status === 'paused')) loadProgress(c.id);
      else reload();
    }, 2000);
  } else if (timer) {
    clearInterval(timer);
    timer = null;
  }
}, { immediate: true });

onUnmounted(() => { if (timer) clearInterval(timer); });

// ---------- 控制 ----------
async function start(row: DialPushTask) {
  await dialPushApi.control(row.id, 'start');
  ElMessage.success('已开始，手机端会自动接单');
  current.value = row;
  await reload();
}

async function ctrl(action: 'pause' | 'resume' | 'stop') {
  if (!current.value) return;
  await ctrl2(current.value, action);
}

async function ctrl2(row: DialPushTask, action: 'start' | 'pause' | 'resume' | 'stop' | 'cancel') {
  await dialPushApi.control(row.id, action);
  ElMessage.success('操作成功');
  await reload();
}

async function skipItem(itemId: number) {
  if (!current.value) return;
  await dialPushApi.skip(current.value.id, itemId);
  ElMessage.success('已跳过');
  await loadProgress(current.value.id);
  if (itemsVisible.value) openItems(current.value.id);
}

async function onRemove(row: DialPushTask) {
  await ElMessageBox.confirm(`删除任务「${row.name}」？明细一并删除。`, '确认', { type: 'warning' });
  await dialPushApi.remove(row.id);
  ElMessage.success('已删除');
  await reload();
}

// ---------- 明细 ----------
const itemsVisible = ref(false);
const items = ref<DialPushItem[]>([]);
async function openItems(id: number) {
  itemsVisible.value = true;
  items.value = await dialPushApi.items(id);
}

// ---------- 新建 ----------
const createVisible = ref(false);
const saving = ref(false);
const members = ref<any[]>([]);
const customers = ref<any[]>([]);
const custLoading = ref(false);
const targetName = computed(() => {
  const m = members.value.find((x) => x.userId === current.value?.targetUserId);
  return m ? `${m.nickname}（${m.phone}）` : '-';
});

const form = reactive({
  name: '',
  scope: 'mine' as 'mine' | 'team' | 'public',
  keyword: '',
  startCustomerId: null as number | null,
  limit: 200,
  intervalSeconds: 15,
  targetUserId: null as number | null,
});

async function searchCustomer(kw: string) {
  custLoading.value = true;
  try {
    const res: any = await customerApi.list(form.scope, kw || '', 1, 30);
    customers.value = res.records || res.list || [];
  } finally {
    custLoading.value = false;
  }
}

watch(() => form.scope, () => { form.startCustomerId = null; customers.value = []; });

async function submitCreate(): Promise<number | null> {
  saving.value = true;
  try {
    const t: any = await dialPushApi.create({ ...form });
    ElMessage.success(`任务已创建，共 ${t.totalCount} 条`);
    createVisible.value = false;
    await reload();
    return t.id;
  } finally {
    saving.value = false;
  }
}

async function submitAndStart() {
  const id = await submitCreate();
  if (id) {
    await dialPushApi.control(id, 'start');
    ElMessage.success('已开始外呼，请让手机保持「自动外呼」页在前台');
    await reload();
  }
}

onMounted(async () => {
  await reload();
  try { members.value = await teamApi.list(); } catch { members.value = []; }
  searchCustomer('');
});
</script>

<style scoped>
.toolbar { margin: 14px 0; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.hint { color: #909399; font-size: 12px; }
.live { margin-top: 14px; }
.live-head { display: flex; align-items: center; gap: 10px; }
.live-title { font-size: 16px; font-weight: 600; }
.live-gap { flex: 1; }
.live-body { text-align: center; margin-bottom: 14px; }
.big { font-size: 30px; font-weight: 700; color: #409eff; line-height: 1.2; }
.big.green { color: #67c23a; }
.unit { font-size: 15px; color: #909399; font-weight: 400; }
.cap { color: #909399; font-size: 12px; margin-top: 2px; }
.now { text-align: left; padding: 6px 14px; border-left: 1px solid #ebeef5; }
.now-name { font-size: 14px; font-weight: 600; }
.now-phone { font-size: 22px; font-weight: 700; letter-spacing: 1px; margin: 2px 0; }
.now-company { color: #909399; font-size: 12px; }
.live-foot { display: flex; align-items: center; gap: 16px; margin-top: 10px; font-size: 12px; color: #606266; }
.mini { font-size: 12px; color: #909399; }
.tip { font-size: 12px; color: #909399; margin-top: 4px; line-height: 1.4; }
.tip-inline { font-size: 12px; color: #909399; margin-left: 10px; }
.pager { margin-top: 12px; justify-content: flex-end; }
</style>
