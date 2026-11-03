mock_provider "aws" {}

variables {
  name               = "test"
  cidr_block         = "10.40.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

run "ha_one_nat_per_az" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Debe existir un NAT Gateway por AZ en modo HA."
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3
    error_message = "Debe existir una subnet pública y una privada por AZ."
  }
}

run "public_subnets_do_not_assign_public_ips" {
  command = plan

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Las subnets públicas no deben asignar IP pública automáticamente."
  }
}

run "subnets_do_not_overlap" {
  command = plan

  assert {
    condition     = aws_subnet.public["us-east-1a"].cidr_block == "10.40.0.0/24" && aws_subnet.private["us-east-1a"].cidr_block == "10.40.16.0/20"
    error_message = "El esquema de direccionamiento no es el esperado."
  }
}

run "single_nat_for_cost_saving" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway=true debe crear un único NAT."
  }
}

run "rejects_single_az" {
  command = plan

  variables {
    availability_zones = ["us-east-1a"]
  }

  expect_failures = [var.availability_zones]
}
