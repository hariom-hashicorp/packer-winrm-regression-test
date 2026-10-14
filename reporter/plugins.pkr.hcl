packer {
required_plugins {
amazon = {
version = "1.8.3"
source = "github.com/hashicorp/amazon"
}
azure = {
version = "2.6.4"
source = "github.com/hashicorp/azure"
}
vsphere = {
version = "> 1"
source = "github.com/hashicorp/vsphere"
}
windows-update = {
version = "> 0.14"
source = "github.com/rgl/windows-update"
}
}
}
