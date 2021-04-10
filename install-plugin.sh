#!/bin/sh

BASE_USAGE="Usage: "$(basename "$0")" --driver <plugin> [--version <plugin-version>] [--update] DRIVER-OPTIONS"

PLUGIN_USAGE="REXRAY PLUGINS SUPPORTED\n
\tdobs\tDigitalOcean Block Storage\n
\ts3fs\tAWS S3"

DO_USAGE="DigitalOcean DRIVER OPTIONS\n
\t--do-secret <do_token_secret>\tDocker Secret containing DigitalOcean Access Token to be used to set DOBS_TOKEN\n
\t--do-region <do_region>\t\tSet DOBS_REGION - The region where volumes should be created\n
\t[--do-convert-underscore]\tSet DOBS_CONVERTUNDERSCORES to true\n
\t[--do-init-delay <time>]\tSet DOBS_STATUSINITIALDELAY - Time duration used to wait when polling volume status\n
\t[--do-max-attempts <count>]\tSet DOBS_STATUSMAXATTEMPTS - Number of times the status of a volume will be queried before giving up\n
\t[--do-status-timeout <time>]\tSet DOBS_STATUSTIMEOUT - Maximum length of time that polling for volume status can occur\n
\t[--http-proxy <proxy_endpoint>]\tSet HTTP_PROXY - Address of HTTP proxy server to gain access to API endpoint"

S3_USAGE="AWS S3 DRIVER OPTIONS\n
\t--aws-accesskey-secret <s3_accesskey_secret>\tDocker Secret container AWS Access Key to be used to set S3FS_ACCESSKEY\n
\t--aws-secretkey-secret <s3_secretkey_secret>\tDocker Secret container AWS Secret Key to be used to set S3FS_SECRETKEY\n
\t[--s3-disable-pathstyle]\t\t\tSet S3FS_DISABLEPATHSTYLE to true\n
\t[--s3-max-retry <count>]\t\t\tSet S3FS_MAXRETRIES - The number of retries that will be made for failed operations by the AWS SDK\n
\t[--s3-region <s3_region>]\t\t\tSet S3FS_REGION - The AWS region\n
\t[--s3-options <s3_options>]\t\t\tSet S3FS_OPTION - Additional options to pass to S3FS\n
\t[--http-proxy <proxy_endpoint>]\t\t\tSet HTTP_PROXY - Address of HTTP proxy server to gain access to API endpoint"

USAGE_ERR=$BASE_USAGE"\n\n"$PLUGIN_USAGE"\n\n"$DO_USAGE"\n\n"$S3_USAGE"\n"
PRE_INSTALLED_MSG="Plugin already installed"

LONG_OPTIONS=driver:,version:,update,do-secret:,do-region:,do-convert-underscore,do-init-delay:,do-max-attempts:,do-status-timeout:,http-proxy:,aws-accesskey-secret:,aws-secretkey-secret:,s3-disable-pathstyle,s3-max-retry:,s3-region:,s3-options:

OPTS=$(getopt --options "" --long $LONG_OPTIONS --name "$(basename "$0")" -- "$@")

if [ $? != 0 ] ; then 
    echo "Error while executing script...\n" >&2
    echo $USAGE_ERR >&2
    exit 1
fi

eval set -- "$OPTS"

FORCE_UPDATE=false
DO_CONVERT=false
S3_PATHSTYLE=false
NEW_INSTALL=false

while [ $# -gt 0 ]; do
    case "$1" in
        --driver )
            case "$2" in
                dobs )
                    PLUGIN="rexray/dobs"
                    ;;
                s3fs )
                    PLUGIN="rexray/s3fs"
                    ;;
                * )
                    echo "Invalid or Unsupported Plugin Driver\n" >&2
                    echo $USAGE_ERR >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --version )
            VERSION="$2"
        	shift 2
        	;;
        --update )
            FORCE_UPDATE=true
        	shift
        	;;
        --do-secret )
            DO_SECRET_FILE="/run/secrets/$2"
        	shift 2
        	;;
        --do-region )
            DO_REGION="$2"
        	shift 2
        	;;
        --do-convert-underscore )
            DO_CONVERT=true
        	shift
        	;;
        --do-init-delay )
            DO_DELAY="$2"
        	shift 2
        	;;
        --do-max-attempts )
            DO_ATTEMPT="$2"
        	shift 2
        	;;
        --do-status-timeout )
            DO_TIMEOUT="$2"
        	shift 2
        	;;
        --http-proxy )
            HTTP_PROXY="$2"
        	shift 2
        	;;
        --aws-accesskey-secret )
            AWS_ACCESSKEY_SECRET_FILE="/run/secrets/$2"
        	shift 2
        	;;
        --aws-secretkey-secret )
            AWS_SECRETKEY_SECRET_FILE="/run/secrets/$2"
        	shift 2
        	;;
        --s3-disable-pathstyle )
            S3_PATHSTYLE=true
        	shift
        	;;
        --s3-max-retry )
            S3_RETRY="$2"
        	shift 2
        	;;
        --s3-region )
            S3_REGION="$2"
        	shift 2
        	;;
        --s3-options )
            S3_OPTIONS="$2"
        	shift 2
        	;;
        -- )
            shift
            ;;
        * )
            echo "Invalid or Unrecognized Argument '$1'\n" >&2
            echo $USAGE_ERR >&2
            exit 1
            ;;
    esac
done

if [ -z "$PLUGIN" ] ; then
    echo "Plugin Driver Missing\n" >&2
    echo $USAGE_ERR >&2
    exit 1
elif [ "$PLUGIN" = "rexray/dobs" ] ; then
    if [ -z "$DO_SECRET_FILE" ] ; then
        echo "DO Secret Missing\n" >&2
        echo $USAGE_ERR >&2
        exit 1
    elif [ -z "$DO_REGION" ] ; then
        echo "DO Region Missing\n" >&2
        echo $USAGE_ERR >&2
        exit 1
    else
        DO_TOKEN="$(cat $DO_SECRET_FILE)"
        if [ $? != 0 ] ; then exit 1; fi
    fi
elif [ "$PLUGIN" = "rexray/s3fs" ] ; then
    if [ -z "$AWS_ACCESSKEY_SECRET_FILE" ] ; then
        echo "AWS Access Key Secret Missing\n" >&2
        echo $USAGE_ERR >&2
        exit 1
    elif [ -z "$AWS_SECRETKEY_SECRET_FILE" ] ; then
        echo "AWS Secret Key Secret Missing\n" >&2
        echo $USAGE_ERR >&2
        exit 1
    else
        AWS_ACCESSKEY="$(cat $AWS_ACCESSKEY_SECRET_FILE)"
        if [ $? != 0 ] ; then exit 1; fi
        AWS_SECRETKEY="$(cat $AWS_SECRETKEY_SECRET_FILE)"
        if [ $? != 0 ] ; then exit 1; fi
    fi
fi


if docker plugin ls | grep -q "$PLUGIN":latest
then
    if [ -z $VERSION ] && [ "$FORCE_UPDATE" = false ] ; then
        echo $PRE_INSTALLED_MSG
        exit 0
    else
        if [ -z $VERSION ] ; then
            VERSION="latest"
        fi
        CONTAINERID="$(docker plugin ls | grep $PLUGIN:latest | fold -w 12 | head -n 1)"
        PLUGINREF="$(docker plugin inspect -f '{{.PluginReference}}' $CONTAINERID)"
        CURRENT_VER="${PLUGINREF#*$PLUGIN:}"
        if [ "$FORCE_UPDATE" = true ] || [ "$VERSION" = "latest" ] || [ "$VERSION" != "$CURRENT_VER" ] ; then
            echo "Removing Previously Installed Plugin"
            docker plugin rm -f "$PLUGIN":latest
            NEW_INSTALL=true
        else
            echo $PRE_INSTALLED_MSG
            exit 0
        fi
    fi
else
    if [ -z $VERSION ] ; then
        VERSION="latest"
    fi    
    NEW_INSTALL=true
fi

if [ "$NEW_INSTALL" = true ] ; then

    INSTALL_OPTIONS=""

    if [ "$PLUGIN" = "rexray/dobs" ] ; then

        INSTALL_OPTIONS=$INSTALL_OPTIONS"DOBS_REGION=$DO_REGION DOBS_TOKEN=$DO_TOKEN"

        if [ "$DO_CONVERT" = true ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" DOBS_CONVERTUNDERSCORES=true"
        fi

        if [ ! -z "$DO_DELAY" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" DOBS_STATUSINITIALDELAY=$DO_DELAY"
        fi

        if [ ! -z "$DO_ATTEMPT" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" DOBS_STATUSMAXATTEMPTS=$DO_ATTEMPT"
        fi

        if [ ! -z "$DO_TIMEOUT" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" DOBS_STATUSTIMEOUT=$DO_TIMEOUT"
        fi

        if [ ! -z "$HTTP_PROXY" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" HTTP_PROXY=$HTTP_PROXY"
        fi

    elif [ "$PLUGIN" = "rexray/s3fs" ] ; then

        INSTALL_OPTIONS=$INSTALL_OPTIONS"S3FS_ACCESSKEY=$AWS_ACCESSKEY S3FS_SECRETKEY=$AWS_SECRETKEY"

        if [ "$S3_PATHSTYLE" = true ] ; then
            INSTALL_OPTIONS=${INSTALL_OPTIONS}" S3FS_DISABLEPATHSTYLE=true"
        fi

        if [ ! -z "$S3_RETRY" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" S3FS_MAXRETRIES=$S3_RETRY"
        fi

        if [ ! -z "$S3_REGION" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" S3FS_REGION=$S3_REGION"
        fi

        if [ ! -z "$S3_OPTIONS" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" S3FS_OPTIONS=\"$S3_OPTIONS\""
        fi

        if [ ! -z "$HTTP_PROXY" ] ; then
            INSTALL_OPTIONS=$INSTALL_OPTIONS" HTTP_PROXY=$HTTP_PROXY"
        fi

    fi
    echo "Installing New Plugin"
    docker plugin install --grant-all-permissions --alias $PLUGIN:latest $PLUGIN:$VERSION $INSTALL_OPTIONS
fi