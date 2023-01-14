# Create a GCP Service Account
resource "google_service_account" "sa" {
  account_id   = "sa-oxdit-app"
  display_name = "sa-oxdit-app"
  description  = "Service Account for App"
  project      = var.gcp_project
}

# Create a GCP IAM Policy for Service Account
data "google_iam_policy" "sa-iam-policy" {
  binding {
    role = "roles/owner"
    
    members = [
      "serviceAccount:${google_service_account.sa.email}",
    ]
  }
}
# Assign IAM roles to the Service Account
resource "google_service_account_iam_policy" "sa-iam" {
  service_account_id = google_service_account.sa.id
  policy_data        = data.google_iam_policy.sa-iam-policy.policy_data
}

# Create Owners Group
resource "google_cloud_identity_group" "owners-group" {
  provider = google-beta
  display_name = "oxdit-app-owners"
  parent = "customers/C026kk58t"                                      #Need to change Customer ID ACG
  group_key {
    id = "oxdit-app-owners@oxdit.com"
  }
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}
# Create Editors Group
resource "google_cloud_identity_group" "editors-group" {
  provider = google-beta
  display_name = "oxdit-app-editors"
  parent = "customers/C026kk58t"
  group_key {
    id = "oxdit-app-editors@oxdit.com"
  }
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Assign Groups to the Project
resource "google_project_iam_policy" "group-iam-policy" {
  depends_on = [
    google_cloud_identity_group.owners-group,
    google_cloud_identity_group.editors-group
  ]
  project     = var.gcp_project
  policy_data = data.google_iam_policy.groups-iam-policy.policy_data
}
# Groups Policy
data "google_iam_policy" "groups-iam-policy" {
  binding {
    role = "roles/owner"
    members = [
      "group:oxdit-app-owners@oxdit.com",
    ]
  }
  binding {
    role = "roles/editor"
    members = [
      "group:oxdit-app-editors@oxdit.com",
    ]
  }
}

# Add members to the Owners Group
resource "google_cloud_identity_group_membership" "owners-group-membership" {
  provider = google-beta
  group    = google_cloud_identity_group.owners-group.id
  for_each = toset(var.owners_members)
  member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "MANAGER"
  }
}
# Add members to the Editors Group
resource "google_cloud_identity_group_membership" "editors-group-membership" {
  provider = google-beta
  group    = google_cloud_identity_group.editors-group.id
  for_each = toset(var.editors_members)
  member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
}


module "group" {
  source   = "./modules/gcp-group"
  group_email = "GCP-Integration_Extract_Users@oxdit.com"
  display_name         = "GCP-Integration_Extract_Users"
  customer_id          =  "C026kk58t"
  roles                =  ["Member", "owner"]
  org_id               =  144284246947                                               #OrgID needs to be ACG
  role                 =  "Member" 
}

module "service_accounts" {
  source        = "./modules/serviceaccount"
  project_id    = var.gcp_project
  prefix        = "Svc"
  names         = ["Terraform-Managed-Service-Group"]
  project_roles = ["${var.gcp_project}=>roles/viewer"]
  display_name  = "Terraform-Managed-Service-Group"
  description   = "Service Account for module"
  account_id    =  "tfsvcag"
}

module "custom-role-project" {
  source = "./modules/custom_role_iam"

  target_level         = "project"
  target_id            = var.gcp_project
  role_id              = "iamDeleter"
  base_roles           = ["roles/iam.serviceAccountAdmin"]
  permissions          = ["iam.roles.list", "iam.roles.create", "iam.roles.delete"]
  excluded_permissions = ["iam.serviceAccounts.setIamPolicy", "resourcemanager.projects.get", "resourcemanager.projects.list"]
  description          = "This is a project level custom role."
  members              = ["serviceAccount:${google_service_account.sa.email}", "group:oxdit-app-editors@oxdit.com"]
}

resource "google_folder" "department1" {
  display_name = "Department 1"
  parent       = "organizations/144284246947"
}

module "folder-iam" {                                                                   
  source  = "./modules/folders_iam"
  folders = ["Department 1"]                            #Update your variables whenver you are calling                
  mode = "additive"

  bindings = {
    "roles/resourcemanager.folderEditor" = [
      "serviceAccount:${google_service_account.sa.email}",
      "group:oxdit-app-editors@oxdit.com",
    ]

    "roles/resourcemanager.folderViewer" = [
      "group:oxdit-app-editors@oxdit.com",
    ]
  }
}

resource "google_service_account" "member_iam_test" {
  project      = var.gcp_project
  account_id   = "member-iam-test"
  display_name = "member-iam-test"
}

module "member_roles" {
  source                  = "./modules/member_iam"
  service_account_address = google_service_account.member_iam_test.email
  project_id              = var.gcp_project
  project_roles           = ["roles/compute.networkAdmin", "roles/appengine.appAdmin"]
  prefix                  = "serviceAccount"
}
