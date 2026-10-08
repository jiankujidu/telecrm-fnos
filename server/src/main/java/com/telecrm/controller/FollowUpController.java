package com.telecrm.controller;

import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.dto.FollowUpDTO;
import com.telecrm.dto.FollowUpVO;
import com.telecrm.service.FollowUpService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 跟进/回访接口：外呼标记后创建回访任务，支持按客户或本人查询
 */
@RestController
@RequestMapping("/api/follow-up")
public class FollowUpController {

    @Resource
    private FollowUpService followUpService;

    @PostMapping("/add")
    public Result<Long> add(@RequestBody FollowUpDTO dto) {
        com.telecrm.entity.FollowUp f =
                followUpService.add(UserContext.getUserId(), dto.getCustomerId(), dto.getContent(), dto.getTag());
        return Result.success(f.getId());
    }

    /** 列表：传 customerId 查该客户，否则查本人全部回访 */
    @GetMapping("/list")
    public Result<List<FollowUpVO>> list(@RequestParam(required = false) Long customerId) {
        Long userId = UserContext.getUserId();
        List<FollowUpVO> data = customerId != null
                ? followUpService.listByCustomer(customerId)
                : followUpService.listMine(userId);
        return Result.success(data);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        followUpService.remove(id, UserContext.getUserId());
        return Result.success();
    }
}
