package com.telecrm.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

/**
 * 注册 JWT 拦截器，排除鉴权/文档类路径；并映射录音/文件静态资源
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final JwtInterceptor jwtInterceptor;

    @Value("${telecrm.storage.path:./uploads}")
    private String storagePath;

    @Value("${telecrm.storage.base-url:/files}")
    private String baseUrl;

    public WebConfig(JwtInterceptor jwtInterceptor) {
        this.jwtInterceptor = jwtInterceptor;
    }

    /**
     * 一体化部署下所有接口都在 /api 下，鉴权只拦接口；
     * 管理后台页面（/、/index.html、/assets/*、/customer 等前端路由）一律放行。
     */
    private static final List<String> EXCLUDE = List.of(
            "/api/auth/**",
            "/api/files/**"
    );

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(jwtInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(EXCLUDE);
    }

    /**
     * 管理后台是单页应用（SPA），这些路径后端没有对应接口，
     * 必须回落到前端 index.html 交给前端路由处理，否则刷新页面会 404/500。
     * 这里显式枚举后台路由，不会和 /api/** 接口冲突。
     */
    private static final String[] SPA_ROUTES = {
            "/login",
            "/customer", "/customer/**",
            "/order", "/order/**",
            "/package", "/package/**",
            "/records", "/records/**",
            "/report", "/report/**",
            "/task", "/task/**",
            "/team", "/team/**",
            "/vipcode", "/vipcode/**",
    };

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        for (String path : SPA_ROUTES) {
            registry.addViewController(path).setViewName("forward:/index.html");
        }
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String pattern = baseUrl.endsWith("/") ? baseUrl + "**" : baseUrl + "/**";
        Path root = Paths.get(storagePath).toAbsolutePath().normalize();
        registry.addResourceHandler(pattern)
                .addResourceLocations("file:" + root + "/");
    }
}
