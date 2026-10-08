package com.telecrm.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.telecrm.entity.User;

/**
 * 用户服务
 */
public interface UserService extends IService<User> {

    /**
     * 登录校验
     */
    User login(String phone, String password);

    /**
     * 注册
     */
    User register(User user);
}
