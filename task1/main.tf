# 1. Створення VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.10.10.0/24"
  enable_dns_hostnames = true # Допомагає з ідентифікацією вузла
  tags                 = { Name = "${var.surname}-vpc" }
}

# 2. Створення публічної підмережі (Subnet)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.10.0/25"
  map_public_ip_on_launch = true # Автоматично дає публічний IP
  availability_zone       = "eu-central-1a"
  tags                    = { Name = "${var.surname}-subnet" }
}

# 3. Інтернет-шлюз (IGW)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.surname}-igw" }
}

# 4. Таблиця маршрутизації (шлях до інтернету через IGW)
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "${var.surname}-route-table" }
}

# Прив'язка таблиці маршрутів до підмережі
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

# 5. Налаштування фаєрвола (Security Group)
resource "aws_security_group" "firewall" {
  name   = "${var.surname}-firewall"
  vpc_id = aws_vpc.main.id

  # Дозволяємо вхід по SSH для Ansible
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ДОЗВОЛЯЄМО ВХІД ДЛЯ KUBERNETES NODEPORT (Завдання 3)
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Дозволяємо вихід в інтернет (для завантаження Docker/K8s)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 6. Реєстрація ключа
resource "aws_key_pair" "shram_key" {
  key_name   = "shram-deployer-key"
  public_key = file("${path.module}/../task2/id_rsa.pub")
}

# 7. Віртуальна машина (EC2 Node)
resource "aws_instance" "node" {
  ami                         = "ami-0084a47cc718c111a" # Ubuntu 24.04
  instance_type               = "t3.medium"             # Для Minikube
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.firewall.id]
  key_name                    = aws_key_pair.shram_key.key_name
  associate_public_ip_address = true # Обов'язково для зовнішнього доступу

  tags = { Name = "${var.surname}-node" }
}

# 8. Бакет S3
resource "aws_s3_bucket" "state_bucket" {
  bucket = lower("${var.surname}-bucket-task-unique-id")
}