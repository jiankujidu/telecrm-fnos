package com.telecrm.service;

import java.util.List;
import java.util.Map;

/**
 * 报表统计服务：团队概览 + 成员维度
 */
public interface ReportService {

    /** 团队概览：今日拨打/接通/有效客户/客户总数/成员数/任务数 */
    Map<String, Object> overview(Long teamId);

    /** 成员维度报表：拨打/接通/有效 */
    List<Map<String, Object>> teamReport(Long teamId);

    /** 趋势统计：按日聚合拨打/接通/加客户 */
    List<Map<String, Object>> trend(Long teamId, int days);
}
