<template>
  <div>
    <el-tabs v-model="tab" @tab-change="reload">
      <el-tab-pane label="我的客户" name="mine" />
      <el-tab-pane label="团队客户" name="team" />
      <el-tab-pane label="客户库(公海)" name="public" />
    </el-tabs>

    <div class="toolbar">
      <el-input v-model="keyword" placeholder="搜索姓名/电话" style="width: 220px" clearable @keyup.enter="reload" @clear="reload" />
      <el-button type="primary" @click="reload">查询</el-button>
      <el-button type="primary" @click="onCreate">新增客户</el-button>
      <el-button v-if="tab === 'public'" type="success" :disabled="!selected.length" @click="onAssign">分配给坐席</el-button>
      <el-button v-else type="warning" :disabled="!selected.length" @click="onAbandon">放弃回公海</el-button>
      <el-button type="danger" :disabled="!selected.length" @click="onDeleteBatch">批量删除</el-button>
      <el-button :loading="exporting" @click="onExport">导出 Excel</el-button>
    </div>

    <el-table :data="customers" border v-loading="loading" @selection-change="onSelect">
      <el-table-column type="selection" width="50" />
      <el-table-column prop="name" label="姓名" />
      <el-table-column prop="phone" label="电话" />
      <el-table-column prop="company" label="公司" />
      <el-table-column prop="tags" label="标签" />
      <el-table-column label="意向" width="80">
        <template #default="{ row }">
          <el-tag v-if="profileOf(row.id)?.intentLevel" :type="intentType(profileOf(row.id)!.intentLevel)" size="small">
            {{ profileOf(row.id)!.intentLevel }}
          </el-tag>
          <span v-else style="color:#c0c4cc">-</span>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="90">
        <template #default="{ row }">{{ statusText(row.status) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="300">
        <template #default="{ row }">
          <el-button link type="primary" @click="onDetail(row)">详情</el-button>
          <el-button link type="primary" @click="onEdit(row)">编辑</el-button>
          <el-button link type="success" @click="onProfile(row)">画像</el-button>
          <el-button link type="primary" @click="onTransfer(row)">转让</el-button>
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

    <!-- 新增 / 编辑客户 -->
    <el-dialog v-model="editVisible" :title="editForm.id ? '编辑客户' : '新增客户'" width="520px">
      <el-form :model="editForm" label-width="90px">
        <el-form-item label="姓名"><el-input v-model="editForm.name" placeholder="客户姓名" /></el-form-item>
        <el-form-item label="手机号"><el-input v-model="editForm.phone" placeholder="必填，团队内唯一" /></el-form-item>
        <el-form-item label="公司"><el-input v-model="editForm.company" /></el-form-item>
        <el-form-item label="地址"><el-input v-model="editForm.address" /></el-form-item>
        <el-form-item label="标签"><el-input v-model="editForm.tags" placeholder="多个用逗号分隔" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="editForm.status" style="width: 100%">
            <el-option label="正常" value="normal" />
            <el-option label="跟进中" value="follow_up" />
            <el-option label="无效" value="dead" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="editForm.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveCustomer">保存</el-button>
      </template>
    </el-dialog>

    <!-- 选择坐席对话框（转让/分配共用） -->
    <el-dialog v-model="pickDialog" :title="pickTitle" width="420px">
      <el-select v-model="pickUserId" placeholder="选择坐席" style="width: 100%">
        <el-option v-for="m in members" :key="m.userId" :label="`${m.nickname}（${m.phone}）`" :value="m.userId" />
      </el-select>
      <template #footer>
        <el-button @click="pickDialog = false">取消</el-button>
        <el-button type="primary" :disabled="!pickUserId" :loading="acting" @click="confirmPick">确定</el-button>
      </template>
    </el-dialog>

    <!-- 客户详情抽屉：基本信息 + 画像 + 通话记录 + 回访时间线 -->
    <el-drawer v-model="detailVisible" :title="detailCustomer?.name || '客户详情'" size="520px">
      <div v-loading="detailLoading">
        <el-descriptions :column="1" border v-if="detailCustomer">
          <el-descriptions-item label="姓名">{{ detailCustomer.name }}</el-descriptions-item>
          <el-descriptions-item label="电话">{{ detailCustomer.phone }}</el-descriptions-item>
          <el-descriptions-item label="公司">{{ detailCustomer.company || '-' }}</el-descriptions-item>
          <el-descriptions-item label="地址">{{ detailCustomer.address || '-' }}</el-descriptions-item>
          <el-descriptions-item label="标签">{{ detailCustomer.tags || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注">{{ detailCustomer.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <div v-if="detailProfile" class="profile-block">
          <h4>客户画像</h4>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="意向等级">{{ detailProfile.intentLevel || '-' }}</el-descriptions-item>
            <el-descriptions-item label="是否决策人">{{ detailProfile.isDecision ? '是' : '否' }}</el-descriptions-item>
            <el-descriptions-item label="行业">{{ detailProfile.industry || '-' }}</el-descriptions-item>
            <el-descriptions-item label="职位">{{ detailProfile.position || '-' }}</el-descriptions-item>
            <el-descriptions-item label="微信">{{ detailProfile.wechat || '-' }}</el-descriptions-item>
            <el-descriptions-item label="预算">{{ detailProfile.budget || '-' }}</el-descriptions-item>
            <el-descriptions-item label="痛点" :span="2">{{ detailProfile.painPoint || '-' }}</el-descriptions-item>
            <el-descriptions-item label="小结" :span="2">{{ detailProfile.summary || '-' }}</el-descriptions-item>
          </el-descriptions>
        </div>

        <h4 style="margin: 16px 0 8px">通话记录（{{ detailRecords.length }}）</h4>
        <el-table :data="detailRecords" border size="small">
          <el-table-column label="结果" width="80">
            <template #default="{ row }">{{ recordLabel(row.result) }}</template>
          </el-table-column>
          <el-table-column prop="phone" label="号码" />
          <el-table-column label="时长" width="80">
            <template #default="{ row }">{{ row.duration ? row.duration + '″' : '-' }}</template>
          </el-table-column>
          <el-table-column prop="calledAt" label="时间" />
        </el-table>

        <h4 style="margin: 16px 0 8px">回访时间线（{{ detailFollowUps.length }}）</h4>
        <el-timeline v-if="detailFollowUps.length">
          <el-timeline-item
            v-for="f in detailFollowUps"
            :key="f.id"
            :timestamp="f.createdAt"
            placement="top">
            <div>{{ f.content }}</div>
            <span style="color: #999" v-if="f.tag">#{{ f.tag }}</span>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无回访" :image-size="60" />
      </div>
    </el-drawer>

    <!-- 客户画像编辑抽屉 -->
    <el-drawer v-model="profileVisible" :title="`客户画像 - ${profileCustomer?.name || ''}`" size="560px">
      <div v-loading="profileLoading">
        <el-form :model="profileForm" label-width="100px">
          <el-divider content-position="left">基本信息</el-divider>
          <el-row :gutter="12">
            <el-col :span="12">
              <el-form-item label="性别">
                <el-select v-model="profileForm.gender" style="width:100%">
                  <el-option label="未知" value="" /><el-option label="男" value="男" /><el-option label="女" value="女" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="年龄"><el-input-number v-model="profileForm.age" :min="0" :max="120" controls-position="right" style="width:100%" /></el-form-item>
            </el-col>
            <el-col :span="12"><el-form-item label="生日"><el-input v-model="profileForm.birthday" placeholder="如 1990-05-20" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="行业"><el-input v-model="profileForm.industry" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="职位"><el-input v-model="profileForm.position" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="微信"><el-input v-model="profileForm.wechat" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="邮箱"><el-input v-model="profileForm.email" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="备用电话"><el-input v-model="profileForm.secondPhone" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="省份"><el-input v-model="profileForm.province" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="城市"><el-input v-model="profileForm.city" /></el-form-item></el-col>
          </el-row>

          <el-divider content-position="left">商机信息</el-divider>
          <el-row :gutter="12">
            <el-col :span="12">
              <el-form-item label="意向等级">
                <el-select v-model="profileForm.intentLevel" style="width:100%">
                  <el-option label="未评估" value="" /><el-option label="A 高" value="A" /><el-option label="B 中" value="B" /><el-option label="C 低" value="C" /><el-option label="D 无" value="D" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12"><el-form-item label="预算"><el-input v-model="profileForm.budget" /></el-form-item></el-col>
            <el-col :span="12">
              <el-form-item label="决策人">
                <el-switch v-model="profileForm.isDecision" :active-value="1" :inactive-value="0" />
              </el-form-item>
            </el-col>
            <el-col :span="12"><el-form-item label="来源渠道"><el-input v-model="profileForm.channel" /></el-form-item></el-col>
            <el-col :span="24"><el-form-item label="感兴趣产品"><el-input v-model="profileForm.productInterest" /></el-form-item></el-col>
            <el-col :span="24"><el-form-item label="客户痛点"><el-input v-model="profileForm.painPoint" type="textarea" :rows="2" /></el-form-item></el-col>
            <el-col :span="24"><el-form-item label="在用竞品"><el-input v-model="profileForm.competitor" /></el-form-item></el-col>
            <el-col :span="24">
              <el-form-item label="下次跟进">
                <el-date-picker v-model="profileForm.nextFollowAt" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" placeholder="选择时间" style="width:100%" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-divider content-position="left">总结</el-divider>
          <el-form-item label="画像标签"><el-input v-model="profileForm.profileTags" placeholder="多个用逗号分隔" /></el-form-item>
          <el-form-item label="画像小结"><el-input v-model="profileForm.summary" type="textarea" :rows="3" placeholder="一通电话聊下来的关键信息" /></el-form-item>

          <div v-if="profileForm.callCount !== undefined" class="call-stat">
            累计拨打 {{ profileForm.callCount || 0 }} 次　最近：{{ profileForm.lastCalledAt || '未拨打' }}
          </div>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="profileVisible = false">取消</el-button>
        <el-button type="primary" :loading="profileSaving" @click="saveProfile">保存画像</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { customerApi, emptyProfile, type CustomerRow, type CustomerScope, type CustomerProfile } from '@/api/customer';
import { teamApi, type TeamMemberVO } from '@/api/team';
import { recordsApi } from '@/api/records';
import { followupApi, type FollowUpRow } from '@/api/followup';
import { ElMessage, ElMessageBox } from 'element-plus';
import { exportApi } from '@/api/export';

const tab = ref<CustomerScope>('mine');
const keyword = ref('');
const exporting = ref(false);
const customers = ref<CustomerRow[]>([]);
const selected = ref<CustomerRow[]>([]);
const loading = ref(false);
const total = ref(0);
const current = ref(1);
const size = ref(20);

const members = ref<TeamMemberVO[]>([]);
const pickDialog = ref(false);
const pickTitle = ref('');
const pickUserId = ref<number | null>(null);
const acting = ref(false);
let pendingAction: 'transfer' | 'assign' = 'transfer';

// 画像缓存：customerId -> profile
const profileCache = ref<Record<number, CustomerProfile>>({});
function profileOf(id: number) {
  return profileCache.value[id];
}
function intentType(v: string) {
  return ({ A: 'danger', B: 'warning', C: 'info', D: 'info' } as Record<string, any>)[v] || 'info';
}

function statusText(s: string) {
  return { normal: '正常', follow_up: '跟进中', dead: '无效' }[s] || s;
}

async function loadMembers() {
  members.value = await teamApi.list();
}

async function reload() {
  current.value = 1;
  await load();
}

async function load() {
  loading.value = true;
  try {
    const data: any = await customerApi.list(tab.value, keyword.value, current.value, size.value);
    customers.value = data.records || [];
    total.value = data.total || 0;
    await loadProfiles();
  } finally {
    loading.value = false;
  }
}

async function loadProfiles() {
  const ids = customers.value.map((c) => c.id);
  if (!ids.length) return;
  try {
    const m: any = await customerApi.profiles(ids);
    if (m) Object.assign(profileCache.value, m);
  } catch {
    /* 画像拉取失败不影响列表 */
  }
}

async function onExport() {
  exporting.value = true;
  try {
    const name = await exportApi.customers(tab.value, keyword.value);
    ElMessage.success(`已导出：${name}`);
  } catch (e: any) {
    ElMessage.error(`导出失败：${e?.message || '请稍后重试'}`);
  } finally {
    exporting.value = false;
  }
}

function onSelect(rows: CustomerRow[]) {
  selected.value = rows;
}
function onPage(p: number) {
  current.value = p;
  load();
}

function openPick(action: 'transfer' | 'assign') {
  pendingAction = action;
  pickTitle.value = action === 'transfer' ? '转让给坐席' : '分配给坐席';
  pickUserId.value = null;
  pickDialog.value = true;
}

async function confirmPick() {
  if (!pickUserId.value) return;
  acting.value = true;
  try {
    if (pendingAction === 'transfer') {
      const ids = selected.value.map((c) => c.id);
      for (const id of ids) await customerApi.transfer(id, pickUserId.value as number);
      ElMessage.success('已转让');
    } else {
      const ids = selected.value.map((c) => c.id);
      for (const id of ids) await customerApi.assign(id, pickUserId.value as number);
      ElMessage.success('已分配');
    }
    pickDialog.value = false;
    await reload();
  } finally {
    acting.value = false;
  }
}

function onTransfer(row: CustomerRow) {
  selected.value = [row];
  openPick('transfer');
}

async function onAssign() {
  if (!selected.value.length) return ElMessage.warning('请先勾选客户');
  openPick('assign');
}

async function onAbandon() {
  if (!selected.value.length) return ElMessage.warning('请先勾选客户');
  await ElMessageBox.confirm(`确认将选中的 ${selected.value.length} 个客户放弃回公海？`, '提示', { type: 'warning' });
  acting.value = true;
  try {
    for (const c of selected.value) await customerApi.abandon(c.id);
    ElMessage.success('已放弃回公海');
    await reload();
  } finally {
    acting.value = false;
  }
}

// ---------- 新增 / 编辑 ----------
const editVisible = ref(false);
const saving = ref(false);
const editForm = ref<any>({ id: null, name: '', phone: '', company: '', address: '', tags: '', status: 'normal', remark: '' });

function onCreate() {
  editForm.value = { id: null, name: '', phone: '', company: '', address: '', tags: '', status: 'normal', remark: '' };
  editVisible.value = true;
}

function onEdit(row: CustomerRow) {
  editForm.value = { ...row };
  editVisible.value = true;
}

async function saveCustomer() {
  if (!editForm.value.phone?.trim()) return ElMessage.warning('手机号必填');
  saving.value = true;
  try {
    if (editForm.value.id) {
      await customerApi.update(editForm.value);
      ElMessage.success('已保存');
    } else {
      await customerApi.create(editForm.value);
      ElMessage.success('已新增');
    }
    editVisible.value = false;
    await reload();
  } finally {
    saving.value = false;
  }
}

async function onDelete(row: CustomerRow) {
  await ElMessageBox.confirm(`确认删除客户「${row.name || row.phone}」？删除后可在备份中恢复。`, '删除确认', { type: 'warning' });
  await customerApi.remove(row.id);
  ElMessage.success('已删除');
  await reload();
}

async function onDeleteBatch() {
  if (!selected.value.length) return ElMessage.warning('请先勾选客户');
  await ElMessageBox.confirm(`确认删除选中的 ${selected.value.length} 个客户？`, '批量删除', { type: 'warning' });
  await customerApi.removeBatch(selected.value.map((c) => c.id));
  ElMessage.success('已删除');
  await reload();
}

// ---------- 详情 ----------
const detailVisible = ref(false);
const detailLoading = ref(false);
const detailCustomer = ref<any>(null);
const detailProfile = ref<CustomerProfile | null>(null);
const detailRecords = ref<any[]>([]);
const detailFollowUps = ref<FollowUpRow[]>([]);

function recordLabel(r: string) {
  return { empty: '空号', not_answered: '未接通', connected: '已接通', add_customer: '添加客户' }[r] || r;
}

async function onDetail(row: CustomerRow) {
  detailVisible.value = true;
  detailLoading.value = true;
  detailProfile.value = null;
  try {
    const [c, recs, fus] = await Promise.all([
      customerApi.detail(row.id),
      recordsApi.byCustomer(row.id),
      followupApi.list(row.id),
    ]);
    detailCustomer.value = c;
    detailRecords.value = recs || [];
    detailFollowUps.value = fus || [];
    try {
      detailProfile.value = await customerApi.getProfile(row.id);
    } catch { /* 画像可能不存在 */ }
  } finally {
    detailLoading.value = false;
  }
}

// ---------- 画像 ----------
const profileVisible = ref(false);
const profileLoading = ref(false);
const profileSaving = ref(false);
const profileCustomer = ref<CustomerRow | null>(null);
const profileForm = ref<CustomerProfile>(emptyProfile());

async function onProfile(row: CustomerRow) {
  profileCustomer.value = row;
  profileVisible.value = true;
  profileLoading.value = true;
  try {
    const p = await customerApi.getProfile(row.id);
    profileForm.value = { ...emptyProfile(), ...p };
  } catch (e) {
    profileForm.value = emptyProfile();
  } finally {
    profileLoading.value = false;
  }
}

async function saveProfile() {
  if (!profileCustomer.value) return;
  profileSaving.value = true;
  try {
    const saved = await customerApi.saveProfile(profileCustomer.value.id, profileForm.value);
    profileCache.value[profileCustomer.value.id] = saved;
    ElMessage.success('画像已保存');
    profileVisible.value = false;
    await load();
  } finally {
    profileSaving.value = false;
  }
}

onMounted(async () => {
  await loadMembers();
  await load();
});
</script>

<style scoped>
.toolbar { display: flex; gap: 8px; margin: 12px 0; flex-wrap: wrap; }
.pager { margin-top: 12px; justify-content: flex-end; }
.profile-block { margin-top: 16px; }
.profile-block h4 { margin: 0 0 8px; }
.call-stat { color: #909399; font-size: 12px; padding: 8px 0; }
</style>
