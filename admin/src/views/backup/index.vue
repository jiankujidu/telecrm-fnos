<template>
  <div class="backup-page">
    <el-alert
      type="warning"
      :closable="false"
      show-icon
      title="数据备份用于防止数据丢失：导出的 JSON 含全部客户、画像、通话记录、任务、订单等。换机器或重装后上传同一个文件即可恢复。" />

    <el-row :gutter="16" class="cards">
      <el-col :span="12">
        <el-card shadow="never">
          <template #header><b>① 备份（导出全部数据）</b></template>
          <p class="tip">把当前数据库里的全部业务数据打包成一个 JSON 文件下载到本地。</p>
          <el-button type="primary" size="large" :loading="exporting" @click="onExport">立即备份下载</el-button>
          <p class="hint">建议每周备份一次，重大操作（批量导入、批量删除）前先备份。</p>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card shadow="never">
          <template #header><b>② 恢复（导入备份文件）</b></template>
          <p class="tip">选择之前导出的 JSON 备份文件，先预览条数，确认后再写入。</p>

          <el-upload
            :auto-upload="false"
            :limit="1"
            accept=".json"
            :on-change="onFileChange"
            :on-remove="onFileRemove"
            :file-list="fileList">
            <el-button size="large">选择备份文件</el-button>
            <template #tip><div class="el-upload__tip">只支持 .json 备份文件</div></template>
          </el-upload>

          <div class="mode">
            <span>恢复方式：</span>
            <el-radio-group v-model="mode">
              <el-radio value="overwrite">覆盖（清空现有数据后写入，结果与备份一致）</el-radio>
              <el-radio value="append">追加（只补进缺失的记录，保留现有数据）</el-radio>
            </el-radio-group>
          </div>

          <div class="actions">
            <el-button :disabled="!file" :loading="previewing" @click="onPreview">预览文件内容</el-button>
            <el-button type="danger" :disabled="!file" :loading="restoring" @click="onRestore">确认恢复</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 预览结果 -->
    <el-card v-if="preview" shadow="never" class="preview">
      <template #header><b>备份文件内容</b></template>
      <p>导出时间：{{ preview.exportedAt || '-' }}　共 {{ preview.totalRows }} 条记录</p>
      <el-table :data="previewRows" border size="small" max-height="360">
        <el-table-column prop="table" label="数据表" />
        <el-table-column prop="label" label="说明" />
        <el-table-column prop="count" label="条数" width="100" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { backupApi } from '@/api/backup';

const TABLE_LABEL: Record<string, string> = {
  team: '团队',
  user: '用户/坐席',
  team_member: '团队成员',
  customer: '客户',
  customer_profile: '客户画像',
  follow_up: '跟进记录',
  customer_transfer_log: '客户流转日志',
  call_task: '外呼任务',
  call_task_item: '外呼任务明细',
  call_record: '通话记录',
  business_template: '业务模板',
  custom_field: '自定义字段',
  package: '套餐',
  order: '订单',
  vip_code: '激活码',
};

const exporting = ref(false);
const previewing = ref(false);
const restoring = ref(false);
const file = ref<File | null>(null);
const fileList = ref<any[]>([]);
const mode = ref<'overwrite' | 'append'>('overwrite');
const preview = ref<any>(null);

const previewRows = computed(() => {
  const counts = preview.value?.counts || {};
  return Object.keys(counts).map((k) => ({
    table: k,
    label: TABLE_LABEL[k] || k,
    count: counts[k],
  }));
});

async function onExport() {
  exporting.value = true;
  try {
    const name = await backupApi.export();
    ElMessage.success(`已备份：${name}`);
  } catch (e: any) {
    ElMessage.error(`备份失败：${e?.message || '请稍后重试'}`);
  } finally {
    exporting.value = false;
  }
}

function onFileChange(uploadFile: any) {
  file.value = uploadFile.raw as File;
  fileList.value = [uploadFile];
  preview.value = null;
}

function onFileRemove() {
  file.value = null;
  fileList.value = [];
  preview.value = null;
}

async function onPreview() {
  if (!file.value) return;
  previewing.value = true;
  try {
    preview.value = await backupApi.preview(file.value);
    ElMessage.success('读取成功，请核对条数');
  } catch (e: any) {
    ElMessage.error(`预览失败：${e?.message || '文件格式可能不对'}`);
  } finally {
    previewing.value = false;
  }
}

async function onRestore() {
  if (!file.value) return;
  const isOverwrite = mode.value === 'overwrite';
  await ElMessageBox.confirm(
    isOverwrite
      ? '覆盖恢复会先清空现有全部业务数据，再写入备份内容，当前数据将被替换。确定继续？'
      : '追加恢复只写入当前不存在的记录，现有数据保留。确定继续？',
    '恢复确认',
    { type: 'warning' },
  );
  restoring.value = true;
  try {
    const res: any = await backupApi.restore(file.value, mode.value);
    const skipped = res?.skipped || [];
    ElMessage.success(
      `恢复完成，共写入 ${res?.totalRows ?? 0} 条` + (skipped.length ? `，跳过 ${skipped.length} 张表` : ''),
    );
  } catch (e: any) {
    ElMessage.error(`恢复失败：${e?.message || '请稍后重试'}`);
  } finally {
    restoring.value = false;
  }
}
</script>

<style scoped>
.backup-page { max-width: 1100px; }
.cards { margin-top: 16px; }
.tip { color: #606266; font-size: 13px; margin: 0 0 12px; }
.hint { color: #909399; font-size: 12px; margin: 12px 0 0; }
.mode { margin: 16px 0 12px; font-size: 13px; }
.mode :deep(.el-radio) { margin-right: 12px; }
.actions { display: flex; gap: 8px; }
.preview { margin-top: 16px; }
</style>
