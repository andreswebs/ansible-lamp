# Lightsail Deployment Pipeline

## Pipeline

**AWS CodePipeline**

The code pipeline has the following structure:

|      Source            -->|      Build              |
|---                        |---                      |
|      Github               |      AWS CodeBuild      |

Deployment happens from inside the `scripts/build.sh` script directly to Lightsail.

## Directory structure

The following files and directories are needed at the root of the code repository:

- buildspec.yml        : required by AWS CodeBuild
- scripts/             : shell scripts used by various pipeline steps
- infrastructure/      : used during the Build step to enforce instance configuration
- app/                 : the application code

## References

<https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html>
