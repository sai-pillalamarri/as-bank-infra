locals {
  services = {
    customer = {
      service_name  = "customer-service"
      database_name = "customer_service"
      username      = "customer_service"
    }

    account = {
      service_name  = "account-service"
      database_name = "account_service"
      username      = "account_service"
    }

    transaction = {
      service_name  = "transaction-service"
      database_name = "transaction_service"
      username      = "transaction_service"
    }
  }

  postgresql_port       = 5432
  allocated_storage_gib = 20
}
