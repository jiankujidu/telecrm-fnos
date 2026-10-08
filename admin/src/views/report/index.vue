<template>
  <div>
    <el-row :gutter="16">
      <el-col :span="6" v-for="c in cards" :key="c.label">
        <el-card shadow="hover">
          <div class="num">{{ c.value }}</div>
          <div class="label">{{ c.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 16px" v-loading="trendLoading">
      <template #header>
        <div class="trend-head">
          <span>通话趋势</span>
          <el-radio-group v-model="trendDays" size="small" @change="loadTrend">
            <el-radio-button :value="7">近7天</el-radio-button>
            <el-radio-button :value="30">近30天</el-radio-button>
          </el-radio-group>
        </div>
      </template>
      <div v-if="trend.length" class="chart-wrap">
        <svg :viewBox="`0 0 ${CHART.w} ${CHART.h}`" class="trend-svg">
          <!-- 网格 + Y 轴刻度 -->
          <g stroke="#eee" stroke-width="1">
            <line v-for="(t, i) in yTicks" :key="'g' + i" :x1="CHART.padL" :y1="t.y" :x2="CHART.w - CHART.padR" :y2="t.y" />
          </g>
          <text v-for="(t, i) in yTicks" :key="'y' + i" :x="CHART.padL - 6" :y="t.y + 4" text-anchor="end" class="axis-text">{{ t.label }}</text>
          <!-- 数据线 -->
          <polyline v-for="s in seriesPaths" :key="s.key" :points="s.points" fill="none" :stroke="s.color" stroke-width="2" stroke-linejoin="round" />
          <!-- X 轴标签 -->
          <text v-for="(x, i) in xLabels" :key="'x' + i" v-show="x.show" :x="x.x" :y="CHART.h - 8" text-anchor="middle" class="axis-text">{{ x.label }}</text>
        </svg>
        <div class="legend">
          <span v-for="s in seriesDefs" :key="s.key" class="legend-item">
            <i :style="{ background: s.color }"></i>{{ s.name }}
          </span>
        </div>
      </div>
      <el-empty v-else description="暂无数据" :image-size="60" />
    </el-card>

    <el-card style="margin-top: 16px" v-loading="loading">
      <template #header>团队报表（成员维度）</template>
      <el-table :data="rows" border>
        <el-table-column prop="nickname" label="成员" />
        <el-table-column prop="called" label="拨打数" />
        <el-table-column prop="connected" label="接通数" />
        <el-table-column prop="rate" label="接通率" />
        <el-table-column prop="notAnswered" label="未接通" />
        <el-table-column prop="empty" label="空号" />
        <el-table-column prop="addCustomer" label="加客户" />
        <el-table-column prop="valid" label="有效客户" />
        <el-table-column prop="convertRate" label="加客户率" />
        <el-table-column label="平均时长">
          <template #default="{ row }">{{ fmtDur(row.avgDuration) }}</template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { reportApi, type ReportOverview, type ReportTeamRow, type ReportTrendPoint } from '@/api/report';

const loading = ref(false);
const overview = ref<ReportOverview>({
  todayCalled: 0,
  todayConnected: 0,
  todayEmpty: 0,
  todayNotAnswered: 0,
  todayAddCustomer: 0,
  todayConnectRate: '0%',
  todayConvertRate: '0%',
  todayAvgDuration: 0,
  totalCalled: 0,
  validCustomers: 0,
  totalCustomers: 0,
  totalMembers: 0,
  totalTasks: 0,
});
const rows = ref<ReportTeamRow[]>([]);

// ---- 通话趋势（纯 SVG 自绘，无第三方图表依赖）----
const trendDays = ref(7);
const trend = ref<ReportTrendPoint[]>([]);
const trendLoading = ref(false);

const CHART = { w: 640, h: 260, padL: 40, padR: 16, padT: 24, padB: 28 };
const seriesDefs = [
  { key: 'called', name: '拨打', color: '#21c17a' },
  { key: 'connected', name: '接通', color: '#409eff' },
  { key: 'addCustomer', name: '加客户', color: '#e6a23c' },
];

const plotW = computed(() => CHART.w - CHART.padL - CHART.padR);
const plotH = computed(() => CHART.h - CHART.padT - CHART.padB);

// Y 轴上限：按 5 向上取整，避免刻度出现小数
const yMax = computed(() => {
  const max = Math.max(1, ...trend.value.map((p) => p.called));
  return Math.ceil(max / 5) * 5;
});

const xStep = computed(() => (trend.value.length <= 1 ? 0 : plotW.value / (trend.value.length - 1)));

const xAt = (i: number) => CHART.padL + i * xStep.value;
const yAt = (v: number) => CHART.padT + plotH.value * (1 - v / yMax.value);

// Y 轴网格线 + 刻度值（4 等分）
const yTicks = computed(() =>
  Array.from({ length: 5 }, (_, i) => ({
    y: CHART.padT + (plotH.value * i) / 4,
    label: String(Math.round(yMax.value * (1 - i / 4))),
  })),
);

// 三条折线的 points 串
const seriesPaths = computed(() =>
  seriesDefs.map((s) => ({
    ...s,
    points: trend.value
      .map((p, i) => {
        const v = (p as unknown as Record<string, number>)[s.key] ?? 0;
        return `${xAt(i).toFixed(1)},${yAt(v).toFixed(1)}`;
      })
      .join(' '),
  })),
);

// X 轴日期标签：点多时抽稀，末尾强制显示
const xLabels = computed(() => {
  const n = trend.value.length;
  const step = n <= 10 ? 1 : Math.ceil(n / 10);
  return trend.value.map((p, i) => ({
    x: xAt(i),
    label: p.date.slice(5), // MM-DD
    show: i % step === 0 || i === n - 1,
  }));
});

async function loadTrend() {
  trendLoading.value = true;
  try {
    trend.value = await reportApi.trend(trendDays.value);
  } finally {
    trendLoading.value = false;
  }
}

const cards = ref<{ label: string; value: string }[]>([
  { label: '今日拨打', value: '0' },
  { label: '今日接通率', value: '0%' },
  { label: '今日加客户率', value: '0%' },
  { label: '历史总通话', value: '0' },
  { label: '今日空号', value: '0' },
  { label: '今日未接通', value: '0' },
  { label: '今日加客户', value: '0' },
  { label: '今日平均时长', value: '0秒' },
]);

function fmtDur(s: number) {
  if (!s) return '-';
  const m = Math.floor(s / 60);
  const sec = s % 60;
  return m > 0 ? `${m}分${sec}秒` : `${sec}秒`;
}

async function load() {
  loading.value = true;
  try {
    const o: ReportOverview = await reportApi.overview();
    overview.value = o;
    cards.value = [
      { label: '今日拨打', value: String(o.todayCalled) },
      { label: '今日接通率', value: o.todayConnectRate },
      { label: '今日加客户率', value: o.todayConvertRate },
      { label: '历史总通话', value: String(o.totalCalled) },
      { label: '今日空号', value: String(o.todayEmpty) },
      { label: '今日未接通', value: String(o.todayNotAnswered) },
      { label: '今日加客户', value: String(o.todayAddCustomer) },
      { label: '今日平均时长', value: fmtDur(o.todayAvgDuration) },
    ];
    rows.value = await reportApi.team();
  } finally {
    loading.value = false;
  }
}

onMounted(async () => {
  await load();
  await loadTrend();
});
</script>

<style scoped>
.num { font-size: 28px; font-weight: bold; color: #21c17a; }
.label { color: #999; margin-top: 4px; }
.trend-head { display: flex; align-items: center; justify-content: space-between; }
.chart-wrap { width: 100%; }
.trend-svg { width: 100%; height: auto; }
.axis-text { font-size: 11px; fill: #999; }
.legend { display: flex; justify-content: center; gap: 20px; margin-top: 8px; }
.legend-item { font-size: 12px; color: #666; display: inline-flex; align-items: center; gap: 6px; }
.legend-item i { width: 10px; height: 10px; border-radius: 2px; display: inline-block; }
</style>
