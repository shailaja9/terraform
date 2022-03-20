terraform {
  backend "s3" {
    bucket = "mli-devsecops-terraform"
    key    = "%NAME%-%ENV%-cloudfront.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}

variable "project" {
  type = map(string)
  default = {
    name : "%NAME%",
    s3_bucket_strapi : "strapi"
    s3_bucket_nextjs : "nextjs"
    strapi_origin_access_identity : "%STRAPI_ORIGIN%"
    nextjs_origin_access_identity : "%NEXTJS_ORIGIN%"
    api_gateway_id : "%API_GATEWAY_ID%"
  }
}

variable "aws" {
  type = map(string)
  default = {
    vpc_id : "vpc-2ab88343",
    account_id : "777706696655"
    region : "ap-south-1"
  }
}


variable "default_tags" {
  type = map(string)
  default = {
    project : "%NAME%",
    subproject : "%NAME%",
    env : "prod",
    subenv : "%ENV%"
  }
}

variable "ipv6_enabled" {
  default = "true"
}

variable "viewer_protocol_policy" {
  default = "redirect-to-https"
}

variable "min_ttl" {
  default = "0"
}

variable "default_ttl" {
  default = "3600"
}

variable "max_ttl" {
  default = "86400"
}

variable "allowed_methods" {
  type    = list(string)
  default = ["GET", "HEAD"]
}
variable "cached_methods" {
  type    = list(string)
  default = ["GET", "HEAD"]
}

variable "compress" {
  default = "false"
}
