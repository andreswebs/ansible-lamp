# LAMP Instance Deployment Pipeline

## Pipeline

**AWS CodePipeline**

The code pipeline has the following structure:

|      Source            -->|      Build              |
|---                        |---                      |
|      Github               |      AWS CodeBuild      |

Deployment happens from inside the `scripts/build.sh` script on AWS CodeBuild, directly to a server instance via ansible.

The playbook at `infrastructure/lamp.playbook.yml` can be run locally if the needed files and variables are present in the local machine.

If stored locally, the relevant files will be ignored by `git` through the configured `.gitignore` files.

## Directory structure

The following files and directories are needed at the root of the code repository:

- buildspec.yml        : required by AWS CodeBuild
- scripts/             : shell scripts used by various pipeline steps
- infrastructure/      : used during the Build step to enforce instance configuration
- app/                 : the application code

## References

<https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html>
