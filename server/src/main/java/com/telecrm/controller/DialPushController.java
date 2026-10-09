package com.telecrm.controller;

import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.entity.DialPushItem;
import com.telecrm.entity.DialPushTask;
import com.telecrm.service.DialPushService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 云端自动外呼接口
 *
 * 电脑端（管理后台）：建任务 / 控制（开始、暂停、继续、结束）/ 看进度
 * 手机端（App）：轮询取号 / 上报结果
 *
 * 设计：后端是「大脑」，手机只是「执行器」。
 * 顺序、间隔秒数、暂停全部由后端决定，手机每轮都来问一次，
 * 所以电脑上一改，手机下一轮立刻生效。
 */
@RestController
@RequestMapping("/api/dial-push")
public class DialPushController {

    @Resource
    private DialPushService dialPushService;

    // ============ 电脑端 ============

    /** 新建外呼任务 */
    @PostMapping("/create")
    public Result<DialPushTask> create(@RequestBody Map<String, Object> body) {
        String scope = str(body.get("scope"), "mine");
        String keyword = str(body.get("keyword"), "");
        String name = str(body.get("name"), "");
        Long startCustomerId = lng(body.get("startCustomerId"));
        Integer limit = intg(body.get("limit"));
        Integer intervalSeconds = intg(body.get("intervalSeconds"));
        Long targetUserId = lng(body.get("targetUserId"));
        if (intervalSeconds == null) intervalSeconds = 15;
        return Result.success(dialPushService.create(
                scope, keyword, startCustomerId, limit, intervalSeconds, targetUserId, name));
    }

    /** 任务列表 */
    @GetMapping("/list")
    public Result<List<DialPushTask>> list() {
        return Result.success(dialPushService.listTasks());
    }

    /** 任务详情 */
    @GetMapping("/{id}")
    public Result<DialPushTask> detail(@PathVariable Long id) {
        return Result.success(dialPushService.task(id));
    }

    /** 任务进度（电脑端每 2 秒刷一次） */
    @GetMapping("/{id}/progress")
    public Result<Map<String, Object>> progress(@PathVariable Long id) {
        return Result.success(dialPushService.progress(id));
    }

    /** 任务明细 */
    @GetMapping("/{id}/items")
    public Result<List<DialPushItem>> items(@PathVariable Long id) {
        return Result.success(dialPushService.items(id));
    }

    /** 控制：start / pause / resume / stop / cancel */
    @PostMapping("/{id}/control")
    public Result<Map<String, Object>> control(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        String action = str(body.get("action"), "start");
        dialPushService.control(id, action);
        Map<String, Object> m = new HashMap<>();
        m.put("id", id);
        m.put("action", action);
        return Result.success(m);
    }

    /** 跳过某一条 */
    @PostMapping("/{id}/skip")
    public Result<Map<String, Object>> skip(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long itemId = lng(body.get("itemId"));
        if (itemId == null) return Result.fail("缺少 itemId");
        dialPushService.skip(id, itemId);
        Map<String, Object> m = new HashMap<>();
        m.put("itemId", itemId);
        return Result.success(m);
    }

    /** 删除任务 */
    @DeleteMapping("/{id}")
    public Result<Map<String, Object>> remove(@PathVariable Long id) {
        dialPushService.remove(id);
        Map<String, Object> m = new HashMap<>();
        m.put("id", id);
        return Result.success(m);
    }

    // ============ 手机端 ============

    /**
     * 手机轮询：现在该拨谁？
     * 返回 status: none(无任务) / paused(已暂停) / wait(间隔等待) / dial(该拨号) / finished(已拨完)
     */
    @GetMapping("/next")
    public Result<Map<String, Object>> next() {
        Map<String, Object> r = dialPushService.next(UserContext.getUserId());
        // 手机端配合处理「已暂停」：任务存在但被暂停
        if ("none".equals(r.get("status"))) {
            Long pausedId = dialPushService.findPausedTaskId(UserContext.getTeamId(), UserContext.getUserId());
            if (pausedId != null) {
                r.put("status", "paused");
                r.put("taskId", pausedId);
            }
        }
        return Result.success(r);
    }

    /** 手机上报通话结果 */
    @PostMapping("/report")
    public Result<Map<String, Object>> report(@RequestBody Map<String, Object> body) {
        Long taskId = lng(body.get("taskId"));
        Long itemId = lng(body.get("itemId"));
        String result = str(body.get("result"), "");
        Integer duration = intg(body.get("duration"));
        String remark = str(body.get("remark"), "");
        if (taskId == null || itemId == null) return Result.fail("缺少 taskId 或 itemId");
        dialPushService.report(taskId, itemId, result, duration == null ? 0 : duration,
                remark, UserContext.getUserId());
        Map<String, Object> m = new HashMap<>();
        m.put("itemId", itemId);
        return Result.success(m);
    }

    /** 手机放弃当前这条（退回队列，让别人/下一轮再拨） */
    @PostMapping("/release")
    public Result<Map<String, Object>> release(@RequestBody Map<String, Object> body) {
        Long taskId = lng(body.get("taskId"));
        Long itemId = lng(body.get("itemId"));
        if (taskId == null || itemId == null) return Result.fail("缺少 taskId 或 itemId");
        dialPushService.release(taskId, itemId, UserContext.getUserId());
        Map<String, Object> m = new HashMap<>();
        m.put("itemId", itemId);
        return Result.success(m);
    }

    // ---------- 工具 ----------

    private String str(Object v, String def) {
        return v == null ? def : String.valueOf(v);
    }

    private Long lng(Object v) {
        if (v == null) return null;
        if (v instanceof Number n) return n.longValue();
        String s = String.valueOf(v).trim();
        if (s.isEmpty()) return null;
        try {
            return Long.parseLong(s);
        } catch (Exception e) {
            return null;
        }
    }

    private Integer intg(Object v) {
        if (v == null) return null;
        if (v instanceof Number n) return n.intValue();
        try {
            return Integer.parseInt(String.valueOf(v).trim());
        } catch (Exception e) {
            return null;
        }
    }
}
