# Terraform module for Yandex.Cloud Compute
Terraform module is beta version. Use it at your own risk and check that it does what you want it to do.

Module is fork repositories:
- https://github.com/terraform-aws-modules/terraform-aws-ec2-instance
- https://github.com/glavk/terraform-yandex-compute

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| yandex | 0.73.0  |

## Contributing

The following guidelines must be followed by all contributors to this repository. Please review them carefully and do not hesitate to ask for help.

### Type

The *type* should always be lowercase as shown below.

#### Allowed `<type>` values:

* **breaking: msg** (a commit that has the text BREAKING CHANGE: at the beginning of its optional body or footer section introduces a breaking API change)
* **chore: msg** (updating build/env/packages, etc; no production code change)
* **ci: msg** (changes to our CI configuration files and scripts )
* **docs: msg** (changes to documentation)
* **feat: msg** (new feature for the user)
* **fix: msg** (bug fix for the user, not a fix to build scripts)
* **refactor: msg** (refactoring production code, eg. renaming a variable)
* **security: msg** (fix security vulnerabilities)
* **style: msg** (formatting, missing semi colons, etc; no functional code change)
* **test: msg** (adding missing tests, refactoring tests; no production code change)


## Usage
### Single Linux Instance with 2 second disks

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

### Single Windows Instance

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

## Inputs

| Name                    | Description                                                                                                                                                                                                                                                                                                             | Type               | Default               | Required |
| ----------------------- |-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| ------------------ | --------------------- | :------: |
| `allow_stopping_for_update` | If true, allows Terraform to stop the instance in order to update its properties. If you try to update a property that requires stopping the instance without setting this field, the update will fail.                                                                                                                 | `bool`             | `false`               |    no    |
| `core_fraction`         | Baseline performance for a core as a percent                                                                                                                                                                                                                                                                            | `number`           | `100`                 |    no    |
| `cores`                 | CPU cores for the instance                                                                                                                                                                                                                                                                                              | `number`           | `2`                   |    no    |
| `description`           | Description of the instance                                                                                                                                                                                                                                                                                             | `string`           | n/a                   |    no    |
| `folder_id`             | The ID of the folder that the resource belongs to. If it is not provided, the default provider folder is used.                                                                                                                                                                                                          | `string`           | n/a                   |    no    |
| `hostname`              | Host name for the instance. This field is used to generate the instance fqdn value                                                                                                                                                                                                                                      | `string`           | n/a                   |   yes    |
| `https`                 | Set to `true` to connect using HTTPS instead of HTTP for WinRM.                                                                                                                                                                                                                                                         | `string`           | n/a                   |    no    |
| `image_family`           | Yandex Cloud Compute Image family                                                                                                                                                                                                                                                                                       | `string`           | n/a                   |   yes    |
| `insecure`              | Set to `true` to skip validating the HTTPS certificate chain WinRM.                                                                                                                                                                                                                                                     | `bool`             | `false`               |    no    |
| `instance_count`        | The `instance_count` meta-argument accepts a whole number, and creates that many instances of the resource or module.                                                                                                                                                                                                   | `number`           | 1                     |    no    |
| `ip_address`            | The private IP address to assign to the instance. If empty, the address will be automatically assigned from the specified subnet.                                                                                                                                                                                       | `number`           | n/a                   |    no    |
| `is_nat`                | Provide a public address for instance to access the internet over NAT                                                                                                                                                                                                                                                   | `bool`             | `false`               |    no    |
| `labels`                | A set of key/value label pairs to assign to the instance.                                                                                                                                                                                                                                                               | `map(string)`      | {}                    |    no    |
| `memory`                | Memory size for the instance in GB                                                                                                                                                                                                                                                                                      | `number`           | `2`                   |    no    |
| `name`                  | Yandex Cloud Compute (VM) name                                                                                                                                                                                                                                                                                          | `string`           | n/a                   |   yes    |
| `nat_ip_address`        | Public IP address for instance to access the internet over NAT                                                                                                                                                                                                                                                          | `string`           | `""`                  |    no    |
| `password`              | The password to use for the connection.                                                                                                                                                                                                                                                                                 | `string`           | n/a                   |    no    |
| `platform_id`            | The type of virtual machine to create                                                                                                                                                                                                                                                                                   | `string`           | `"standard-v3"`       |    no    |
| `port`                  | The port to connect to. `22` for type `"ssh"` `5985 or 5986` for type `"winrm"`                                                                                                                                                                                                                                         | `string`           | `22`                  |    no    |
| `preemptible`           | Specifies if the instance is preemptible                                                                                                                                                                                                                                                                                | `bool`             | `false`               |    no    |
| `private_key`           | The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the `file` function. This takes preference over `password` if provided.                                                                                         | `string`           | `"~/.ssh/id_rsa"`     |    no    |
| `secondary_disk`        | A list of disks to attach to the instance. The structure is documented below. **Note**: The `allow_stopping_for_update` property must be set to true in order to update this structure. | `map(map(string))` | `{}`                  |    no    |
| `serial-port-enable`    | Serial-port-enable parameter for metadata                                                                                                                                                                                                                                                                               | `number`           | `null`                |    no    |
| `size`                  | Size of the boot disk in GB                                                                                                                                                                                                                                                                                             | `string`           | `"10"`                |    no    |
| `type`                  | Type of the boot disk                                                                                                                                                                                                                                                                                                   | `string`           | `"network-ssd"`       |          |
| `ssh_pubkey`            | SSH public key for access to the instance                                                                                                                                                                                                                                                                               | `string`           | `"~/.ssh/id_rsa.pub"` |    no    |
| `subnet_id`             | Yandex VPC subnet id                                                                                                                                                                                                                                                                                                    | `string`           | n/a                   |   yes    |
| `timeout`               | The timeout to wait for the connection to become available. Should be provided as a string (e.g., `"30s"` or `"5m"`.)                                                                                                                                                                                                   | `string`           | `"5m"`                |    no    |
| `type`                  | Type of the boot disk                                                                                                                                                                                                                                                                                                   | `string`           | `"network-ssd"`       |    no    |
| `type_remote_exec`      | The connection type. Valid values are `"ssh"` and `"winrm"`. Provisioners typically assume that the remote system runs Microsoft Windows when using WinRM.                                                                                                                                                              | `string`           | `"ssh"`               |    no    |
| `user`                  | User for access to the instance. If type `"winrm"`, then use  `Administrator`                                                                                                                                                                                                                                           | `string`           | `ubuntu`              |    no    |
| `user-data`             | User-data parameter for metadata                                                                                                                                                                                                                                                                                        | `string`           | `""`                  |    no    |
| `zone`                  | Yandex Cloud Zone for provisoned resources                                                                                                                                                                                                                                                                              | `string`           | n/a                   |    no    |

## Outputs

| Name | Description |
|------|-------------|
| compute\_instance\_external\_ip | The external IP address of the instance |
| compute\_instance\_fqdn | The fully qualified DNS name of this instance |
| compute\_instance\_internal\_ip | The internal IP address of the instance |
