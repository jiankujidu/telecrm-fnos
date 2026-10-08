package com.telecrm.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.telecrm.common.PageResult;
import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.entity.Customer;
import com.telecrm.entity.CustomerProfile;
import com.telecrm.service.CustomerService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 客户接口：我的客户 / 团队客户 / 客户库(公海) + 增删改 + 流转 + 画像
 */
@RestController
@RequestMapping("/api/customer")
public class CustomerController {

    @Resource
    private CustomerService customerService;

    @Resource
    private org.springframework.jdbc.core.JdbcTemplate jdbc;

    @GetMapping("/list")
    public Result<PageResult<Customer>> list(
            @RequestParam(defaultValue = "mine") String scope,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "20") long size) {
        IPage<Customer> page = customerService.pageList(
                scope, UserContext.getTeamId(), UserContext.getUserId(), keyword, current, size);
        return Result.success(new PageResult<>(
                page.getRecords(), page.getTotal(), page.getSize(), page.getCurrent()));
    }

    /** 新建客户 */
    @PostMapping("/create")
    public Result<Customer> create(@RequestBody Customer body) {
        if (body.getTeamId() == null) body.setTeamId(UserContext.getTeamId());
        return Result.success(customerService.create(body));
    }

    /** 编辑客户（null 字段不覆盖） */
    @PostMapping("/update")
    public Result<Customer> update(@RequestBody Customer body) {
        return Result.success(customerService.updateCustomer(body.getId(), body));
    }

    /** 删除客户 */
    @PostMapping("/delete")
    public Result<Map<String, Object>> delete(@RequestBody Map<String, Object> body) {
        Object idObj = body.get("id");
        if (idObj != null) {
            customerService.deleteCustomer(Long.valueOf(String.valueOf(idObj)));
            return Result.success(Map.of("count", 1));
        }
        @SuppressWarnings("unchecked")
        List<Object> ids = (List<Object>) body.get("ids");
        int n = 0;
        if (ids != null) {
            List<Long> longs = new ArrayList<>();
            for (Object o : ids) longs.add(Long.valueOf(String.valueOf(o)));
            n = customerService.batchDelete(longs);
        }
        Map<String, Object> r = new HashMap<>();
        r.put("count", n);
        return Result.success(r);
    }

    @PostMapping("/transfer")
    public Result<Void> transfer(@RequestBody Map<String, Long> body) {
        customerService.transfer(body.get("customerId"), body.get("toUserId"), UserContext.getUserId());
        return Result.success();
    }

    @PostMapping("/assign")
    public Result<Void> assign(@RequestBody Map<String, Long> body) {
        customerService.assign(body.get("customerId"), body.get("toUserId"), UserContext.getUserId());
        return Result.success();
    }

    @PostMapping("/abandon")
    public Result<Void> abandon(@RequestBody Map<String, Long> body) {
        customerService.abandon(body.get("customerId"), UserContext.getUserId());
        return Result.success();
    }

    /** 客户详情：基本信息（供移动端/后台详情页） */
    @GetMapping("/{id}")
    public Result<Customer> detail(@PathVariable Long id) {
        Customer c = customerService.getById(id);
        return Result.success(c);
    }

    // ---------- 客户画像 ----------

    /** 读取画像（无则自动建空画像） */
    @GetMapping("/{id}/profile")
    public Result<CustomerProfile> getProfile(@PathVariable Long id) {
        return Result.success(customerService.getProfile(id));
    }

    /** 保存画像 */
    @PostMapping("/{id}/profile")
    public Result<CustomerProfile> saveProfile(@PathVariable Long id, @RequestBody CustomerProfile p) {
        return Result.success(customerService.saveProfile(id, p));
    }

    /**
     * 批量取画像，供列表页合并展示
     * GET /api/customer/profiles?ids=1,2,3
     */
    @GetMapping("/profiles")
    public Result<Map<Long, CustomerProfile>> profiles(@RequestParam String ids) {
        List<Long> list = new ArrayList<>();
        for (String s : ids.split(",")) {
            String t = s.trim();
            if (!t.isEmpty()) list.add(Long.valueOf(t));
        }
        return Result.success(customerService.profileMap(list));
    }

    /**
     * 画像表：客户 + 画像 联表分页，供「客户画像」页使用
     * GET /api/customer/profile/list?scope=&keyword=&intentLevel=&current=&size=
     */
    @GetMapping("/profile/list")
    public Result<PageResult<Map<String, Object>>> profileList(
            @RequestParam(defaultValue = "mine") String scope,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String intentLevel,
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "20") long size) {
        StringBuilder where = new StringBuilder(" WHERE c.deleted = 0 AND c.team_id = ? ");
        List<Object> args = new ArrayList<>();
        args.add(UserContext.getTeamId());
        if ("mine".equals(scope)) {
            where.append(" AND c.owner_user_id = ? ");
            args.add(UserContext.getUserId());
        } else if ("team".equals(scope)) {
            where.append(" AND c.owner_user_id IS NOT NULL ");
        } else {
            where.append(" AND c.owner_user_id IS NULL ");
        }
        if (keyword != null && !keyword.isBlank()) {
            where.append(" AND (c.name LIKE ? OR c.phone LIKE ? OR c.company LIKE ?) ");
            String k = "%" + keyword.trim() + "%";
            args.add(k); args.add(k); args.add(k);
        }
        if (intentLevel != null && !intentLevel.isBlank()) {
            where.append(" AND p.intent_level = ? ");
            args.add(intentLevel.trim());
        }

        String cols = "c.id AS id, c.name AS name, c.phone AS phone, c.company AS company,"
                + " c.tags AS tags, c.status AS status, c.owner_user_id AS ownerUserId,"
                + " p.id AS profileId, p.gender AS gender, p.age AS age, p.industry AS industry,"
                + " p.position AS position, p.wechat AS wechat, p.email AS email,"
                + " p.second_phone AS secondPhone, p.intent_level AS intentLevel, p.budget AS budget,"
                + " p.is_decision AS isDecision, p.channel AS channel,"
                + " p.product_interest AS productInterest, p.pain_point AS painPoint,"
                + " p.competitor AS competitor, p.next_follow_at AS nextFollowAt,"
                + " p.call_count AS callCount, p.last_called_at AS lastCalledAt,"
                + " p.profile_tags AS profileTags, p.summary AS summary";
        String from = " FROM customer c LEFT JOIN customer_profile p"
                + " ON p.customer_id = c.id AND p.deleted = 0 ";

        Long total = jdbc.queryForObject("SELECT COUNT(*) " + from + where, Long.class, args.toArray());
        long offset = Math.max(0, (current - 1) * size);
        String sql = "SELECT " + cols + from + where + " ORDER BY c.created_at DESC LIMIT ? OFFSET ?";
        List<Object> pageArgs = new ArrayList<>(args);
        pageArgs.add(size);
        pageArgs.add(offset);

        List<Map<String, Object>> rows = jdbc.queryForList(sql, pageArgs.toArray());
        List<Map<String, Object>> norm = new ArrayList<>(rows.size());
        for (Map<String, Object> r : rows) {
            Map<String, Object> m = new LinkedHashMap<>();
            r.forEach((k, v) -> m.put(k, v instanceof java.time.LocalDateTime
                    ? ((java.time.LocalDateTime) v).format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
                    : v));
            norm.add(m);
        }
        return Result.success(new PageResult<>(norm, total == null ? 0 : total, size, current));
    }

    /** 拨打后累计（App 拨号成功后调用） */
    @PostMapping("/{id}/touch-call")
    public Result<CustomerProfile> touchCall(@PathVariable Long id) {
        customerService.touchCall(id);
        return Result.success(customerService.getProfile(id));
    }
}
