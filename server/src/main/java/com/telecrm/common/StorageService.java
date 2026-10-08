package com.telecrm.common;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

/**
 * 文件存储服务：默认本地磁盘，可平滑替换为 OSS/MinIO。
 * 返回相对 context-path 的访问 URL（如 /files/abc.mp3）。
 */
@Service
public class StorageService {

    @Value("${telecrm.storage.path:./uploads}")
    private String storagePath;

    @Value("${telecrm.storage.base-url:/files}")
    private String baseUrl;

    private Path root;

    @PostConstruct
    public void init() {
        root = Paths.get(storagePath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            throw new BusinessException("存储目录初始化失败：" + e.getMessage());
        }
    }

    /** 存储文件，返回访问 URL */
    public String store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("文件为空");
        }
        String original = file.getOriginalFilename();
        String ext = "";
        if (original != null && original.contains(".")) {
            ext = original.substring(original.lastIndexOf('.'));
            // 仅允许安全后缀
            if (!ext.matches("(?i)\\.(mp3|wav|m4a|amr|aac|ogg|mp4|jpg|jpeg|png|pdf)$")) {
                throw new BusinessException("不支持的文件类型：" + ext);
            }
        }
        String name = UUID.randomUUID().toString().replace("-", "") + ext;
        try {
            Files.copy(file.getInputStream(), root.resolve(name));
        } catch (IOException e) {
            throw new BusinessException("文件写入失败：" + e.getMessage());
        }
        String base = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        return base + "/" + name;
    }
}
