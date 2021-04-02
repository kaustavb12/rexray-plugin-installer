## Rexray Plugin Installer

Docker image with embedded shell script to install or update Rexray plug-in to nodes in Docker Swarm Clusters

*Currently only `rexray/dobs` plug-in is supported. Support for other rexray plug-ins to be included later.*

### Usage

```
./install-plugin.sh [-v <driver-version>] [-u] <do-token-secret> <do-region>
```

`<do-token-secret>` **Mandatory** Docker secret holding the DigitalOcean API Token. **Do not use the actual API Token.** It us assumed that the secret is mounted in the default location `/run/secrets/<do-token-secret>`

`<do-region>` **Mandatory** Digital Ocean region where the volume should be created. Example : `blr1`,`fra1`,`nyc3`,etc.

`-v <driver-version>` **Optional** The plug-in version tag to installed. Can be either `latest` or specific tag like `0.11.4`

`-u` **Optional** Force Update installed plug-in irrespective of plug-in version installed


### Script Behaviour

1. If no version `-v <driver-version>` is provided, the script installs plug-in using `latest` tag to nodes where plug-in is not already installed. If plug-in is already installed, then no action is taken.

2. If latest is provided as version `-v latest`, the script installs plug-in using `latest` tag to nodes. If plug-in is already installed, script updates the plug-in with `latest` tag.

3. If specific version is provided `-v 0.11.4`, the script installs plug-in using that specific tag to nodes. If plug-in is already installed, script checks the tag of the installed plug-in. If the installed tag does not match the provided tag (including installed tag being `latest`), then the plug-in is updated using the provided tag.

4. If force update option `-u` is used, the script updates plug-in already installed irrespective of the installed tag and provided tag. If plug-in is not already installed, then it is installed with appropriate tag. This is useful if either API Token or DO Region needs to be updated without changing the version tag.

5. To update an already installed plug-in, the plug-in is first removed and then re-installed with appropriate tag.