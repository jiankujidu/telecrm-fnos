package com.telecrm.controller;

import com.telecrm.common.Result;
import com.telecrm.common.StorageService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * 通用文件上传：录音、附件等。返回相对 context-path 的访问 URL。
 */
@RestController
@RequestMapping("/api/file")
public class FileController {

    @Resource
    private StorageService storageService;

    @PostMapping("/upload")
    public Result<Map<String, String>> upload(@RequestParam("file") MultipartFile file) {
        String url = storageService.store(file);
        return Result.success(Map.of("url", url));
    }
}
