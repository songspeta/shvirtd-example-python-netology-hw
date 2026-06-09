terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
provider "yandex" {
  service_account_key_file = var.yc_token_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
}

variable "yc_token_path" {
  description = "Path to Yandex Cloud service account key file"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key for VM access"
  type        = string
}

resource "yandex_vpc_security_group" "machine-1" {
  name        = "machine-1"
  description = "Security group for machine-1"
  network_id  = yandex_vpc_network.main.id


  # Входящий: SSH
  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

    # Входящий: HTTP для приложения (nginx на 8090)
  ingress {
    description    = "HTTP app"
    protocol       = "TCP"
    port           = 8090
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Исходящий: любой трафик
  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}


# Создаём облачную сеть
resource "yandex_vpc_network" "main" {
  name        = "network"
  description = "Main network for machine-1"
}

# Публичная подсеть Zone A
resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

# Получаем ID образа Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = "container-optimized-image"
}




resource "yandex_compute_instance" "machine-1" {

  # Имя ВМ
  name        = "machine-1"
  hostname    = "machine-1"
  description = "machine-1"

  # Зона
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
      size     = 20
    }
  }

  # Подсеть
  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.machine-1.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = true
  }

  allow_stopping_for_update = true
}

