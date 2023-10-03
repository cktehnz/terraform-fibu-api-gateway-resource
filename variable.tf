variable "aws_region" {
  description = "The region of AWS resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "The environment for which these tags are applicable."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "The owner for which these tags are applicable."
  type        = string
  default     = "fibu"
}

variable "name" {
  description = "The name of the module"
  type        = string
  default     = "api-gateway"
}

variable "project" {
  description = "The project for which these tags are applicable."
  type        = string
  default     = "superapp"
}

variable "api_gateway" {
  description = "The API Gateway details."
  type = object({
    id               = string
    root_resource_id = string
  })
  default = {
    id               = ""
    root_resource_id = ""
  }
}

variable "resources" {
  description = "List of API Gateway resources and their methods"
  type = list(object({
    path_part = string
    parent    = string
    methods = list(object({
      type                   = string
      authorization          = string
      status_code            = string
      response_model         = string
      response_template_file = string
    }))
  }))
  default = []
}
