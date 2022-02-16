# Random Pet for Azure AD users (First part of password)
resource "random_pet" "rp_string" {
  length = 2
}

output "rp_string" {
  value = random_pet.rp_string.id
}

# Random String for Azure AD users (Second part of password)
resource "random_string" "my_password" {
  length  = 4 
  special = false
  upper   = true
}

output "my_password" {
  value = random_string.my_password.id
}

locals {
  creds = "${random_pet.rp_string.id}-${random_string.my_password.id}"
}

output "my_aad_creds" {
  value = local.creds
}

# write azure ad user password to file
resource "local_file" "aad_creds" {
    content = local.creds
    filename = "${path.module}/AAD_PASSWORD.txt"
    file_permission = "0700"
}

resource "azuread_user" "user1" {
  user_principal_name = "jeff@${var.upn_suffix}"
  display_name        = "Jeff Robertson"
  mail_nickname       = "jeff"
  password            = local.creds
}

resource "azuread_user" "user2" {
  user_principal_name = "freya@${var.upn_suffix}"
  display_name        = "Freya Odinsdottir"
  mail_nickname       = "freya"
  password            = local.creds
}

resource "azuread_user" "user3" {
  user_principal_name = "adam@${var.upn_suffix}"
  display_name        = "Adam Johnston"
  mail_nickname       = "adam"
  password            = local.creds
}

resource "azuread_user" "user4" {
  user_principal_name = "kirstin@${var.upn_suffix}"
  display_name        = "Kristin Smith"
  mail_nickname       = "kristin"
  password            = local.creds
}

resource "azuread_user" "user5" {
  user_principal_name = "danni@${var.upn_suffix}"
  display_name        = "Danni Hogan"
  password            = local.creds
}

resource "azuread_user" "user6" {
  user_principal_name = "zane@${var.upn_suffix}"
  display_name        = "Zane Olson"
  mail_nickname       = "zane"
  password            = local.creds
}

resource "azuread_user" "user7" {
  user_principal_name = "juliet@${var.upn_suffix}"
  display_name        = "Juliet May"
  mail_nickname       = "juliet"
  password            = local.creds
}

resource "azuread_user" "user8" {
  user_principal_name = "joe@${var.upn_suffix}"
  display_name        = "Joe Barrett"
  mail_nickname       = "joe"
  password            = local.creds
}

resource "azuread_user" "user9" {
  user_principal_name = "scarlette@${var.upn_suffix}"
  display_name        = "Scarlette Vinson"
  mail_nickname       = "scarlette"
  password            = local.creds
}

resource "azuread_user" "user10" {
  user_principal_name = "tala@${var.upn_suffix}"
  display_name        = "Tala Valentine"
  mail_nickname       = "tala"
  password            = local.creds
}

resource "azuread_user" "user11" {
  user_principal_name = "tammy@${var.upn_suffix}"
  display_name        = "Tammy Leonard"
  mail_nickname       = "tammy"
  password            = local.creds
}

resource "azuread_user" "user12" {
  user_principal_name = "elsa@${var.upn_suffix}"
  display_name        = "Elsa Parsons"
  mail_nickname       = "elsa"
  password            = local.creds
}

resource "azuread_user" "user13" {
  user_principal_name = "brad@${var.upn_suffix}"
  display_name        = "Brad Mata"
  mail_nickname       = "brad"
  password            = local.creds
}

resource "azuread_user" "user14" {
  user_principal_name = "donald@${var.upn_suffix}"
  display_name        = "Donald Riddle"
  mail_nickname       = "donald"
  password            = local.creds
}

resource "azuread_user" "user15" {
  user_principal_name = "micah@${var.upn_suffix}"
  display_name        = "Micah Blackmore"
  mail_nickname       = "micah"
  password            = local.creds
}

resource "azuread_user" "user16" {
  user_principal_name = "trixie@${var.upn_suffix}"
  display_name        = "Trixie Mac"
  mail_nickname       = "trixie"
  password            = local.creds
}

resource "azuread_user" "user17" {
  user_principal_name = "kaila@${var.upn_suffix}"
  display_name        = "Kaila Moore"
  mail_nickname       = "kaila"
  password            = local.creds
}

resource "azuread_user" "user18" {
  user_principal_name = "liam@${var.upn_suffix}"
  display_name        = "Liam Rich"
  mail_nickname       = "liam"
  password            = local.creds
}

resource "azuread_user" "user19" {
  user_principal_name = "star@${var.upn_suffix}"
  display_name        = "Star Jordan"
  mail_nickname       = "star"
  password            = local.creds
}

resource "azuread_user" "user20" {
  user_principal_name = "neil@${var.upn_suffix}"
  display_name        = "Neil Barnard"
  mail_nickname       = "neil"
  password            = local.creds
}

resource "azuread_user" "user21" {
  user_principal_name = "michelle@${var.upn_suffix}"
  display_name        = "Michelle Gray"
  mail_nickname       = "michelle"
  password            = local.creds
}

resource "azuread_user" "user22" {
  user_principal_name = "trevor@${var.upn_suffix}"
  display_name        = "Trevor Cox"
  mail_nickname       = "trevor"
  password            = local.creds
}

resource "azuread_user" "user23" {
  user_principal_name = "johanna@${var.upn_suffix}"
  display_name        = "Johanna Webb"
  mail_nickname       = "johanna"
  password            = local.creds
}

resource "azuread_user" "user24" {
  user_principal_name = "jackson@${var.upn_suffix}"
  display_name        = "Jackson Santiago"
  mail_nickname       = "jackson"
  password            = local.creds
}

resource "azuread_user" "user25" {
  user_principal_name = "chloe@${var.upn_suffix}"
  display_name        = "Chloe Devlin"
  mail_nickname       = "chloe"
  password            = local.creds
}

resource "azuread_user" "user26" {
  user_principal_name = "ajohnston@${var.upn_suffix}"
  display_name        = "Alice Johnston"
  mail_nickname       = "alice"
  password            = local.creds
}

resource "azuread_user" "user27" {
  user_principal_name = "avi@${var.upn_suffix}"
  display_name        = "Avi Cullen"
  mail_nickname       = "avi"
  password            = local.creds
}

resource "azuread_user" "user28" {
  user_principal_name = "emelie@${var.upn_suffix}"
  display_name        = "Emelie Robbins"
  mail_nickname       = "emelie"
  password            = local.creds
}

resource "azuread_user" "user29" {
  user_principal_name = "gene@${var.upn_suffix}"
  display_name        = "Gene Shah"
  mail_nickname       = "gene"
  password            = local.creds
}

resource "azuread_user" "user30" {
  user_principal_name = "herbert@${var.upn_suffix}"
  display_name        = "Herbert Stone"
  mail_nickname       = "herbert"
  password            = local.creds
}

resource "azuread_user" "user31" {
  user_principal_name = "jade@${var.upn_suffix}"
  display_name        = "Jade Wallis"
  mail_nickname       = "jade"
  password            = local.creds
}

resource "azuread_user" "user32" {
  user_principal_name = "jenson@${var.upn_suffix}"
  display_name        = "Jenson Grey"
  mail_nickname       = "jenson"
  password            = local.creds
}

resource "azuread_user" "user33" {
  user_principal_name = "katherin@${var.upn_suffix}"
  display_name        = "Katherine May"
  mail_nickname       = "katherine"
  password            = local.creds
}

resource "azuread_user" "user34" {
  user_principal_name = "kaycee@${var.upn_suffix}"
  display_name        = "Kaycee Peters"
  mail_nickname       = "kaycee"
  password            = local.creds
}

resource "azuread_user" "user35" {
  user_principal_name = "kim@${var.upn_suffix}"
  display_name        = "Kim Johnson"
  mail_nickname       = "kim"
  password            = local.creds
}

resource "azuread_user" "user36" {
  user_principal_name = "luka@${var.upn_suffix}"
  display_name        = "Luka Henderson"
  mail_nickname       = "luka"
  password            = local.creds
}

resource "azuread_user" "user37" {
  user_principal_name = "ned@${var.upn_suffix}"
  display_name        = "Ned Broughton"
  mail_nickname       = "ned"
  password            = local.creds
}

resource "azuread_user" "user38" {
  user_principal_name = "phillip@${var.upn_suffix}"
  display_name        = "Phillip Laing"
  mail_nickname       = "phillip"
  password            = local.creds
}

resource "azuread_user" "user39" {
  user_principal_name = "rui@${var.upn_suffix}"
  display_name        = "Rui Mueller"
  mail_nickname       = "rui"
  password            = local.creds
}

resource "azuread_user" "user40" {
  user_principal_name = "spike@${var.upn_suffix}"
  display_name        = "Spike Betts"
  mail_nickname       = "spike"
  password            = local.creds
}

resource "azuread_user" "user41" {
  user_principal_name = "susie@${var.upn_suffix}"
  display_name        = "Susie Lawrence"
  mail_nickname       = "susie"
  password            = local.creds
}

resource "azuread_user" "user42" {
  user_principal_name = "tracy@${var.upn_suffix}"
  display_name        = "Tracy Orr"
  mail_nickname       = "tracy"
  password            = local.creds
}

resource "azuread_user" "user43" {
  user_principal_name = "tarun@${var.upn_suffix}"
  display_name        = "Tarun Peterson"
  mail_nickname       = "tarun"
  password            = local.creds
}

resource "azuread_user" "user44" {
  user_principal_name = "lloyd@${var.upn_suffix}"
  display_name        = "LLoyd Lin"
  mail_nickname       = "lloyd"
  password            = local.creds
}

resource "azuread_user" "user45" {
  user_principal_name = "clara@${var.upn_suffix}"
  display_name        = "Clara Valencia"
  mail_nickname       = "clara"
  password            = local.creds
}

resource "azuread_user" "user46" {
  user_principal_name = "ben@${var.upn_suffix}"
  display_name        = "Ben Barton"
  mail_nickname       = "ben"
  password            = local.creds
}

resource "azuread_user" "user47" {
  user_principal_name = "honor@${var.upn_suffix}"
  display_name        = "Honor Walker"
  mail_nickname       = "honor"
  password            = local.creds
}

resource "azuread_user" "user48" {
  user_principal_name = "samantha@${var.upn_suffix}"
  display_name        = "Samantha Hampton"
  mail_nickname       = "samantha"
  password            = local.creds
}

resource "azuread_user" "user49" {
  user_principal_name = "darius@${var.upn_suffix}"
  display_name        = "Darius Campbell"
  mail_nickname       = "darius"
  password            = local.creds
}

resource "azuread_user" "user50" {
  user_principal_name = "margo@${var.upn_suffix}"
  display_name        = "Margon Stephenson"
  mail_nickname       = "margo"
  password            = local.creds
}

resource "azuread_user" "user51" {
  user_principal_name = "moses@${var.upn_suffix}"
  display_name        = "Moses Alcock"
  mail_nickname       = "moses"
  password            = local.creds
}

resource "azuread_user" "user52" {
  user_principal_name = "wilfred@${var.upn_suffix}"
  display_name        = "Wilfred Hodson"
  mail_nickname       = "wilfred"
  password            = local.creds
}

resource "azuread_user" "user53" {
  user_principal_name = "charlotte@${var.upn_suffix}"
  display_name        = "Charloette Orr"
  mail_nickname       = "charlotte"
  password            = local.creds
}

resource "azuread_user" "user54" {
  user_principal_name = "king@${var.upn_suffix}"
  display_name        = "King Vega"
  mail_nickname       = "king"
  password            = local.creds
}

resource "azuread_user" "user55" {
  user_principal_name = "jena@${var.upn_suffix}"
  display_name        = "Jena Wheeler"
  mail_nickname       = "jen"
  password            = local.creds
}

resource "azuread_user" "user56" {
  user_principal_name = "conrad@${var.upn_suffix}"
  display_name        = "Conrad McCullough"
  mail_nickname       = "conrad"
  password            = local.creds
}

resource "azuread_user" "user57" {
  user_principal_name = "derrick@${var.upn_suffix}"
  display_name        = "Derrick Barnett"
  mail_nickname       = "derrick"
  password            = local.creds
}

resource "azuread_user" "user58" {
  user_principal_name = "gary@${var.upn_suffix}"
  display_name        = "Gary Edmonds"
  mail_nickname       = "gary"
  password            = local.creds
}

resource "azuread_user" "user59" {
  user_principal_name = "valerie@${var.upn_suffix}"
  display_name        = "Valerie Quinn"
  mail_nickname       = "valerie"
  password            = local.creds
}

resource "azuread_user" "user60" {
  user_principal_name = "diego@${var.upn_suffix}"
  display_name        = "Diego Ponce"
  mail_nickname       = "diego"
  password            = local.creds
}

resource "azuread_user" "user61" {
  user_principal_name = "kurt@${var.upn_suffix}"
  display_name        = "Kurt Sosa"
  mail_nickname       = "kurt"
  password            = local.creds
}

resource "azuread_user" "user62" {
  user_principal_name = "bryan@${var.upn_suffix}"
  display_name        = "Bryan Webber"
  mail_nickname       = "bryan"
  password            = local.creds
}
