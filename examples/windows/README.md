## Single Windows Instance

```hcl
data "template_file" "userdata_win" {
  template = file("user_data.tpl")
  vars = {
    windows_password = "password"
  }
}

resource "yandex_vpc_network" "network-01" {
  name = "network-01"
}

resource "yandex_vpc_subnet" "subnet-01" {
  name           = "subnet-pdc-01"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-01.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

locals {
  subnet_id = yandex_vpc_subnet.subnet-01.id
}

module "pdc" {
  source             = "github.com/patsevanton/terraform-yandex-compute.git?ref=main"
  image_family       = "windows-2022-dc-gvlk"
  subnet_id          = local.subnet_id
  zone               = var.yc_zone
  name               = "pdc"
  hostname           = "pdc"
  is_nat             = true
  description        = "pdc"
  user-data          = data.template_file.userdata_win.rendered
  type_remote_exec   = "winrm"
  user               = "Administrator"
  password           = "password"
  https              = true
  port               = 5986
  insecure           = true
  timeout            = "15m"
  serial-port-enable = 1
  size               = 50
  labels = {
    environment = "development"
    scope       = "testing"
  }
  depends_on = [yandex_vpc_subnet.subnet-01]
}
```

#### user_data.tpl:
```
<powershell>
net user Administrator "${windows_password}"
$chocoInstallScriptUrl  = 'https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'
$chocoInstallScript     = Join-Path $env:Temp 'SetupComplete.ps1'

Set-ExecutionPolicy Unrestricted

$downloader = New-Object System.Net.WebClient
$downloader.DownloadFile($chocoInstallScriptUrl, $chocoInstallScript)

& $chocoInstallScript
</powershell>
```

