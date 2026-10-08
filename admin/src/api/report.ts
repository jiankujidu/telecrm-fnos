import request from './request';

export interface ReportOverview {
  todayCalled: number;
  todayConnected: number;
  todayEmpty: number;
  todayNotAnswered: number;
  todayAddCustomer: number;
  todayConnectRate: string;
  todayConvertRate: string;
  todayAvgDuration: number;
  totalCalled: number;
  validCustomers: number;
  totalCustomers: number;
  totalMembers: number;
  totalTasks: number;
}

export interface ReportTeamRow {
  userId: number;
  nickname: string;
  called: number;
  connected: number;
  empty: number;
  notAnswered: number;
  addCustomer: number;
  valid: number;
  rate: string;
  convertRate: string;
  avgDuration: number;
}

export interface ReportTrendPoint {
  date: string; // yyyy-MM-dd
  called: number;
  connected: number;
  addCustomer: number;
}

export const reportApi = {
  overview: () => request.get('/report/overview'),
  team: () => request.get('/report/team'),
  trend: (days: number) => request.get('/report/trend', { params: { days } }),
};
