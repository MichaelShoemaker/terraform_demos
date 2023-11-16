terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

locals {
  data_lake_bucket = "this_my_bucket"
}

resource "google_compute_instance" "default" {
  name         = "test"
  #Type of instance. Maybe make it a variable in variables.tf
  machine_type = "e2-medium"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      #OS to use
      image = "ubuntu-os-cloud/ubuntu-minimal-2204-lts"
      #Disk size in Gb
      size  = "15"
    }
  }

  metadata = {
    #User name and path to public SSH Key
    ssh-keys = "gary:${file("~/.ssh/demo_key.pub")}"
  }

  network_interface {
    #Use the default GCP VPC Network
    network = "default"
    #Give VM an Ephemeral External IP
    access_config {}
  }
}

resource "google_storage_bucket" "data-lake-bucket" {
  name     = "terraform-demo-397122-demo-bucket"
  location = "US"

  # Optional, but recommended settings:
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 // days
    }
  }

  force_destroy = true
}



resource "google_storage_bucket" "data-lake-bucket" {
  name          = "${local.data_lake_bucket}_${var.project}" 
  location      = var.region

  # Optional, but recommended settings:
  storage_class = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled     = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  // days
    }
  }

  force_destroy = true
}




resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.bigquery_dataset
  project    = var.project
  location   = var.region
}


output "public_ip_address" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}