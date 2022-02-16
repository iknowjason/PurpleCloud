resource "azuread_group" "IT_Ops" {
  display_name = "${var.tenant_id} - IT Ops"
  members = [
    azuread_user.user1.object_id,
    azuread_user.user2.object_id,
    azuread_user.user3.object_id,
    azuread_user.user4.object_id
  ]
}

resource "azuread_group" "IT_Admins" {
  display_name = "${var.tenant_id} - IT Admins"
  members = [
    azuread_user.user4.object_id
  ]
}

resource "azuread_group" "HR_Users" {
  display_name = "${var.tenant_id} - HR Users"
  members = [
    azuread_user.user5.object_id,
    azuread_user.user6.object_id,
    azuread_user.user7.object_id
  ]
}

resource "azuread_group" "Finance_Users" {
  display_name = "${var.tenant_id} - Finance Users"
  members = [
    azuread_user.user8.object_id,
    azuread_user.user9.object_id,
    azuread_user.user10.object_id
  ]
}

resource "azuread_group" "Marketing_Users" {
  display_name = "${var.tenant_id} - Marketing Users"
  members = [
    azuread_user.user11.object_id,
    azuread_user.user12.object_id,
    azuread_user.user13.object_id,
    azuread_user.user14.object_id,
    azuread_user.user15.object_id
  ]
}

resource "azuread_group" "Executive_Team" {
  display_name = "${var.tenant_id} - Executive Team"
  members = [
    azuread_user.user16.object_id,
    azuread_user.user17.object_id,
    azuread_user.user18.object_id,
    azuread_user.user19.object_id
  ]
}

resource "azuread_group" "Sales_Team" {
  display_name = "${var.tenant_id} - Sales Team"
  members = [
    azuread_user.user20.object_id,
    azuread_user.user21.object_id,
    azuread_user.user22.object_id,
    azuread_user.user23.object_id,
    azuread_user.user24.object_id,
    azuread_user.user25.object_id
  ]
}

resource "azuread_group" "Users" {
  display_name = "${var.tenant_id} - Users"
  members = [
    azuread_user.user1.object_id,
    azuread_user.user2.object_id,
    azuread_user.user3.object_id,
    azuread_user.user4.object_id,
    azuread_user.user5.object_id,
    azuread_user.user6.object_id,
    azuread_user.user7.object_id,
    azuread_user.user8.object_id,
    azuread_user.user9.object_id,
    azuread_user.user10.object_id,
    azuread_user.user11.object_id,
    azuread_user.user12.object_id,
    azuread_user.user13.object_id,
    azuread_user.user14.object_id,
    azuread_user.user15.object_id,
    azuread_user.user16.object_id,
    azuread_user.user17.object_id,
    azuread_user.user18.object_id,
    azuread_user.user19.object_id,
    azuread_user.user20.object_id,
    azuread_user.user21.object_id,
    azuread_user.user22.object_id,
    azuread_user.user23.object_id,
    azuread_user.user24.object_id,
    azuread_user.user25.object_id
  ]
}
