/* -------------------------------------------------------------------------- */
/*                              Create the Group                              */
/* -------------------------------------------------------------------------- */

resource "google_cloud_identity_group" "group" {
  display_name         = var.display_name
  initial_group_config = "EMPTY"

  parent = "customers/${var.customer_id}"

  group_key {
     id = "var.group_email"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

/* -------------------------------------------------------------------------- */
/*                           Create the IAM Policies                          */
/* -------------------------------------------------------------------------- */

/* -------------------------- Organizational Level -------------------------- */

resource "google_organization_iam_member" "org_iam_member" {
  # for_each = local.org_iam_bindings
  role     = var.role
  member   = "group:${var.group_email}"
  org_id   =  var.org_id
}

/* ------------------------------ Folder Level ------------------------------ */

resource "google_folder_iam_member" "folder_iam_member" {
  # for_each = local.folder_iam_bindings
  folder   = "folders/${var.folder_id}"
  role     = var.role
  member   = "group:${var.group_email}"
}
