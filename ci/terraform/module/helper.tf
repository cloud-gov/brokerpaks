resource "cloudfoundry_app" "helper" {
  name       = "csb-helper"
  org_name   = var.org_name
  space_name = var.space_name

  docker_image = "${var.helper_docker_image_name}${var.helper_docker_image_version}"
  docker_credentials = {
    "username" = var.ecr_access_key_id
    "password" = var.ecr_secret_access_key
  }

  command   = "/app/helper"
  instances = var.helper_instances
  memory    = "128M"

  environment = {
    "BROKER_URL" = cloudfoundry_route.csb.url
    // Can't reference cloudfoundry_route.docproxy.url like above because it creates a cycle,
    // so manually build the host instead
    "HOST" = "services.${data.cloudfoundry_domain.docproxy_parent_domain.name}"
  }
}

data "cloudfoundry_domain" "docproxy_parent_domain" {
  name = var.docproxy_domain
}

// Route is specific to the documentation feature of the csb-helper.
resource "cloudfoundry_route" "docproxy" {
  domain = data.cloudfoundry_domain.docproxy_parent_domain.id
  space  = data.cloudfoundry_space.brokers.id
  host   = "services"

  destinations = [{
    app_id = cloudfoundry_app.helper.id
  }]
}

data "cloudfoundry_service_plans" "external_domain" {
  service_offering_name = "external-domain"
  name                  = "domain"
  service_broker_name   = "external-domain-broker"
}

resource "cloudfoundry_service_instance" "docproxy_external_domain" {
  count = var.stack_name == "development" ? 0 : 1

  name  = "docproxy-domain"
  space = data.cloudfoundry_space.brokers.id
  type  = "managed"

  service_plan = data.cloudfoundry_service_plans.external_domain.service_plans[0].id

  parameters = jsonencode({
    domains = ["services.${var.docproxy_domain}"]
  })
}
