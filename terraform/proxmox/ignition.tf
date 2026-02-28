data "ct_config" "prod_db_01" {
  content      = local.butane_prod_db_01
  strict       = true
  pretty_print = true
}

data "ct_config" "prod_app_01" {
  content      = local.butane_prod_app_01
  strict       = true
  pretty_print = true
}

data "ct_config" "prod_idp_01" {
  content      = local.butane_prod_idp_01
  strict       = true
  pretty_print = true
}

data "ct_config" "prod_proxy_01" {
  content      = local.butane_prod_proxy_01
  strict       = true
  pretty_print = true
}
