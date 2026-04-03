terraform {
  backend "s3" {
    bucket = "shram-devops-exam-state" # Якщо ти створив бакет з іншою назвою в консолі AWS — впиши її сюди
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}