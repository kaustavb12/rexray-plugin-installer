[![Build](https://github.com/kaustavb12/rexray-plugin-installer/actions/workflows/docker-image.yml/badge.svg)](https://github.com/kaustavb12/rexray-plugin-installer/actions?query=workflow%3ABuild)

## Rexray Plugin Installer

Docker image with embedded shell script to install or update Rexray plug-in to nodes in Docker Swarm Clusters

*Currently only `rexray/dobs` and `rexray/s3fs` plug-ins are supported. Support for other rexray plug-ins to be included later.*

##

### Usage

```
install-plugin.sh --driver <plugin> [--version <plugin-version>] [--update] DRIVER-OPTIONS
```

`--driver <plugin>` **Mandatory** Rexray plugin driver. Currently only `dobs` and `s3fs` are supported.

`--version <plugin-version>` **Optional** The plug-in version tag to installed. Can be either *latest* or specific tag like *0.11.4*

`--update` **Optional** Force Update installed plug-in irrespective of plug-in version installed

### rexray/dobs Driver Options

`--do-secret <do_token_secret>` **Mandatory** Docker secret holding the DigitalOcean Access Token to be used to set DOBS_TOKEN. **Do not use the actual API Token.** It is assumed that the secret is mounted in the default location */run/secrets/<do_token_secret>*

`--do-region <do_region>` **Mandatory** Set DOBS_REGION - The region where volumes should be created. Example : *blr1, fra1, nyc3*, etc.

`--do-convert-underscore` **Optional** Set DOBS_CONVERTUNDERSCORES to *true*

`--do-init-delay <time>` **Optional** Set DOBS_STATUSINITIALDELAY - Time duration used to wait when polling volume status

`--do-max-attempts <count>` **Optional** Set DOBS_STATUSMAXATTEMPTS - Number of times the status of a volume will be queried before giving up

`--do-status-timeout <time>` **Optional** Set DOBS_STATUSTIMEOUT - Maximum length of time that polling for volume status can occur

`--http-proxy <proxy_endpoint>` **Optional** Set HTTP_PROXY - Address of HTTP proxy server to gain access to API endpoint

### rexray/s3fs Driver Options

`--aws-accesskey-secret <s3_accesskey_secret>` **Mandatory** Docker Secret holding the AWS Access Key ID to be used to set S3FS_ACCESSKEY. **Do not use the actual API Token.** It is assumed that the secret is mounted in the default location */run/secrets/<s3_accesskey_secret>*

`--aws-secretkey-secret <s3_secretkey_secret>` **Mandatory** Docker Secret holding the AWS Secret Access Key to be used to set S3FS_SECRETKEY. **Do not use the actual API Token.** It is assumed that the secret is mounted in the default location */run/secrets/<s3_secretkey_secret>*

`--s3-disable-pathstyle` **Optional** Set S3FS_DISABLEPATHSTYLE to *true*

`--s3-max-retry <count>` **Optional** Set S3FS_MAXRETRIES - The number of retries that will be made for failed operations by the AWS SDK

`--s3-region <s3_region>` **Optional** Set S3FS_REGION - The AWS region. Example : *ap-south-1, ap-east-1, us-east-2*, etc.

`--s3-options <s3_options>` **Optional** Set S3FS_OPTION - Additional options to pass to S3FS

`--http-proxy <proxy_endpoint>` **Optional** Set HTTP_PROXY - Address of HTTP proxy server to gain access to API endpoint

##

### Script Behaviour

1. If no version using the `--version` option is provided, the script installs plug-in using `latest` tag to nodes where plug-in is not already installed. If plug-in is already installed, then no action is taken.

2. If latest is provided as version `--version latest`, the script installs plug-in using `latest` tag to nodes. If plug-in is already installed, script updates the plug-in with `latest` tag.

3. If specific version is provided `--version 0.11.4`, the script installs plug-in using that specific tag to nodes. If plug-in is already installed, script checks the tag of the installed plug-in. If the installed tag does not match the provided tag (including installed tag being `latest`), then the plug-in is updated using the provided tag.

4. If force update option `--update` is used, the script updates plug-in already installed irrespective of the installed tag and provided tag. If plug-in is not already installed, then it is installed with appropriate tag. This is useful if any driver options need to be updated without changing the version tag.

**NOTE:** *To update an already installed plug-in, the plug-in is first removed and then re-installed with appropriate tag and options.*