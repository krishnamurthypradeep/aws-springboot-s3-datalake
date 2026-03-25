resource "aws_kms_key" "s3" {
  description             = "KMS key for optional SSE-KMS S3 object uploads"
  deletion_window_in_days = var.s3_kms_key_deletion_window_in_days
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-s3-kms-key"
  }
}

resource "aws_kms_alias" "s3" {
  name          = var.s3_kms_key_alias
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_s3_bucket" "app_bucket" {
  bucket        = var.bucket_name
  force_destroy = var.s3_force_destroy

  tags = {
    Name = "${var.project_name}-app-bucket"
  }
}

resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_bucket_pab" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "app_bucket_lifecycle" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    id     = "archive-prefix-transitions"
    status = "Enabled"

    filter {
      prefix = var.s3_archive_prefix
    }

    transition {
      days          = var.s3_lifecycle_archive_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.s3_lifecycle_archive_to_glacier_ir_days
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = var.s3_lifecycle_archive_expiration_days
    }
  }

  rule {
    id     = "expire-temp-prefix"
    status = "Enabled"

    filter {
      prefix = var.s3_tmp_prefix
    }

    expiration {
      days = var.s3_lifecycle_tmp_expiration_days
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.s3_abort_incomplete_multipart_upload_days
    }
  }
}

data "aws_iam_policy_document" "app_bucket_policy" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.app_bucket.arn,
      "${aws_s3_bucket.app_bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid     = "DenyMissingEncryptionHeaderOnPut"
    effect  = "Deny"
    actions = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.app_bucket.arn}/*"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  statement {
    sid     = "DenyUnsupportedEncryptionHeaders"
    effect  = "Deny"
    actions = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.app_bucket.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256", "aws:kms"]
    }
  }
}

resource "aws_s3_bucket_policy" "app_bucket_policy" {
  bucket = aws_s3_bucket.app_bucket.id
  policy = data.aws_iam_policy_document.app_bucket_policy.json
}

resource "aws_s3_object" "app_jar" {
  bucket                 = aws_s3_bucket.app_bucket.bucket
  key                    = var.app_jar_s3_key
  source                 = var.app_jar_path
  etag                   = filemd5(var.app_jar_path)
  storage_class          = "STANDARD"
  server_side_encryption = "AES256"
}
