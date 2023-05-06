# Terraform Coding Exercise

Terraform Coding Exercise for Cisco's SRE position for the XDR Data team.

## Assignment

**Your task is to troubleshoot the root module and calling module such that the terraform apply succeeds. Feel free to refactor the code as you see fit.**

## Observations

This TF module appears to define a basic AWS VPC, an internal and external subnet,
and binds them together across three (of six) AZs within us-east-1. 

I see that the specified version for Terraform is 0.12. I performed my testing with
1.4/0.14, and some of the options specified have becomed deprecated. You should be 
able to see in the commit history where I removed the deprecated features and revert
them fairly quickly.

### Possible Refactoring Opportunity

I also saw the `count` idiom used a lot. I've run into problems with it in the past
when parallel lists get out of sync (in this case, the `public_subnet_cidr_blocks`,
`private_subnet_cidr_blocks`, and `availability_zones` lists), and also if someone
adds or, worse, removes something from the middle of the list; Terraform can get
confused and start to redefine everything after the removed item, usually
destructively. With these kinds of parallel lists, I'd prefer to use a nested data
construct and feed it into a `for_each`, something like this:

```terraform
variable "vpcs" {
    default = {
        "us-east-1a" = {
            public_subnet_cidr_block  = "172.33.10.0/24"
            private_subnet_cidr_block = "172.33.100.0/24"
        }
        "us-east-1b" = {
            public_subnet_cidr_block  = "172.33.20.0/24"
            private_subnet_cidr_block = "172.33.110.0/24"
        }
        "us-east-1c" = {
            public_subnet_cidr_block  = "172.33.30.0/24"
            private_subnet_cidr_block = "172.33.120.0/24"
        }
    }
}
```

You could then reference, for instance, "${lookup(vpcs.vpcs["us-east-1"]
public_subnet_cidr_block)}", and so on (forgive any syntax errors, I didn't run
that through a parser). You could then use a `for_each` idiom instead of `count` and
not have to worry as much about ordering. This wouldn't be a good use-case for
flattening the map for a Cartesian product of the values, since it really is a 1:1:1
relationship among the three parallel variables (i.e., each AZ should have its own
CIDR blocks and not share them, lest sadness visit your on-call).

I chose not to refactor the entire thing as above, since I don't want to gold-plate
the thing, and it currently works in my testing environment. We can refactor later, 
if it makes sense to revisit it.

## Testing Setup

Because my personal AWS account is too old to take advantage of the Free Tier, I
chose to test my code using [LocalStack](https://localstack.cloud), which sets up a
mock AWS infrastructure on your local system under Docker. I was able to use their
`tflocal` and `awslocal` wrapper scripts to approximate "live" Terraform and AWS CLI
calls, and the results looked about as I expected once `tflocal plan && tflocal
apply` ran cleanly. I also destroyed and rebuilt the entire stack (`localstack 
stop && localstack start` made it easy) to show that my results were repeatable.