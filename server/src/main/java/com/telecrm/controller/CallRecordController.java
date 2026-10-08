package com.telecrm.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.telecrm.common.BusinessException;
import com.telecrm.common.PageResult;
import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.dto.CallRecordDTO;
import com.telecrm.entity.CallRecord;
import com.telecrm.entity.CallTask;
import com.telecrm.entity.CallTaskItem;
import com.telecrm.mapper.CallRecordMapper;
import com.telecrm.mapper.CallTaskItemMapper;
import com.telecrm.mapper.CallTaskMapper;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 通话记录接口：写入拨打结果并联动更新任务统计
 */
@RestController
@RequestMapping("/api/call-record")
public class CallRecordController {

    @Resource
    private CallRecordMapper recordMapper;
    @Resource
    private CallTaskItemMapper itemMapper;
    @Resource
    private CallTaskMapper taskMapper;

    @PostMapping
    public Result<Void> add(@RequestBody CallRecordDTO dto) {
        CallRecord r = new CallRecord();
        r.setTeamId(UserContext.getTeamId());
        r.setTaskItemId(dto.getTaskItemId());
        r.setUserId(UserContext.getUserId());
        r.setCustomerId(dto.getCustomerId());
        r.setPhone(dto.getPhone());
        r.setDuration(dto.getDuration() == null ? 0 : dto.getDuration());
        r.setResult(dto.getResult());
        r.setRemark(dto.getRemark());
        r.setTag(dto.getTag());
        r.setCalledAt(LocalDateTime.now());
        recordMapper.insert(r);

        // 联动更新任务明细与任务统计
        if (dto.getTaskItemId() != null) {
            CallTaskItem item = itemMapper.selectById(dto.getTaskItemId());
            if (item != null) {
                item.setCallResult(dto.getResult());
                item.setStatus(mapStatus(dto.getResult()));
                item.setCallCount((item.getCallCount() == null ? 0 : item.getCallCount()) + 1);
                item.setLastCallAt(LocalDateTime.now());
                itemMapper.updateById(item);

                CallTask task = taskMapper.selectById(item.getTaskId());
                if (task != null) {
                    task.setCalledCount((task.getCalledCount() == null ? 0 : task.getCalledCount()) + 1);
                    if ("add_customer".equals(dto.getResult()) || "connected".equals(dto.getResult())) {
                        task.setValidCount((task.getValidCount() == null ? 0 : task.getValidCount()) + 1);
                    }
                    taskMapper.updateById(task);
                }
            }
        }
        return Result.success();
    }

    private String mapStatus(String result) {
        if (result == null) return "called";
        return switch (result) {
            case "empty" -> "invalid";
            case "not_answered" -> "no_answer";
            case "add_customer" -> "follow_up";
            default -> "called";
        };
    }

    /** 通话记录/话单列表（分页，支持 mine/team 与结果筛选） */
    @GetMapping("/list")
    public Result<PageResult<CallRecord>> list(
            @RequestParam(defaultValue = "mine") String scope,
            @RequestParam(required = false) String result,
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "20") long size) {
        LambdaQueryWrapper<CallRecord> w = new LambdaQueryWrapper<>();
        if ("team".equals(scope)) {
            w.eq(CallRecord::getTeamId, UserContext.getTeamId());
        } else {
            w.eq(CallRecord::getUserId, UserContext.getUserId());
        }
        if (result != null && !result.isBlank()) {
            w.eq(CallRecord::getResult, result);
        }
        w.orderByDesc(CallRecord::getCalledAt);
        Page<CallRecord> page = new Page<>(current, size);
        Page<CallRecord> res = recordMapper.selectPage(page, w);
        return Result.success(new PageResult<>(
                res.getRecords(), res.getTotal(), res.getSize(), res.getCurrent()));
    }

    /** 关联通话录音：上传后回填录音 URL */
    @PostMapping("/{id}/recording")
    public Result<Void> attachRecording(@PathVariable Long id,
                                        @RequestBody Map<String, String> body) {
        CallRecord r = recordMapper.selectById(id);
        if (r == null) throw new BusinessException("通话记录不存在");
        r.setRecordingUrl(body.get("recordingUrl"));
        recordMapper.updateById(r);
        return Result.success();
    }

    /** 某客户的通话记录（详情页用，最近 50 条） */
    @GetMapping("/by-customer")
    public Result<List<CallRecord>> byCustomer(@RequestParam Long customerId) {
        LambdaQueryWrapper<CallRecord> w = new LambdaQueryWrapper<>();
        w.eq(CallRecord::getCustomerId, customerId);
        w.orderByDesc(CallRecord::getCalledAt);
        w.last("LIMIT 50");
        return Result.success(recordMapper.selectList(w));
    }
}
