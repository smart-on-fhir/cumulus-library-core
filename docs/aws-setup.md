<!-- Target audience: 
    - clinical researcher, low AWS familiarity
    - engineer w/ some AWS experience
reference tone -->
# AWS setup

Cumulus library executes queries against an 
[Amazon Athena](https://aws.amazon.com/athena/) datastore. A
[sample database](https://github.com/smart-on-fhir/cumulus-library-sample-database)
for creating such a datastore is available for testing purposes if you don't
already have one.

The cloudforamtion template in the sample database's Cloudformation template should
have the appropriate permissions set for all the services. If you need to configure
an IAM policy manually, you will need to ensure the AWS profile you are using has
the following permissions:

- Glue access to starting/stopping crawlers
- Glue Get/create database permission for your glue catalog and the database
- Glue CRUD permissions for tables and partitions for the catalog, database, and all tables
- Athena CRUD query access and queing permissions
- S3 CRUD access to your ETL bucket (along with any secrets/kms keys)

A [sample IAM policy](./sample-iam-policy.json) for this use case is available as
a starting point.

## Local AWS configuration

The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
has some built in hooks that allow applications to seamlessly connect to AWS services.
If you are going to be using AWS services for more than just Cumulus, we recommend
following the 
[CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
as well as the 
[configuration and credentials guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
so that anything on your system can successfully communicate with AWS.

If you are only using AWS for Cumulus, it may be simpler to configure environment
variables containing your credential information. The relevant ones are:
- `CUMULUS_LIBRARY_PROFILE` : The profile name ('default' is usually the right value,
unless your organization is using advanced credential management.)
- `CUMULUS_LIBRARY_REGION` : The AWS region your bucket is in (usually us-east-1 unless your organization has selected another)

In both cases, there are several additional parameters you will need to configure
to specify where your database information lives. Unless you are using multiple
library instances, you will want to specify these values  
- `CUMULUS_LIBRARY_SCHEMA` : The name of the schema Athena will use ('cumulus_library_sample_db' if using the sample DB)
- `CUMULUS_LIBRARY_S3` : The URL of your S3 bucket 
  ('s3://cumulus_library_sample_db-(AWS account ID)-(AWS region)' if using sample db)
- `CUMULUS_LIBRARY_PROFILE` : the Athena profile to execute queries in ('cumulus_library_sample_db' if using the sample DB)

Configuring environment variables on your system is out of scope of this document, but several guides are available elsewhere. [This guide](https://www.twilio.com/blog/2017/01/how-to-set-environment-variables.html), for example, covers Mac, Windows, and Linux. And, as a plus, it has a picture of an adorable puppy at the top of it.