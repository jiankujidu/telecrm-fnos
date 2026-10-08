package com.telecrm.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.telecrm.entity.CallRecord;
import com.telecrm.entity.CallTask;
import com.telecrm.entity.Customer;
import com.telecrm.entity.TeamMember;
import com.telecrm.mapper.CallRecordMapper;
import com.telecrm.mapper.CallTaskMapper;
import com.telecrm.mapper.CustomerMapper;
import com.telecrm.mapper.TeamMemberMapper;
import com.telecrm.mapper.UserMapper;
import com.telecrm.service.ReportService;
import org.springframework.stereotype.Service;

import jakarta.annotation.Resource;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 报表统计实现：团队概览 + 成员维度（含结果分布 / 接通率 / 转化率 / 平均时长）
 */
@Service
public class ReportServiceImpl implements ReportService {

    @Resource
    private CallRecordMapper callRecordMapper;
    @Resource
    private CustomerMapper customerMapper;
    @Resource
    private CallTaskMapper callTaskMapper;
    @Resource
    private TeamMemberMapper teamMemberMapper;
    @Resource
    private UserMapper userMapper;

    /** 接通口径：已接通 + 添加客户 */
    private static final List<String> CONNECTED = List.of("connected", "add_customer");
    /** 加客户口径：添加客户 */
    private static final String ADD_CUSTOMER = "add_customer";
    private static final String NOT_ANSWERED = "not_answered";
    private static final String EMPTY = "empty";

    @Override
    public Map<String, Object> overview(Long teamId) {
        LocalDateTime startOfToday = LocalDate.now().atStartOfDay();

        long todayCalled = countRecords(teamId, startOfToday, null);
        long todayConnected = countRecords(teamId, startOfToday, CONNECTED);
        long todayEmpty = countResult(teamId, startOfToday, EMPTY);
        long todayNotAnswered = countResult(teamId, startOfToday, NOT_ANSWERED);
        long todayAddCustomer = countResult(teamId, startOfToday, ADD_CUSTOMER);
        long totalCalled = callRecordMapper.selectCount(new LambdaQueryWrapper<CallRecord>()
                .eq(CallRecord::getTeamId, teamId));
        long todayAvgDuration = avgDuration(teamId, startOfToday);

        long validCustomers = customerMapper.selectCount(new LambdaQueryWrapper<Customer>()
                .eq(Customer::getTeamId, teamId).eq(Customer::getStatus, "follow_up"));
        long totalCustomers = customerMapper.selectCount(new LambdaQueryWrapper<Customer>()
                .eq(Customer::getTeamId, teamId));
        long totalMembers = teamMemberMapper.selectCount(new LambdaQueryWrapper<TeamMember>()
                .eq(TeamMember::getTeamId, teamId).eq(TeamMember::getStatus, 0));
        long totalTasks = callTaskMapper.selectCount(new LambdaQueryWrapper<CallTask>()
                .eq(CallTask::getTeamId, teamId));

        Map<String, Object> map = new HashMap<>();
        map.put("todayCalled", todayCalled);
        map.put("todayConnected", todayConnected);
        map.put("todayEmpty", todayEmpty);
        map.put("todayNotAnswered", todayNotAnswered);
        map.put("todayAddCustomer", todayAddCustomer);
        map.put("todayConnectRate", todayCalled == 0 ? "0%" : String.format("%.1f%%", todayConnected * 100.0 / todayCalled));
        map.put("todayConvertRate", todayCalled == 0 ? "0%" : String.format("%.1f%%", todayAddCustomer * 100.0 / todayCalled));
        map.put("todayAvgDuration", todayAvgDuration);
        map.put("totalCalled", totalCalled);
        map.put("validCustomers", validCustomers);
        map.put("totalCustomers", totalCustomers);
        map.put("totalMembers", totalMembers);
        map.put("totalTasks", totalTasks);
        return map;
    }

    @Override
    public List<Map<String, Object>> teamReport(Long teamId) {
        List<TeamMember> members = teamMemberMapper.selectList(new LambdaQueryWrapper<TeamMember>()
                .eq(TeamMember::getTeamId, teamId).eq(TeamMember::getStatus, 0));

        List<Map<String, Object>> rows = new ArrayList<>();
        for (TeamMember m : members) {
            Long userId = m.getUserId();
            long called = callRecordMapper.selectCount(new LambdaQueryWrapper<CallRecord>()
                    .eq(CallRecord::getTeamId, teamId).eq(CallRecord::getUserId, userId));
            long connected = callRecordMapper.selectCount(new LambdaQueryWrapper<CallRecord>()
                    .eq(CallRecord::getTeamId, teamId).eq(CallRecord::getUserId, userId).in(CallRecord::getResult, CONNECTED));
            long empty = countResultUser(teamId, userId, EMPTY);
            long notAnswered = countResultUser(teamId, userId, NOT_ANSWERED);
            long addCustomer = countResultUser(teamId, userId, ADD_CUSTOMER);
            long avgDuration = avgDurationUser(teamId, userId);

            Map<String, Object> row = new HashMap<>();
            row.put("userId", userId);
            row.put("nickname", m.getNickname());
            row.put("called", called);
            row.put("connected", connected);
            row.put("empty", empty);
            row.put("notAnswered", notAnswered);
            row.put("addCustomer", addCustomer);
            row.put("valid", addCustomer);
            row.put("rate", called == 0 ? "0%" : String.format("%.1f%%", connected * 100.0 / called));
            row.put("convertRate", called == 0 ? "0%" : String.format("%.1f%%", addCustomer * 100.0 / called));
            row.put("avgDuration", avgDuration);
            rows.add(row);
        }
        return rows;
    }

    @Override
    public List<Map<String, Object>> trend(Long teamId, int days) {
        int n = days <= 0 ? 7 : Math.min(days, 90);
        LocalDate start = LocalDate.now().minusDays(n - 1L);
        LocalDateTime startAt = start.atStartOfDay();

        // 一次性拉取范围内记录，按本地日期聚合，避免逐日查库
        List<CallRecord> records = callRecordMapper.selectList(new LambdaQueryWrapper<CallRecord>()
                .eq(CallRecord::getTeamId, teamId)
                .ge(CallRecord::getCalledAt, startAt)
                .select(CallRecord::getId, CallRecord::getCalledAt, CallRecord::getResult));

        Map<LocalDate, long[]> agg = new LinkedHashMap<>();
        for (int i = 0; i < n; i++) {
            agg.put(start.plusDays(i), new long[3]); // [called, connected, addCustomer]
        }
        for (CallRecord r : records) {
            if (r.getCalledAt() == null) continue;
            long[] arr = agg.get(r.getCalledAt().toLocalDate());
            if (arr == null) continue;
            arr[0]++;
            String res = r.getResult();
            if (CONNECTED.contains(res)) arr[1]++;
            if (ADD_CUSTOMER.equals(res)) arr[2]++;
        }

        List<Map<String, Object>> list = new ArrayList<>();
        for (Map.Entry<LocalDate, long[]> e : agg.entrySet()) {
            Map<String, Object> m = new HashMap<>();
            m.put("date", e.getKey().toString()); // yyyy-MM-dd
            m.put("called", e.getValue()[0]);
            m.put("connected", e.getValue()[1]);
            m.put("addCustomer", e.getValue()[2]);
            list.add(m);
        }
        return list;
    }

    private long countRecords(Long teamId, LocalDateTime since, List<String> results) {
        LambdaQueryWrapper<CallRecord> w = new LambdaQueryWrapper<CallRecord>()
                .eq(CallRecord::getTeamId, teamId).ge(CallRecord::getCalledAt, since);
        if (results != null) w.in(CallRecord::getResult, results);
        return callRecordMapper.selectCount(w);
    }

    private long countResult(Long teamId, LocalDateTime since, String result) {
        return callRecordMapper.selectCount(new LambdaQueryWrapper<CallRecord>()
                .eq(CallRecord::getTeamId, teamId).ge(CallRecord::getCalledAt, since).eq(CallRecord::getResult, result));
    }

    private long countResultUser(Long teamId, Long userId, String result) {
        return callRecordMapper.selectCount(new LambdaQueryWrapper<CallRecord>()
                .eq(CallRecord::getTeamId, teamId).eq(CallRecord::getUserId, userId).eq(CallRecord::getResult, result));
    }

    /** 今日/全量接通通话的平均时长（秒） */
    private long avgDuration(Long teamId, LocalDateTime since) {
        List<CallRecord> list = callRecordMapper.selectList(new LambdaQueryWrapper<CallRecord>()
                .eq(CallRecord::getTeamId, teamId).ge(CallRecord::getCalledAt, since)
                .in(CallRecord::getResult, CONNECTED).select(CallRecord::getDuration));
        if (list.isEmpty()) return 0;
        long sum = list.stream().mapToInt(c -> c.getDuration() == null ? 0 : c.getDuration()).sum();
        return sum / list.size();
    }

    private long avgDurationUser(Long teamId, Long userId) {
        List<CallRecord> list = callRecordMapper.selectList(new LambdaQueryWrapper<CallRecord>()
                .eq(CallRecord::getTeamId, teamId).eq(CallRecord::getUserId, userId)
                .in(CallRecord::getResult, CONNECTED).select(CallRecord::getDuration));
        if (list.isEmpty()) return 0;
        long sum = list.stream().mapToInt(c -> c.getDuration() == null ? 0 : c.getDuration()).sum();
        return sum / list.size();
    }
}
