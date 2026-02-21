terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.109.0"
    }
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "databricks_profile" {
  type    = string
  default = "DEFAULT"
}
variable "databricks_catalog_name" {
  type = string
}
variable "databricks_schema_name" {
  type = string
}

# ----------------------------
# Provider
# ----------------------------
provider "databricks" {
  profile = var.databricks_profile
}

# ----------------------------
# Vector Search Index
# ----------------------------
resource "databricks_vector_search_index" "main" {
  name          = "${var.databricks_catalog_name}.${var.databricks_schema_name}.g_monthly_news_vsi"
  endpoint_name = "vsi_endpoint"
  index_type    = "DELTA_SYNC"
  primary_key   = "file_name"

  delta_sync_index_spec {
    source_table  = "${var.databricks_catalog_name}.${var.databricks_schema_name}.g_monthly_news_embed"
    pipeline_type = "TRIGGERED"
    embedding_vector_columns {
      name                = "embedding"
      embedding_dimension = 3072
    }
  }
}
