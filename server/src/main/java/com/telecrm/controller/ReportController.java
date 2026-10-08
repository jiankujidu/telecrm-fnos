package com.telecrm.controller;

import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.service.ReportService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 报表统计接口
 */
@RestController
@RequestMapping("/api/report")
public class ReportController {

    @Resource
    private ReportService reportService;

    /** 团队概览看板 */
    @GetMapping("/overview")
    public Result<Map<String, Object>> overview() {
        return Result.success(reportService.overview(UserContext.getTeamId()));
    }

    /** 成员维度报表 */
    @GetMapping("/team")
    public Result<List<Map<String, Object>>> teamReport() {
        return Result.success(reportService.teamReport(UserContext.getTeamId()));
    }

    /** 趋势统计：按日聚合拨打/接通/加客户 */
    @GetMapping("/trend")
    public Result<List<Map<String, Object>>> trend(@RequestParam(defaultValue = "7") int days) {
        return Result.success(reportService.trend(UserContext.getTeamId(), days));
    }
}
