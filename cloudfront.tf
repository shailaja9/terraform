/*********** Describe S3 Bucket: Strapi, Nextjs ***************/
data "aws_s3_bucket" "strapi" {
  bucket = "${var.project.name}-${terraform.workspace}-${var.project.s3_bucket_strapi}"
}

data "aws_s3_bucket" "nextjs" {
  bucket = "${var.project.name}-${terraform.workspace}-${var.project.s3_bucket_nextjs}"
}

data "aws_cloudfront_cache_policy" "caching-disabled" {
  name = "Managed-CachingDisabled"
}


/*********** Cloudfront Cache Policy ***************/
resource "aws_cloudfront_cache_policy" "assets-cache-policy" {
  name        = "${var.project.name}-${terraform.workspace}-cdn-assets-cache-policy"
  comment     = "${var.project.name}-${terraform.workspace}-cdn-assets-cache-policy"
  default_ttl = 300
  max_ttl     = 300
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = "true"
    enable_accept_encoding_gzip   = "true"
  }
}

/*********** Cloudfront Origin Request Policy ***************/
resource "aws_cloudfront_origin_request_policy" "assets-request-policy" {
  name    = "${var.project.name}-${terraform.workspace}-cdn-assets-request-policy"
  comment = "${var.project.name}-${terraform.workspace}-cdn-assets-request-policy"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

/*********** Cloudfront Origin Request Policy ***************/
resource "aws_cloudfront_origin_request_policy" "cdn-api-request-policy" {
  name    = "${var.project.name}-${terraform.workspace}-cdn-api-request-policy"
  comment = "${var.project.name}-${terraform.workspace}-cdn-api-request-policy"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["uicorrelationid"]
    }
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}


/*********** Cloudfront Distribution ***************/
resource "aws_cloudfront_distribution" "main" {
  enabled         = "true"
  is_ipv6_enabled = var.ipv6_enabled
  comment         = "${var.project.name}-${terraform.workspace}"

  //CDN Origin - Strapi
  origin {
    domain_name = data.aws_s3_bucket.strapi.bucket_domain_name
    origin_id   = data.aws_s3_bucket.strapi.id
    s3_origin_config {
      origin_access_identity = var.project.strapi_origin_access_identity
    }
  }

  //CDN Origin - NextJs
  origin {
    domain_name = data.aws_s3_bucket.nextjs.bucket_domain_name
    origin_id   = data.aws_s3_bucket.nextjs.id
    s3_origin_config {
      origin_access_identity = var.project.nextjs_origin_access_identity
    }
  }

  //CDN Origin - API Gateway
  origin {
    domain_name = "${var.project.api_gateway_id}.execute-api.${var.aws.region}.amazonaws.com"
    origin_path = "/${terraform.workspace}"
    origin_id   = "${var.project.name}-${terraform.workspace}-private-api"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  //Default Behavior - Nextjs
  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    cache_policy_id          = aws_cloudfront_cache_policy.assets-cache-policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.assets-request-policy.id
    target_origin_id         = data.aws_s3_bucket.nextjs.id
    compress                 = var.compress
    viewer_protocol_policy   = var.viewer_protocol_policy
  }

  // Cache behavior - API with precedence 0
  ordered_cache_behavior {
    path_pattern             = "/payments/api/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    target_origin_id         = "${var.project.name}-${terraform.workspace}-private-api"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching-disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.cdn-api-request-policy.id
    compress                 = var.compress
    viewer_protocol_policy   = "redirect-to-https"
  }

  # Cache behavior - Assets with precedence 1
  ordered_cache_behavior {
    path_pattern           = "/cs/assets/*"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    cache_policy_id        = aws_cloudfront_cache_policy.assets-cache-policy.id
    target_origin_id       = data.aws_s3_bucket.strapi.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = var.default_tags
}
