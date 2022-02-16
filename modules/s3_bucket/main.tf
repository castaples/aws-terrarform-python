data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

locals {
  default_bucket_policy_statements = <<-STATEMENTS
  {
    "Sid": "AllowAccountBucketReadOnly",
    "Principal": {
      "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    },
    "Action": [
      "s3:Get*",
      "s3:List*"
    ],
    "Effect": "Allow",
    "Resource": "arn:aws:s3:::${var.bucket_name}*"
  },
  {
    "Sid": "DenyBucketModification",
    "Principal": {
      "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    },
    "Action": [
      "s3:DeleteBucket*",
      "s3:PutBucketPolicy"
    ],
    "Effect": "Deny",
    "Resource": "arn:aws:s3:::${var.bucket_name}",
    "Condition": {
      "StringNotLike": {
        "aws:PrincipalArn": "${data.aws_caller_identity.current.user_id}"
      }
    }
  },
  {
    "Sid": "EnforceEncryptionInTransit",
    "Principal": "*",
    "Action": "s3:*",
    "Effect": "Deny",
    "Resource": "arn:aws:s3:::${var.bucket_name}*",
    "Condition": {
      "Bool": {
        "aws:SecureTransport": "false"
      },
      "NumericLessThan": {
        "s3:TlsVersion": 1.2
      }
    }
  }
  STATEMENTS

  bucket_policy = var.bucket_policy_additional_statements != "" ? local.default_bucket_policy_statements + "," + var.bucket_policy_additional_statements : local.default_bucket_policy_statements
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      ${local.bucket_policy}
    ]
  }
  POLICY
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.bucket]

  bucket = aws_s3_bucket.bucket.bucket

  rule {
    id = "noncurrent"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    status = "Enabled"
  }

  rule {
    id = "deletemarker"

    expiration {
      expired_object_delete_marker = true
    }

    status = "Enabled"
  }
}
