package com.telecrm.controller;

import com.telecrm.common.Result;
import com.telecrm.common.JwtUtil;
import com.telecrm.entity.User;
import com.telecrm.service.UserService;
import org.springframework.web.bind.annotation.*;

import jakarta.annotation.Resource;
import java.util.Map;

/**
 * 鉴权接口：登录/注册/退出（骨架）
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Resource
    private UserService userService;

    @Resource
    private JwtUtil jwtUtil;

    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        String phone = body.get("phone");
        String password = body.get("password");
        User user = userService.login(phone, password);
        String token = jwtUtil.generateToken(user.getId(), user.getCurrentTeamId());
        return Result.success(Map.of("token", token, "user", user));
    }

    @PostMapping("/register")
    public Result<User> register(@RequestBody User user) {
        return Result.success(userService.register(user));
    }
}
