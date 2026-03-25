package com.myapp.spring.api;

import com.myapp.spring.service.S3StorageService;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/s3")
public class S3Controller {

    private S3StorageService storageService;

    public S3Controller(S3StorageService storageService) {
        this.storageService = storageService;
    }

    @PostMapping(value = "/upload",consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "prefix",required = false)String prefix,
            @RequestParam(value = "storageClass",required = false) String storageClass,
            @RequestParam(value = "encryption",required = false)  String encryption){
        return storageService.upload(file,prefix,storageClass,encryption);
    }
}
