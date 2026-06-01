# Terraform-Konfiguration: S3-Bucket
# Diese Datei ist ein Template mit Platzhaltern, die vom Workflow ersetzt werden.
# Platzhalter: __BUCKET_NAME__, __REGION__, __ENVIRONMENT__, __TAG_PROJECT__

# --- Terraform- und Provider-Anforderungen ---
# Best Practice: Terraform- und Provider-Version pinnen, damit ein spaeteres
# "terraform init" nicht ungeplant eine inkompatible Provider-Version zieht.
terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Provider ---
# Die Region kommt aus dem Issue-Formular. S3-Bucket-Ressourcen selbst kennen
# kein "region"-Argument – die Region wird ueber den Provider gesetzt.
provider "aws" {
  region = "__REGION__"
}

# --- S3-Bucket Ressource ---
# Erstellt den eigentlichen Bucket. Der Name muss global eindeutig sein.
resource "aws_s3_bucket" "this" {
  bucket = "__BUCKET_NAME__"

  tags = {
    Name        = "__BUCKET_NAME__"
    Environment = "__ENVIRONMENT__"
    Project     = "__TAG_PROJECT__"
    ManagedBy   = "terraform"
  }
}

# --- Versionierung ---
# Best Practice: Versionierung aktivieren, damit versehentlich geloeschte
# oder ueberschriebene Objekte wiederhergestellt werden koennen.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Server-seitige Verschluesselung ---
# Best Practice: Alle Objekte werden automatisch mit AES-256 verschluesselt.
# Fuer hoehere Sicherheitsanforderungen kann ein KMS-Key verwendet werden.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# --- Public Access Block ---
# Best Practice: Oeffentlichen Zugriff vollstaendig blockieren.
# S3-Buckets sollten nie oeffentlich sein, es sei denn, es gibt einen
# expliziten, dokumentierten Grund (z.B. statisches Webhosting).
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
