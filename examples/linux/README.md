## Single Linux Instance with 2 second disks


```hcl
locals {
  subnet_id = yandex_vpc_subnet.subnet-1.id
}

module "dev" {
  source       = "github.com/patsevanton/terraform-yandex-compute.git?ref=main"
  image_family = "ubuntu-2004-lts"
  subnet_id    = local.subnet_id
  zone         = var.yc_zone
  name         = "dev"
  hostname     = "dev"
  is_nat       = true
  description  = "dev"
  labels = {
    environment = "development"
    scope       = "dev"
  }
  secondary_disk = {
    "var" = {
      "size"        = "1"
      "auto_delete" = true
    },
    "data" = {
      "size"        = "2"
      "auto_delete" = true
    }
  }
  depends_on = [yandex_vpc_subnet.subnet-1]
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
