terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.109.0"
    }
  }
  backend "local" {
    path = "../tfstates/04-databricks-extras.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "databricks_profile" {
  type    = string
  default = "DEFAULT"
}

# ----------------------------
# Provider
# ----------------------------
provider "databricks" {
  profile = var.databricks_profile
}

# ----------------------------
# Vector Search Endpoint
# ----------------------------
resource "databricks_vector_search_endpoint" "main" {
  name          = "vsi_endpoint"
  endpoint_type = "STANDARD"
}
