package com.telecrm;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * 电销CRM后端启动类
 */
@EnableAsync
@SpringBootApplication
@MapperScan("com.telecrm.mapper")
public class TeleCrmApplication {

    public static void main(String[] args) {
        SpringApplication.run(TeleCrmApplication.class, args);
    }
}
