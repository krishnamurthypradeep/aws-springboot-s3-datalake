package com.myapp.spring.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.IOException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class S3StorageService {

    // aws
    private final S3Client s3Client;
    private final String bucketName;
    private final String defaultPrefix;
    private final String kmsKeyId;

    public S3StorageService(S3Client s3Client,
                            @Value("${app.s3.bucket-name}")String bucketName,
                            @Value("${app.s3.default-prefix:uploads/}")String defaultPrefix,
                            @Value("${app.s3.kms-key-id:}") String kmsKeyId) {
        this.s3Client = s3Client;
        this.bucketName = bucketName;
        this.defaultPrefix = defaultPrefix;
        this.kmsKeyId = kmsKeyId;
    }

    public Map<String,Object> upload(MultipartFile file,
                                     String prefix,String storageClassValue,
                                     String encryptionMode){
        if(file == null || file.isEmpty()){
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"file missing");
        }
        // aws s3api put-object --bucket <bucket_name> --key <key> --body <body>
// Storage Classes (S3Standard)
        // ReducedRedundancyStorage
        // S3Glacier

        String resolvedPrefix = normalizePrefix(StringUtils.hasText(prefix) ? prefix : defaultPrefix);
        StorageClass storageClass = parseStorageClass(storageClassValue);
        String originalFileName = sanitizeFilename(file.getOriginalFilename());
        String key = resolvedPrefix + UUID.randomUUID() + "-" + originalFileName;
        ServerSideEncryption encryption = parseEncryption(encryptionMode);

        Map<String, String> metadata = new LinkedHashMap<>();
        metadata.put("original-filename", originalFileName);
        metadata.put("uploaded-at", Instant.now().toString());
        metadata.put("demo-prefix", resolvedPrefix);

        PutObjectRequest.Builder requestBuilder=PutObjectRequest.builder().
        bucket(bucketName)
                .key(key)
                .contentType(resolveContentType(file))
                .contentLength(file.getSize())
                .storageClass(storageClass)
                .metadata(metadata)
                .serverSideEncryption(encryption);
        try {
            s3Client.putObject(requestBuilder.build(), RequestBody.fromBytes(file.getBytes()));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        HeadObjectResponse headObject =
        s3Client.headObject(HeadObjectRequest.builder().bucket(bucketName).key(key).build());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("bucket", bucketName);
        response.put("key", key);
        response.put("size", headObject.contentLength());
        response.put("contentType", headObject.contentType());
        response.put("etag", headObject.eTag());
        response.put("lastModified", headObject.lastModified());
        response.put("serverSideEncryption", headObject.serverSideEncryptionAsString());
        response.put("kmsKeyId", headObject.ssekmsKeyId());
        response.put("userMetadata", headObject.metadata());
        response.put("storageClass", findStorageClassByKey(key));
        return response;

    }


    private String findStorageClassByKey(String key) {
        return s3Client.listObjectsV2(ListObjectsV2Request.builder()
                        .bucket(bucketName)
                        .prefix(key)
                        .build())
                .contents()
                .stream()
                .filter(item -> key.equals(item.key()))
                .findFirst()
                .map(item -> item.storageClassAsString())
                .orElse("UNKNOWN");
    }

    private StorageClass parseStorageClass(String storageClassValue) {
        String value = StringUtils.hasText(storageClassValue) ? storageClassValue.trim().toUpperCase() : "STANDARD";
        try {
            return StorageClass.fromValue(value);
        } catch (IllegalArgumentException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Unsupported storageClass. Try STANDARD, STANDARD_IA, INTELLIGENT_TIERING, ONEZONE_IA, GLACIER_IR.");
        }
    }

    private ServerSideEncryption parseEncryption(String encryptionMode) {
        String value = StringUtils.hasText(encryptionMode) ? encryptionMode.trim().toUpperCase() : "SSE_S3";
        return switch (value) {
            case "SSE_S3", "AES256" -> ServerSideEncryption.AES256;
            case "SSE_KMS", "AWS_KMS", "AWS:KMS" -> ServerSideEncryption.AWS_KMS;
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unsupported encryption. Use SSE_S3 or SSE_KMS.");
        };
    }

    private String normalizePrefix(String prefix) {
        String cleaned = prefix == null ? "" : prefix.trim();
        cleaned = cleaned.replace("\\", "/");
        while (cleaned.startsWith("/")) {
            cleaned = cleaned.substring(1);
        }
        if (!StringUtils.hasText(cleaned)) {
            cleaned = defaultPrefix;
        }
        if (!cleaned.endsWith("/")) {
            cleaned = cleaned + "/";
        }
        return cleaned;
    }

    private String normalizeListPrefix(String prefix) {
        if (!StringUtils.hasText(prefix)) {
            return "";
        }
        String cleaned = prefix.trim().replace("\\", "/");
        while (cleaned.startsWith("/")) {
            cleaned = cleaned.substring(1);
        }
        return cleaned;
    }

    private String sanitizeFilename(String originalFilename) {
        String candidate = StringUtils.hasText(originalFilename) ? originalFilename : "file.bin";
        candidate = candidate.replace("\\", "/");
        int lastSlash = candidate.lastIndexOf('/');
        if (lastSlash >= 0) {
            candidate = candidate.substring(lastSlash + 1);
        }
        candidate = candidate.replaceAll("[^A-Za-z0-9._-]", "_");
        return StringUtils.hasText(candidate) ? candidate : "file.bin";
    }

    private String resolveContentType(MultipartFile file) {
        return StringUtils.hasText(file.getContentType()) ? file.getContentType() : "application/octet-stream";
    }

    private String extractFileName(String key, String originalName) {
        if (StringUtils.hasText(originalName)) {
            return originalName;
        }
        int lastSlash = key.lastIndexOf('/');
        return lastSlash >= 0 ? key.substring(lastSlash + 1) : key;
    }

    private void validateKey(String key) {
        if (!StringUtils.hasText(key)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "key is required");
        }
    }

    private ResponseStatusException translateS3Exception(String message, S3Exception e) {
        HttpStatus status = e.statusCode() == 404 ? HttpStatus.NOT_FOUND : HttpStatus.BAD_GATEWAY;
        String details = e.awsErrorDetails() == null ? e.getMessage() : e.awsErrorDetails().errorMessage();
        return new ResponseStatusException(status, message + ": " + details, e);
    }
    private boolean listContainsKey(String prefix, String key) {
        return s3Client.listObjectsV2(ListObjectsV2Request.builder()
                        .bucket(bucketName)
                        .prefix(prefix)
                        .build())
                .contents()
                .stream()
                .anyMatch(item -> key.equals(item.key()));
    }

}
