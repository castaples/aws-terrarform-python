variable "aws_region" {
  default     = "eu-west-2"
  description = "AWS deployment region"
}

variable "remove_image_exif_lambda_function_name" {
  type        = string
  default     = "RemoveImageExifData"
  description = "Name of the Lambda function to remove exif data from images uploaded to s3"
}

variable "bucket_a_name_prefix" {
  type        = string
  default     = "bucket-a-"
  description = "Bucket A name prefix, to be appened to a random string"
}

variable "bucket_b_name_prefix" {
  type        = string
  default     = "bucket-b-"
  description = "Bucket B name prefix, to be appened to a random string"
}
