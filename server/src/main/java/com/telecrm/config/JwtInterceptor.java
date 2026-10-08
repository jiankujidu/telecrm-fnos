package com.telecrm.config;

import com.telecrm.common.JwtUtil;
import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import io.jsonwebtoken.Claims;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.nio.charset.StandardCharsets;

/**
 * JWT 鉴权拦截器：解析 Authorization 头，注入用户上下文
 */
@Component
public class JwtInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;

    public JwtInterceptor(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // OPTIONS 预检放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        String auth = request.getHeader("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) {
            writeFail(response, "未登录");
            return false;
        }
        try {
            Claims claims = jwtUtil.parseToken(auth.substring(7));
            Long userId = claims.get("userId", Long.class);
            Long teamId = claims.get("teamId", Long.class);
            UserContext.set(userId, teamId);
            return true;
        } catch (Exception e) {
            writeFail(response, "登录已过期");
            return false;
        }
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        UserContext.clear();
    }

    private void writeFail(HttpServletResponse response, String msg) throws Exception {
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write("{\"code\":401,\"message\":\"" + msg + "\",\"data\":null}");
    }
}
