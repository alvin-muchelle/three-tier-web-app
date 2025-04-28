locals {
  public_subnets = {
    "public-1" = {
      cidr_block        = var.public_subnet_cidrs[0]
      availability_zone = var.az_1
    }
    "public-2" = {
      cidr_block        = var.public_subnet_cidrs[1]
      availability_zone = var.az_2
    }
  }

  private_subnets = {
    "private-1" = {
      cidr_block        = var.app_private_subnet_cidrs[0]
      availability_zone = var.az_1
    }
    "private-2" = {
      cidr_block        = var.app_private_subnet_cidrs[1]
      availability_zone = var.az_2
    }
  }

  db_private_subnets = {
    "db-private-1" = {
      cidr_block        = var.db_private_subnet_cidrs[0]
      availability_zone = var.az_1
    }
    "db-private-2" = {
      cidr_block        = var.db_private_subnet_cidrs[1]
      availability_zone = var.az_2
    }
  }
}
