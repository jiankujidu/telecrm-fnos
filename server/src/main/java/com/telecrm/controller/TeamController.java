package com.telecrm.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.telecrm.common.BusinessException;
import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.entity.TeamMember;
import com.telecrm.entity.User;
import com.telecrm.mapper.TeamMemberMapper;
import com.telecrm.mapper.UserMapper;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 团队接口：成员管理
 */
@RestController
@RequestMapping("/api/team")
public class TeamController {

    @Resource
    private TeamMemberMapper teamMemberMapper;
    @Resource
    private UserMapper userMapper;

    @GetMapping("/members")
    public Result<List<Map<String, Object>>> members() {
        Long teamId = UserContext.getTeamId();
        List<TeamMember> list = teamMemberMapper.selectList(new LambdaQueryWrapper<TeamMember>()
                .eq(TeamMember::getTeamId, teamId)
                .eq(TeamMember::getStatus, 0));
        List<Map<String, Object>> vo = list.stream().map(m -> {
            Map<String, Object> map = new HashMap<>();
            User u = userMapper.selectById(m.getUserId());
            map.put("userId", m.getUserId());
            map.put("nickname", m.getNickname());
            map.put("role", m.getRole());
            map.put("phone", u == null ? "" : maskPhone(u.getPhone()));
            return map;
        }).collect(Collectors.toList());
        return Result.success(vo);
    }

    @PostMapping("/member")
    public Result<Void> add(@RequestBody Map<String, String> body) {
        Long teamId = UserContext.getTeamId();
        String phone = body.get("phone");
        User u = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getPhone, phone));
        if (u == null) throw new BusinessException("该手机号用户尚未注册");
        Long cnt = teamMemberMapper.selectCount(new LambdaQueryWrapper<TeamMember>()
                .eq(TeamMember::getTeamId, teamId)
                .eq(TeamMember::getUserId, u.getId()));
        if (cnt != null && cnt > 0) throw new BusinessException("该成员已在团队中");
        TeamMember tm = new TeamMember();
        tm.setTeamId(teamId);
        tm.setUserId(u.getId());
        tm.setRole(body.getOrDefault("role", "member"));
        tm.setNickname(body.getOrDefault("nickname", phone));
        tm.setStatus(0);
        teamMemberMapper.insert(tm);
        return Result.success();
    }

    @DeleteMapping("/member/{userId}")
    public Result<Void> remove(@PathVariable Long userId) {
        teamMemberMapper.delete(new LambdaQueryWrapper<TeamMember>()
                .eq(TeamMember::getTeamId, UserContext.getTeamId())
                .eq(TeamMember::getUserId, userId));
        return Result.success();
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) return phone;
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }
}
