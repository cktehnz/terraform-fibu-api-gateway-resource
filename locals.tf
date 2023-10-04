locals {
  flattened_methods = flatten([
    for res in var.resources : [
      for method in coalesce(res.methods, []) : {
        resource_path_part     = res.path_part
        method_type            = method.type
        authorization          = method.authorization
        status_code            = method.status_code
        response_model         = method.response_model
        response_template_file = method.response_template_file
        query_parameters       = coalesce(method.query_parameters, [])
        parent                 = res.parent
      }
    ]
  ])
}