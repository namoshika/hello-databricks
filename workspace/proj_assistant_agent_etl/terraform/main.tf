terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.114.2"
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
variable "databricks_emb_endpoint_name" {
  type    = string
  default = "databricks-qwen3-embedding-0-6b"
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
  name          = "${var.databricks_catalog_name}.${var.databricks_schema_name}.b_website_vsi"
  endpoint_name = "vsi_endpoint"
  primary_key   = "document_id"
  index_type    = "DELTA_SYNC"

  delta_sync_index_spec {
    source_table  = "${var.databricks_catalog_name}.${var.databricks_schema_name}.b_website"
    pipeline_type = "TRIGGERED"
    # columns_to_sync = ["document_id", "original_url"]
    embedding_source_columns {
      name                          = "content"
      embedding_model_endpoint_name = var.databricks_emb_endpoint_name
    }
  }
}
