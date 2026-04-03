# 1. Створення VPC [cite: 5, 6]
resource "aws_vpc" "main" {
  cidr_block = "10.10.10.0/24" # Діапазон за завданням 
  tags = { Name = "${var.surname}-vpc" }
}

# 2. Інтернет-шлюз (щоб був доступ до мережі)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# 3. Фаєрвол (Security Group) [cite: 9, 11]
resource "aws_security_group" "firewall" {
  name   = "${var.surname}-firewall"
  vpc_id = aws_vpc.main.id

  # Вхідні порти за завданням 
  dynamic "ingress" {
    for_each = [22, 80, 443, 8000, 8001, 8002, 8003]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Вихідні порти: всі [cite: 13]
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Віртуальна машина (Node) [cite: 14]
resource "aws_instance" "node" {
  ami           = "ami-0084a47cc718c111a" # AMI для Ubuntu 24.04 в eu-central-1 
  key_name      = aws_key_pair.shram_key.key_name
  instance_type = "t3.medium"            # Розмір для Minikube/K8s [cite: 15]
  tags = { Name = "${var.surname}-node" }
}

# 5. Бакет S3 [cite: 18, 19]
resource "aws_s3_bucket" "state_bucket" {
  bucket = lower("${var.surname}-bucket-task-unique-id") # Назва бакету [cite: 19]
}

# Реєструємо публічний ключ в AWS
resource "aws_key_pair" "shram_key" {
  key_name   = "shram-deployer-key"
  # Ми використовуємо функцію file, щоб Terraform сам прочитав ключ
  public_key = file("${path.module}/../task2/id_rsa.pub")
}

# Triggering CI/CD