## Terraforming Infoblox in Azure - Infrastructure as code  

While working on automating the IPAM deployment in azure i came across this blog post by Infoblox engineer [Jason Radebaugh's Blog](https://blogs.infoblox.com/community/take-your-infrastructure-as-code-to-the-next-level-with-infoblox-and-terraform/)

There is a terraform manifest at the end of the blog which basically sets up the Infoblox IPAM with a fully functioning Azure environment including resource groups, virtual networks, security groups, storage accounts and vnios instance. 

## 📬 So what's the issue

The  author of the blog had provided a fully working terraform codebase but i had problems after i deployed the code.

- **Issue#1** - I cannot login to the cli/serial console with the given password in os_profile block in the terraform code

- **Issue#2** - Since i can't login, i was unable to see and set the temp licenses to get me going before connecting to IPAM grid

While reviewing the code, it was clear that the admin username and password is not being passed onto cloud-init script used by infobox vnios vm as well as the temp liceneses is not being enabled. 


## 👉🏻👉🏻 Now, the solution

In reviewing multiple cloud init scripts used by Infoblox for deploying vnios, i found the following variables needs to be passed to cloud init script. 

   >- remote_console_enabled - Enables console remote access  
   >- default_admin_password - Enables CLI access to vnios instance
   >- temp_license           - Enables temporary license for grid, dns and dhcp

In Azure, a variable or custom data can be passed to cloud-init script using the *custom_data* block. A *custom_data* block can be used to pass user data to a virtual machine instance. *custom_data* block is similar to user_data block used by terraform aws provider. Terraform will base64 encode this value but it is a good practice base64encode in terraform as a best practice. In this specific case, Infoblox vnios marketplace image is based on linux kernel and hence he *custom_data* block to pass the variables and values to cloud-init script. *custom_data* block is configured inside the *os_profile* block  in *azurerm_virtual_machine* resource type. 

## :zap: Updated Code
A snippet of os_profile should look like this
```
    os_profile {
        computer_name  = "vnios-tf1"
        admin_username = "madmin"
        admin_password = "Infoblox_1"
        ## The custom_data column is required to pass the values to cloud-init script used by Infoblox 
        # remote_console_enabled - Enables console remote access  
        # default_admin_password - Enables CLI access to vnios instance
        # temp_license           - Enables temporary license for grid, dns and dhcp
        custom_data    = base64encode("remote_console_enabled: y\ndefault_admin_password: Infoblox_1\ntemp_license: dns dhcp grid")
  }
```

The *admin_username* and *admin_password* identifiers have no meaning but terraform would fail basic check since they are required identifiers for *os_profile* block

Once the deployment is complete, verify the serial console has posted messages related to variables that were passed to cloud-init script. An example screenshot of serial console is below

![OUTPUT](https://github.com/r2rajan/Infoblox-Terraform-Azure/blob/main/output.jpg)

## Disclaimer
I have hardcoded the credential in the  terraform configuration and it's a bad practice. A good security practice is to store the usernames and secrets/credentials in azure key vault and accessing the secret through a keyvault data resource. 
