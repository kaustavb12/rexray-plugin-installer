#!/bin/sh

USAGE_ERR="usage: "$0" [-v driver-version] [-u] do_token_secret do_region"
PRE_INSTALLED_MSG="Plugin already installed"

FORCE_UPDATE=false

while getopts ":v:u" opt; do
    case $opt in
        v)
            VERSION=$OPTARG
            ;;
        u)
            echo "Force Update"
            FORCE_UPDATE=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo $USAGE_ERR >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            echo $USAGE_ERR >&2
            exit 1
            ;;
    esac
done

shift $(expr $OPTIND - 1)

if [ -z "$1" ] || [ -z "$2" ] ; then 
    echo $USAGE_ERR >&2
    exit 1
else
    SECRET_FILE="/run/secrets/"$1
    DOTOKEN="$(cat $SECRET_FILE)"
    DOREGION=$2
fi

NEW_INSTALL=false

if docker plugin ls | grep -q rexray/dobs:latest
then
    if [ -z $VERSION ] && [ "$FORCE_UPDATE" = false ] ; then
        echo $PRE_INSTALLED_MSG
        exit 0
    else
        if [ -z $VERSION ] ; then
            VERSION="latest"
        fi
        CONTAINERID="$(docker plugin ls | grep rexray/dobs:latest | fold -w 12 | head -n 1)"
        PLUGINREF="$(docker plugin inspect -f '{{.PluginReference}}' $CONTAINERID)"
        CURRENT_VER=${PLUGINREF#*rexray/dobs:}
        if [ "$FORCE_UPDATE" = true ] || [ "$VERSION" = "latest" ] || [ "$VERSION" != "$CURRENT_VER" ] ; then
            echo "Removing Previously Installed Plugin"
            docker plugin rm -f rexray/dobs:latest
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
    echo "Installing New Plugin"
    docker plugin install --grant-all-permissions --alias rexray/dobs:latest rexray/dobs:$VERSION DOBS_REGION=$DOREGION DOBS_TOKEN=$DOTOKEN DOBS_CONVERTUNDERSCORES=true
fi