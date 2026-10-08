<template>
  <div>
    <el-alert type="info" :closable="false" show-icon
      title="客户画像表：打电话过程中把客户信息整理进来，支持直接编辑、删除、导出。" />

    <div class="toolbar">
      <el-select v-model="scope" style="width: 130px" @change="reload">
        <el-option label="我的客户" value="mine" />
        <el-option label="团队客户" value="team" />
        <el-option label="公海" value="public" />
      </el-select>
      <el-input v-model="keyword" placeholder="姓名/电话/公司" style="width: 200px" clearable @keyup.enter="reload" @clear="reload" />
      <el-select v-model="intentLevel" placeholder="意向等级" style="width: 130px" clearable @change="reload">
        <el-option label="A 高" value="A" /><el-option label="B 中" value="B" />
        <el-option label="C 低" value="C" /><el-option label="D 无" value="D" />
      </el-select>
      <el-button type="primary" @click="reload">查询</el-button>
      <el-button type="primary" @click="onCreate">新增客户</el-button>
      <el-button type="danger" :disabled="!selected.length" @click="onDeleteBatch">批量删除</el-button>
      <el-button :loading="exporting" @click="onExport">导出 Excel</el-button>
    </div>

    <el-table :data="rows" border v-loading="loading" @selection-change="onSelect">
      <el-table-column type="selection" width="50" />
      <el-table-column prop="name" label="姓名" width="100" />
      <el-table-column prop="phone" label="电话" width="130" />
      <el-table-column prop="company" label="公司" width="160" show-overflow-tooltip />
      <el-table-column label="意向" width="80">
        <template #default="{ row }">
          <el-tag v-if="row.intentLevel" :type="intentType(row.intentLevel)" size="small">{{ row.intentLevel }}</el-tag>
          <span v-else style="color:#c0c4cc">-</span>
        </template>
      </el-table-column>
      <el-table-column prop="industry" label="行业" width="110" show-overflow-tooltip />
      <el-table-column prop="position" label="职位" width="110" show-overflow-tooltip />
      <el-table-column prop="wechat" label="微信" width="120" show-overflow-tooltip />
      <el-table-column prop="budget" label="预算" width="100" show-overflow-tooltip />
      <el-table-column label="决策人" width="80">
        <template #default="{ row }">{{ row.isDecision ? '是' : '-' }}</template>
      </el-table-column>
      <el-table-column label="拨打" width="70">
        <template #default="{ row }">{{ row.callCount || 0 }}</template>
      </el-table-column>
      <el-table-column prop="profileTags" label="画像标签" width="140" show-overflow-tooltip />
      <el-table-column prop="summary" label="画像小结" min-width="200" show-overflow-tooltip />
      <el-table-column label="操作" width="150" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="onEditProfile(row)">编辑画像</el-button>
          <el-button link type="danger" @click="onDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, prev, pager, next"
      :total="total" :current-page="current" :page-size="size" @current-change="onPage" />

    <!-- 新增客户 -->
    <el-dialog v-model="createVisible" title="新增客户" width="520px">
      <el-form :model="createForm" label-width="90px">
        <el-form-item label="姓名"><el-input v-model="createForm.name" /></el-form-item>
        <el-form-item label="手机号"><el-input v-model="createForm.phone" placeholder="必填" /></el-form-item>
        <el-form-item label="公司"><el-input v-model="createForm.company" /></el-form-item>
        <el-form-item label="意向等级">
          <el-select v-model="createForm.intentLevel" style="width:100%" clearable>
            <el-option label="A 高" value="A" /><el-option label="B 中" value="B" />
            <el-option label="C 低" value="C" /><el-option label="D 无" value="D" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveCreate">保存</el-button>
      </template>
    </el-dialog>

    <!-- 编辑画像 -->
    <el-drawer v-model="editVisible" :title="`编辑画像 - ${editing?.name || ''}`" size="560px">
      <el-form :model="form" label-width="100px" v-loading="editLoading">
        <el-divider content-position="left">基本信息</el-divider>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="姓名"><el-input v-model="baseForm.name" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="电话"><el-input v-model="baseForm.phone" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="性别">
              <el-select v-model="form.gender" style="width:100%">
                <el-option label="未知" value="" /><el-option label="男" value="男" /><el-option label="女" value="女" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="年龄"><el-input-number v-model="form.age" :min="0" :max="120" controls-position="right" style="width:100%" /></el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="生日"><el-input v-model="form.birthday" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="行业"><el-input v-model="form.industry" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="职位"><el-input v-model="form.position" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="微信"><el-input v-model="form.wechat" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="备用电话"><el-input v-model="form.secondPhone" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="省份"><el-input v-model="form.province" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="城市"><el-input v-model="form.city" /></el-form-item></el-col>
        </el-row>

        <el-divider content-position="left">商机信息</el-divider>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="意向等级">
              <el-select v-model="form.intentLevel" style="width:100%">
                <el-option label="未评估" value="" /><el-option label="A 高" value="A" /><el-option label="B 中" value="B" /><el-option label="C 低" value="C" /><el-option label="D 无" value="D" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="预算"><el-input v-model="form.budget" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="决策人">
              <el-switch v-model="form.isDecision" :active-value="1" :inactive-value="0" />
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="来源渠道"><el-input v-model="form.channel" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="感兴趣产品"><el-input v-model="form.productInterest" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="客户痛点"><el-input v-model="form.painPoint" type="textarea" :rows="2" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="在用竞品"><el-input v-model="form.competitor" /></el-form-item></el-col>
          <el-col :span="24">
            <el-form-item label="下次跟进">
              <el-date-picker v-model="form.nextFollowAt" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">总结</el-divider>
        <el-form-item label="画像标签"><el-input v-model="form.profileTags" placeholder="多个用逗号分隔" /></el-form-item>
        <el-form-item label="画像小结"><el-input v-model="form.summary" type="textarea" :rows="3" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveEdit">保存</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { customerApi, emptyProfile, type CustomerProfile, type CustomerScope } from '@/api/customer';
import { ElMessage, ElMessageBox } from 'element-plus';
import { exportApi } from '@/api/export';

const scope = ref<CustomerScope>('mine');
const keyword = ref('');
const intentLevel = ref('');
const rows = ref<any[]>([]);
const selected = ref<any[]>([]);
const loading = ref(false);
const exporting = ref(false);
const total = ref(0);
const current = ref(1);
const size = ref(20);

function intentType(v: string) {
  return ({ A: 'danger', B: 'warning', C: 'info', D: 'info' } as Record<string, any>)[v] || 'info';
}

async function load() {
  loading.value = true;
  try {
    const data: any = await customerApi.profileList(scope.value, keyword.value, intentLevel.value, current.value, size.value);
    rows.value = data.records || [];
    total.value = data.total || 0;
  } finally {
    loading.value = false;
  }
}
function reload() { current.value = 1; load(); }
function onPage(p: number) { current.value = p; load(); }
function onSelect(v: any[]) { selected.value = v; }

// 新增客户
const createVisible = ref(false);
const createForm = ref<any>({ name: '', phone: '', company: '', intentLevel: '' });
const saving = ref(false);
function onCreate() {
  createForm.value = { name: '', phone: '', company: '', intentLevel: '' };
  createVisible.value = true;
}
async function saveCreate() {
  if (!createForm.value.phone?.trim()) return ElMessage.warning('手机号必填');
  saving.value = true;
  try {
    const c: any = await customerApi.create({
      name: createForm.value.name,
      phone: createForm.value.phone,
      company: createForm.value.company,
    });
    if (createForm.value.intentLevel) {
      await customerApi.saveProfile(c.id, { intentLevel: createForm.value.intentLevel });
    }
    ElMessage.success('已新增');
    createVisible.value = false;
    await reload();
  } finally {
    saving.value = false;
  }
}

// 编辑画像
const editVisible = ref(false);
const editLoading = ref(false);
const editing = ref<any>(null);
const form = ref<CustomerProfile>(emptyProfile());
const baseForm = ref<any>({ name: '', phone: '' });

async function onEditProfile(row: any) {
  editing.value = row;
  baseForm.value = { name: row.name || '', phone: row.phone || '' };
  editVisible.value = true;
  editLoading.value = true;
  try {
    const p = await customerApi.getProfile(row.id);
    form.value = { ...emptyProfile(), ...p };
  } catch {
    form.value = emptyProfile();
  } finally {
    editLoading.value = false;
  }
}

async function saveEdit() {
  if (!editing.value) return;
  saving.value = true;
  try {
    await customerApi.update({ id: editing.value.id, name: baseForm.value.name, phone: baseForm.value.phone });
    await customerApi.saveProfile(editing.value.id, form.value);
    ElMessage.success('已保存');
    editVisible.value = false;
    await load();
  } finally {
    saving.value = false;
  }
}

async function onDelete(row: any) {
  await ElMessageBox.confirm(`确认删除客户「${row.name || row.phone}」及其画像？`, '删除确认', { type: 'warning' });
  await customerApi.remove(row.id);
  ElMessage.success('已删除');
  await reload();
}

async function onDeleteBatch() {
  if (!selected.value.length) return ElMessage.warning('请先勾选');
  await ElMessageBox.confirm(`确认删除选中的 ${selected.value.length} 个客户？`, '批量删除', { type: 'warning' });
  await customerApi.removeBatch(selected.value.map((r) => r.id));
  ElMessage.success('已删除');
  await reload();
}

async function onExport() {
  exporting.value = true;
  try {
    const name = await exportApi.customers(scope.value, keyword.value);
    ElMessage.success(`已导出：${name}`);
  } catch (e: any) {
    ElMessage.error(`导出失败：${e?.message || '请稍后重试'}`);
  } finally {
    exporting.value = false;
  }
}

onMounted(load);
</script>

<style scoped>
.toolbar { display: flex; gap: 8px; margin: 12px 0; flex-wrap: wrap; }
.pager { margin-top: 12px; justify-content: flex-end; }
</style>
