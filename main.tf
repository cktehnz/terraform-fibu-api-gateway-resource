module "common" {
  source      = "app.terraform.io/HitachiFIBU/common/fibu"
  version     = "0.1.0"
  environment = var.environment
  owner       = var.owner
  project     = var.project
}

resource "aws_api_gateway_resource" "root_resources" {
  for_each = { for res in var.resources : res.path_part => res if res.parent == "root" }

  rest_api_id = var.api_gateway.id
  parent_id   = var.api_gateway.root_resource_id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "child_resources" {
  for_each = { for res in var.resources : res.path_part => res if res.parent != "root" }

  rest_api_id = var.api_gateway.id
  parent_id   = aws_api_gateway_resource.root_resources[each.value.parent].id
  path_part   = each.value.path_part

  depends_on = [
    aws_api_gateway_resource.root_resources
  ]
}

resource "aws_api_gateway_method" "dynamic_method" {
  for_each = { for method in local.flattened_methods : "${method.resource_path_part}-${method.method_type}" => method }

  rest_api_id   = var.api_gateway.id
  resource_id   = each.value.parent == "root" ? aws_api_gateway_resource.root_resources[each.value.resource_path_part].id : aws_api_gateway_resource.child_resources[each.value.resource_path_part].id
  http_method   = each.value.method_type
  authorization = each.value.authorization

  request_parameters = merge({
    for param in each.value.path_parameters : "method.request.path.${param}" => true
    }, {
    for param in each.value.query_parameters : "method.request.querystring.${param}" => true
  })

  depends_on = [
    aws_api_gateway_resource.root_resources,
    aws_api_gateway_resource.child_resources
  ]
}

resource "aws_api_gateway_integration" "dynamic_mock" {
  for_each = { for method in local.flattened_methods : "${method.resource_path_part}-${method.method_type}" => method }

  rest_api_id = var.api_gateway.id
  resource_id = each.value.parent == "root" ? aws_api_gateway_resource.root_resources[each.value.resource_path_part].id : aws_api_gateway_resource.child_resources[each.value.resource_path_part].id
  http_method = each.value.method_type
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [
    aws_api_gateway_method.dynamic_method
  ]
}

resource "aws_api_gateway_method_response" "dynamic_method_response" {
  for_each = { for method in local.flattened_methods : "${method.resource_path_part}-${method.method_type}" => method }

  rest_api_id = var.api_gateway.id
  resource_id = each.value.parent == "root" ? aws_api_gateway_resource.root_resources[each.value.resource_path_part].id : aws_api_gateway_resource.child_resources[each.value.resource_path_part].id
  http_method = each.value.method_type
  status_code = each.value.status_code

  response_models = {
    "application/json" = each.value.response_model
  }

  depends_on = [
    aws_api_gateway_method.dynamic_method
  ]
}

resource "aws_api_gateway_integration_response" "dynamic_integration_response" {
  for_each = { for method in local.flattened_methods : "${method.resource_path_part}-${method.method_type}" => method }

  rest_api_id = var.api_gateway.id
  resource_id = each.value.parent == "root" ? aws_api_gateway_resource.root_resources[each.value.resource_path_part].id : aws_api_gateway_resource.child_resources[each.value.resource_path_part].id
  http_method = each.value.method_type
  status_code = each.value.status_code

  response_templates = {
    "application/json" = file(each.value.response_template_file)
  }

  depends_on = [
    aws_api_gateway_method.dynamic_method,
    aws_api_gateway_method_response.dynamic_method_response
  ]
}

