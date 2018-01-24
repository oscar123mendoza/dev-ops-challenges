# tastyworks DevOps Code Challenge

## Introduction

**Please choose one or more challenges, fork this repo, and implement your solution in the appropriate directory.**

Explain your solution in the README as you would for documenting your code to hand off to a team and to answer the bonus questions if you choose.

These challenges should be considered in an alpha state and as such, feedback / communication throughout the process of solving them is welcome and encouraged.

## Challenge One (Terraform)

### Description

Most basic web applications can start with a straightforward architecture:
1. A load balancer
1. Two application servers
1. A database server

Please write a collection of Terraform resource defintions which provisions the necessary AWS infrastructure to deploy this application onto. You'll want to create a load balancer, two EC2 instances and a Postgresql RDS instance. You'll also need to provision a basic VPC and security groups that allow traffic to land on the load balancer's public IP, flow through the load balancer to the application servers and for the application servers to connect to the database server.

### Key Points
* We will provide an AWS account and user credential set for you to use during the exercise. Please don't be a jerk and use it for anything other than the exercise.
* Your definitions should specify the smallest instances / cheapest configuration options.
* You can stand up instances and tear them down at will during the exercise. As a part of evaluating your work, we'll tear whatever is running downm, run a `terraform plan` and a `terraform apply` and expect that the end product is exactly what we expect.
* There will not be any actual applications deployed to the app servers, but we should be able to connect to the RDS instance from the app servers.
* Readability and code structure are important, as is general thoughtfulness as if this were a production micro-site.

### Bonus
1. Explain in your README how you'd expand the architecture to work across multiple availability zones.
1. Explain in your README how you'd set up a replicated database.

## Challenge Two (Chef)

### Description
Most basic web applications can start with a straightforward architecture:
1. A load balancer
1. Two application servers
1. A database server

Please write a collection of Chef recipes in one or more cookbooks (following an organizational pattern of your choice) which can be used to configure each of the above as follows

1. Load Balancer:
    1. Install [HAProxy](http://www.haproxy.org/) or [Nginx](https://www.nginx.com/) (use of a [community](https://supermarket.chef.io/cookbooks/haproxy) [cookbook](https://supermarket.chef.io/cookbooks/nginx) is completely acceptable.)
    1. Write a basic configuration file that accepts connections on port 8080 connects to the two application servers on the port or ports they are listening on. Don't worry about SSL.
    1. Ensure the service is started and ready to forward traffic to the application servers
1. Application Servers
    1. Install the Unicorn application server and write out a basic configuration to serve the simple application provided here: (GitHub Repo tbd.)
1. Database server
    1. Install and start Postgres with a default configuration
    1. Allow Postgres to accept inbound connections from an arbitrary network where your application servers will live, using a specific username and password for the application servers

### Expectations
1. All of your code should run in a TestKitchen environment and converge successfully
1. Getting the entire stack to boot up in a TestKitchen environment is a plus, but ensuring each individual node converges is a requirement
1. We will evaluate the overall structure of your cookbook or cookbooks as well as the use of Chef's built-in organizational components and cross-recipe communication.

### Bonus
1. Explain in your README how you would ensure that a new application server is discovered by the load balancer without any explicit definitions for it in the load balancer recipe(s).
1. Explain how you would extract environment-specific configuration to allow the same set of recipes to be applied across a multi-stage deployment environment.

