variable "vpc_cidr" {
    default = "10.40.0.0/16"
}

variable "env" {
    default = "dev"
}

variable "public_subnet_cidrs" {
    default = [
        "10.40.11.0/24",
        "10.40.12.0/24",
        "10.40.13.0/24"        
    ]
}

variable "private_subnet_cidrs" {
    default = [
        "10.40.21.0/24",
        "10.40.22.0/24",
        "10.40.23.0/24"         
    ]
}