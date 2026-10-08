package com.telecrm.common;

/**
 * 当前登录用户上下文（基于 ThreadLocal，请求级）
 */
public class UserContext {

    private static final ThreadLocal<Long> USER_ID = new ThreadLocal<>();
    private static final ThreadLocal<Long> TEAM_ID = new ThreadLocal<>();

    public static void set(Long userId, Long teamId) {
        USER_ID.set(userId);
        TEAM_ID.set(teamId);
    }

    public static Long getUserId() {
        return USER_ID.get();
    }

    public static Long getTeamId() {
        return TEAM_ID.get();
    }

    public static void clear() {
        USER_ID.remove();
        TEAM_ID.remove();
    }
}
