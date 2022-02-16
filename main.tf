data "aws_caller_identity" "current" {}

resource "random_string" "random" {
  length  = 16
  special = false
}

resource "aws_iam_role" "remove_image_exif_lambda_execution_iam_role" {
  name = "${var.remove_image_exif_lambda_function_name}LambdaExecutionRole"

  assume_role_policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy" "remove_image_exif_lambda_execution_iam_role_policy" {
  name = "${aws_iam_role.remove_image_exif_lambda_execution_iam_role.name}Policy"
  role = aws_iam_role.remove_image_exif_lambda_execution_iam_role.id

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowBucketARead",
        "Action": [
          "s3:ListBucket",
          "s3:GetObject*",
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${local.bucket_a_name}*"
      },
      {
        "Sid": "AllowBucketBWrite",
        "Action": [
          "s3:ListBucket",
          "s3:PutObject*",
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${local.bucket_b_name}*"
      },
      {
        "Sid": "AllowLogs",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/${var.remove_image_exif_lambda_function_name}*"
      }
    ]
  }
  POLICY
}

resource "aws_cloudwatch_log_group" "remove_image_exif_lambda_function_logs" {
  name              = "/aws/lambda/${var.remove_image_exif_lambda_function_name}"
  retention_in_days = 14
}

data "archive_file" "remove_image_exif_lambda_function_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "remove_image_exif_lambda_function" {
  filename         = "${path.module}/lambda.zip"
  function_name    = var.remove_image_exif_lambda_function_name
  role             = aws_iam_role.remove_image_exif_lambda_execution_iam_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.remove_image_exif_lambda_function_zip.output_base64sha256
  runtime          = "python3.8"

  environment {
    variables = {
      DST_BUCKET = "${local.bucket_b_name}"
    }
  }
}

resource "aws_lambda_permission" "allow_bucket_a_notification" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remove_image_exif_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${local.bucket_a_name}"
}

resource "aws_s3_bucket_notification" "bucket_a_lambda_notification" {
  bucket = local.bucket_a_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.remove_image_exif_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_bucket_a]
}

resource "aws_s3_account_public_access_block" "block_public_buckets" {
  block_public_acls   = true
  block_public_policy = true
}

locals {
  bucket_a_name = var.bucket_a_name_prefix + random_string.random.result
  bucket_b_name = var.bucket_b_name_prefix + random_string.random.result
}

module "bucket_a" {
  source = "./modules/s3_bucket"

  bucket_name = local.bucket_a_name

  bucket_policy_additional_statements = <<-STATEMENTS
  {
    "Sid": "DenyObjectAccess",
    "Principal": "*",
    "Action": [
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:PutObject*"
    ],
    "Effect": "Deny",
    "Resource": "arn:aws:s3:::${local.bucket_a_name}*",
    "Condition": {
      "StringNotLike": {
        "aws:PrincipalArn": [
          "${aws_iam_user.user_a.arn}",
          "${aws_iam_role.remove_image_exif_lambda_execution_iam_role.arn}"
        ]
      }
    }
  },
  {
    "Sid": "AllowUserA",
    "Principal": "*",
    "Action": [
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:PutObject*"
    ],
    "Effect": "Allow",
    "Resource": "arn:aws:s3:::${local.bucket_a_name}*",
    "Condition": {
      "StringLike": {
        "aws:PrincipalArn": "${aws_iam_user.user_a.arn}"
      }
    }
  },
  {
    "Sid": "AllowLambda",
    "Principal": "*",
    "Action": "s3:GetObject*",
    "Effect": "Allow",
    "Resource": "arn:aws:s3:::${local.bucket_a_name}*",
    "Condition": {
      "StringLike": {
        "aws:PrincipalArn": "${aws_iam_role.remove_image_exif_lambda_execution_iam_role.arn}"
      }
    }
  }
  STATEMENTS
}

module "bucket_b" {
  source = "./modules/s3_bucket"

  bucket_name = "bucket_b"

  bucket_policy_additional_statements = <<-STATEMENTS
  {
    "Sid": "DenyObjectAccess",
    "Principal": "*",
    "Action": [
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:PutObject*"
    ],
    "Effect": "Deny",
    "Resource": "arn:aws:s3:::${local.bucket_b_name}*",
    "Condition": {
      "StringNotLike": {
        "aws:PrincipalArn": [
          "${aws_iam_user.user_b.arn}",
          "${aws_iam_role.remove_image_exif_lambda_execution_iam_role.arn}"
        ]
      }
    }
  },
  {
    "Sid": "AllowUserA",
    "Principal": "*",
    "Action": "s3:GetObject*",
    "Effect": "Allow",
    "Resource": "arn:aws:s3:::${local.bucket_b_name}*",
    "Condition": {
      "StringLike": {
        "aws:PrincipalArn": "${aws_iam_user.user_a.arn}"
      }
    }
  },
  {
    "Sid": "AllowLambda",
    "Principal": "*",
    "Action": "s3:PutObject*",
    "Effect": "Allow",
    "Resource": "arn:aws:s3:::${local.bucket_b_name}*",
    "Condition": {
      "StringLike": {
        "aws:PrincipalArn": "${aws_iam_role.remove_image_exif_lambda_execution_iam_role.arn}"
      }
    }
  }
  STATEMENTS
}

resource "aws_iam_user" "user_a" {
  name = "UserA"
}

resource "aws_iam_user_policy" "user_a_policy" {
  name = "${aws_iam_user.user_a.name}Policy"
  user = aws_iam_user.user_a.name

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:ListBucket",
          "s3:*Object*"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${local.bucket_a_name}*"
      }
    ]
  }
  POLICY
}

resource "aws_iam_user" "user_b" {
  name = "User_B"
}

resource "aws_iam_user_policy" "user_b_policy" {
  name = "${aws_iam_user.user_b.name}Policy"
  user = aws_iam_user.user_b.name

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:ListBucket",
          "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${local.bucket_b_name}*"
      }
    ]
  }
  POLICY
}
