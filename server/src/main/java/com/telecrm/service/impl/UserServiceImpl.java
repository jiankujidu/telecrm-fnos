package com.telecrm.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.telecrm.common.BusinessException;
import com.telecrm.common.UserContext;
import com.telecrm.entity.Team;
import com.telecrm.entity.TeamMember;
import com.telecrm.entity.User;
import com.telecrm.mapper.TeamMapper;
import com.telecrm.mapper.TeamMemberMapper;
import com.telecrm.mapper.UserMapper;
import com.telecrm.service.UserService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import jakarta.annotation.Resource;
import java.util.regex.Pattern;

/**
 * 用户服务实现
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");

    @Resource
    private PasswordEncoder passwordEncoder;
    @Resource
    private TeamMapper teamMapper;
    @Resource
    private TeamMemberMapper teamMemberMapper;

    @Override
    public User login(String phone, String password) {
        User user = lambdaQuery().eq(User::getPhone, phone).one();
        if (user == null || !passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new BusinessException("账号不存在或密码错误");
        }
        if (user.getStatus() != null && user.getStatus() == 1) {
            throw new BusinessException("账号已被禁用");
        }
        return user;
    }

    @Override
    public User register(User user) {
        String phone = user.getPhone();
        if (phone == null || !PHONE_PATTERN.matcher(phone).matches()) {
            throw new BusinessException("手机号格式不正确");
        }
        if (lambdaQuery().eq(User::getPhone, phone).count() > 0) {
            throw new BusinessException("手机号已注册");
        }
        String raw = user.getPasswordHash(); // 约定：入参此处为明文密码
        if (raw == null || raw.length() < 6) {
            throw new BusinessException("密码至少6位");
        }
        user.setPasswordHash(passwordEncoder.encode(raw));
        user.setNickname(user.getNickname() == null ? phone : user.getNickname());
        user.setStatus(0);
        save(user); // ASSIGN_ID 自动回填主键

        // 注册即创建默认团队
        Team team = new Team();
        team.setName(user.getNickname() + "的团队");
        team.setOwnerUserId(user.getId());
        team.setInviteCode(generateInviteCode());
        team.setMaxSeats(50);
        team.setStatus(0);
        teamMapper.insert(team);

        TeamMember tm = new TeamMember();
        tm.setTeamId(team.getId());
        tm.setUserId(user.getId());
        tm.setRole("owner");
        tm.setNickname(user.getNickname());
        tm.setStatus(0);
        teamMemberMapper.insert(tm);

        user.setCurrentTeamId(team.getId());
        updateById(user);
        return user;
    }

    /** 当前登录用户ID（来自JWT拦截器上下文） */
    protected Long currentUserId() {
        return UserContext.getUserId();
    }

    /** 当前团队ID */
    protected Long currentTeamId() {
        return UserContext.getTeamId();
    }

    private String generateInviteCode() {
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 6; i++) {
            sb.append(chars.charAt((int) (Math.random() * chars.length())));
        }
        return sb.toString();
    }
}
