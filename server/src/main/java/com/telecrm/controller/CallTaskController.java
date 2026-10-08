package com.telecrm.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.telecrm.common.PageResult;
import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.entity.CallTask;
import com.telecrm.entity.CallTaskItem;
import com.telecrm.service.CallTaskItemService;
import com.telecrm.dto.CreateTaskDTO;
import com.telecrm.service.CallTaskService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * 外呼任务接口
 */
@RestController
@RequestMapping("/api/call-task")
public class CallTaskController {

    @Resource
    private CallTaskService callTaskService;
    @Resource
    private CallTaskItemService itemService;

    /** 文件导入生成任务 */
    @PostMapping("/import")
    public Result<Long> importFile(@RequestParam("file") MultipartFile file,
                                   @RequestParam(required = false) String name,
                                   @RequestParam(required = false, defaultValue = "file") String sourceType) {
        Long taskId = callTaskService.importFile(
                file, name, sourceType, UserContext.getUserId(), UserContext.getTeamId());
        return Result.success(taskId);
    }

    /** 从联系人创建任务（拓客/附近企业加入拨打） */
    @PostMapping("/create")
    public Result<Long> create(@RequestBody CreateTaskDTO dto) {
        Long taskId = callTaskService.createFromContacts(
                dto.getItems(), dto.getName(), dto.getSourceType(),
                UserContext.getUserId(), UserContext.getTeamId());
        return Result.success(taskId);
    }

    /** 任务列表（分页） */
    @GetMapping("/list")
    public Result<PageResult<CallTask>> list(@RequestParam(defaultValue = "1") long current,
                                             @RequestParam(defaultValue = "20") long size) {
        Page<CallTask> page = new Page<>(current, size);
        Page<CallTask> res = callTaskService.page(page, new LambdaQueryWrapper<CallTask>()
                .eq(CallTask::getTeamId, UserContext.getTeamId())
                .orderByDesc(CallTask::getCreatedAt));
        return Result.success(new PageResult<>(res.getRecords(), res.getTotal(), res.getSize(), res.getCurrent()));
    }

    /** 任务明细（分页） */
    @GetMapping("/{id}/items")
    public Result<PageResult<CallTaskItem>> items(@PathVariable Long id,
                                                  @RequestParam(defaultValue = "1") long current,
                                                  @RequestParam(defaultValue = "50") long size) {
        Page<CallTaskItem> page = new Page<>(current, size);
        Page<CallTaskItem> res = itemService.page(page, new LambdaQueryWrapper<CallTaskItem>()
                .eq(CallTaskItem::getTaskId, id)
                .orderByAsc(CallTaskItem::getId));
        return Result.success(new PageResult<>(res.getRecords(), res.getTotal(), res.getSize(), res.getCurrent()));
    }

    /** 删除任务 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        callTaskService.removeById(id);
        return Result.success();
    }
}
