package com.telecrm.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.telecrm.common.UserContext;
import com.telecrm.entity.CallRecord;
import com.telecrm.entity.Customer;
import com.telecrm.entity.CustomerProfile;
import com.telecrm.mapper.CallRecordMapper;
import com.telecrm.service.CustomerService;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * 数据导出：客户 / 通话记录，导出为 Excel（.xlsx）
 * 导出结果遵循当前登录人的数据权限（mine 只看自己，team 看团队）
 */
@RestController
@RequestMapping("/api/export")
public class ExportController {

    /** 单次导出的最大行数，防止误操作拖垮服务 */
    private static final long MAX_ROWS = 20000;
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Resource
    private CustomerService customerService;
    @Resource
    private CallRecordMapper recordMapper;

    /** 取画像（不存在则建空画像，保证导出列数一致） */
    private CustomerProfile profileOf(Long customerId) {
        try {
            return customerService.getProfile(customerId);
        } catch (Exception e) {
            CustomerProfile empty = new CustomerProfile();
            empty.setCustomerId(customerId);
            return empty;
        }
    }

    /** 导出客户 */
    @GetMapping("/customers")
    public void customers(@RequestParam(defaultValue = "mine") String scope,
                          @RequestParam(required = false) String keyword,
                          HttpServletResponse response) throws IOException {
        List<Customer> rows = new ArrayList<>();
        long current = 1;
        while (rows.size() < MAX_ROWS) {
            IPage<Customer> page = customerService.pageList(
                    scope, UserContext.getTeamId(), UserContext.getUserId(), keyword, current, 500);
            List<Customer> recs = page.getRecords();
            rows.addAll(recs);
            if (recs.size() < 500 || rows.size() >= page.getTotal() || current > 100) {
                break;
            }
            current++;
        }

        String[] headers = {"客户ID", "姓名", "手机号", "公司", "地址", "来源", "状态", "标签", "备注", "归属销售ID",
                "性别", "年龄", "行业", "职位", "微信", "邮箱", "备用电话", "省份", "城市",
                "意向等级", "预算", "决策人", "来源渠道", "感兴趣产品", "客户痛点", "在用竞品",
                "累计拨打", "最近拨打", "画像标签", "画像小结"};
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("客户");
            fillHeader(sheet, headers);
            int r = 1;
            for (Customer c : rows) {
                CustomerProfile p = profileOf(c.getId());
                Row row = sheet.createRow(r++);
                put(row, 0, c.getId());
                put(row, 1, c.getName());
                put(row, 2, c.getPhone());
                put(row, 3, c.getCompany());
                put(row, 4, c.getAddress());
                put(row, 5, c.getSource());
                put(row, 6, statusText(c.getStatus()));
                put(row, 7, c.getTags());
                put(row, 8, c.getRemark());
                put(row, 9, c.getOwnerUserId());
                put(row, 10, p.getGender());
                put(row, 11, p.getAge());
                put(row, 12, p.getIndustry());
                put(row, 13, p.getPosition());
                put(row, 14, p.getWechat());
                put(row, 15, p.getEmail());
                put(row, 16, p.getSecondPhone());
                put(row, 17, p.getProvince());
                put(row, 18, p.getCity());
                put(row, 19, p.getIntentLevel());
                put(row, 20, p.getBudget());
                put(row, 21, p.getIsDecision() != null && p.getIsDecision() == 1 ? "是" : "否");
                put(row, 22, p.getChannel());
                put(row, 23, p.getProductInterest());
                put(row, 24, p.getPainPoint());
                put(row, 25, p.getCompetitor());
                put(row, 26, p.getCallCount());
                put(row, 27, p.getLastCalledAt() == null ? "" : p.getLastCalledAt().format(FMT));
                put(row, 28, p.getProfileTags());
                put(row, 29, p.getSummary());
            }
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            write(response, wb, "客户导出");
        }
    }

    /** 导出通话记录 */
    @GetMapping("/call-records")
    public void callRecords(@RequestParam(defaultValue = "mine") String scope,
                            @RequestParam(required = false) String result,
                            HttpServletResponse response) throws IOException {
        LambdaQueryWrapper<CallRecord> w = new LambdaQueryWrapper<>();
        if ("team".equals(scope)) {
            w.eq(CallRecord::getTeamId, UserContext.getTeamId());
        } else {
            w.eq(CallRecord::getUserId, UserContext.getUserId());
        }
        if (result != null && !result.isBlank()) {
            // 与话单列表保持一致：前端用的是展示型枚举值
            String r = switch (result) {
                case "not_answered" -> "no_answer";
                case "add_customer" -> "follow_up";
                default -> result;
            };
            w.eq(CallRecord::getResult, r);
        }
        w.orderByDesc(CallRecord::getCalledAt).last("LIMIT " + MAX_ROWS);
        List<CallRecord> rows = recordMapper.selectList(w);

        String[] headers = {"记录ID", "通话时间", "手机号", "客户ID", "时长(秒)", "通话结果", "标签", "备注", "录音"};
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("通话记录");
            fillHeader(sheet, headers);
            int r = 1;
            for (CallRecord c : rows) {
                Row row = sheet.createRow(r++);
                put(row, 0, c.getId());
                put(row, 1, c.getCalledAt() == null ? "" : FMT.format(c.getCalledAt()));
                put(row, 2, c.getPhone());
                put(row, 3, c.getCustomerId());
                put(row, 4, c.getDuration());
                put(row, 5, resultText(c.getResult()));
                put(row, 6, c.getTag());
                put(row, 7, c.getRemark());
                put(row, 8, c.getRecordingUrl());
            }
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            write(response, wb, "通话记录导出");
        }
    }

    // ------------------------------------------------------------------ 工具

    private static void fillHeader(Sheet sheet, String[] headers) {
        Row head = sheet.createRow(0);
        for (int i = 0; i < headers.length; i++) {
            Cell cell = head.createCell(i);
            cell.setCellValue(headers[i]);
        }
    }

    private static void put(Row row, int idx, Object value) {
        Cell cell = row.createCell(idx);
        if (value == null) {
            cell.setBlank();
            return;
        }
        if (value instanceof Number n) {
            cell.setCellValue(n.doubleValue());
        } else {
            cell.setCellValue(String.valueOf(value));
        }
    }

    private static void write(HttpServletResponse response, XSSFWorkbook wb, String name) throws IOException {
        String filename = name + "_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmm"))
                + ".xlsx";
        String encoded = URLEncoder.encode(filename, StandardCharsets.UTF_8).replace("+", "%20");
        response.reset();
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition",
                "attachment; filename=\"" + encoded + "\"; filename*=UTF-8''" + encoded);
        wb.write(response.getOutputStream());
        response.flushBuffer();
    }

    /** 客户状态文案（与前端 customer 页保持一致） */
    private static String statusText(String status) {
        if (status == null) return "";
        return switch (status) {
            case "normal" -> "正常";
            case "follow_up" -> "跟进中";
            case "dead" -> "无效";
            case "public" -> "公海";
            default -> status;
        };
    }

    /** 通话结果文案（与前端 records 页保持一致） */
    private static String resultText(String result) {
        if (result == null) return "";
        return switch (result) {
            case "connected" -> "已接通";
            case "not_answered" -> "未接通";
            case "empty" -> "空号";
            case "add_customer" -> "添加客户";
            case "follow_up" -> "跟进";
            case "no_answer" -> "未接通";
            case "rejected" -> "拒接";
            case "busy" -> "占线";
            case "shutdown" -> "关机";
            default -> result;
        };
    }
}
