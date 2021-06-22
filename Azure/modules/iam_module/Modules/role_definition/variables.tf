variable "subscriptionID" {
  description = ""
  default = string
}

variable "enviroment" {
    description = "Value of the enviroment"
    type = map
    default = {

        "infra" = "string"
        "env" = "string"
    }
    validation = {
        condition     = var.Enviroment == "Dev" || var.Enviroment == "QA" || var.Enviroment == "Test" || var.Enviroment == "Prod"
        error_message = "The Enviroment value is invalid, Allow value (Dev,QA,Test,Prod)"
    }    
  
}