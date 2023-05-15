#!/bin/bash
#
# openssl.sh - A script to manage TLS connections using Docker containers.
#
# Usage:
# ./openssl.sh -s server -p PORT [-n NETWORK]: Start a server and expose the specified port
# ./openssl.sh -c client -s server -p PORT [-n NETWORK]: Start a client and connect to the specified server and port
#
# Arguments:
# -c client: Specify the client name
# -s server: Specify the server name
# -p PORT: Specify the port number (between 1 and 65535)
# -n NETWORK: (Optional) Specify the Docker network bridge (default: "tls_net")
#

# Add trap command to stop the Docker container when the script is interrupted or terminated
trap 'docker kill ${CONTAINER_NAME} 2> /dev/null' INT TERM

# Function to print usage instructions
usage() {
    echo -e "\nUsage:"
    echo "$0 -s server -p PORT [-n NETWORK]: Start a server and expose the specified port"
    echo "$0 -c client -s server -p PORT [-n NETWORK]: Start a client and connect to the specified server and port"
}

# Function to validate the port number
validate_port() {
    local port=$1
    if [[ $port -lt 1 ]] || [[ $port -gt 65535 ]]; then
        echo "Invalid port number. Please provide a valid port number (1-65535)."
        exit 1
    fi
}

# Function to parse command line arguments
parse_arguments() {
    while getopts "c:s:p:n:" opt; do
        case $opt in
            c)
                mode="client"
                ENTITY="$OPTARG"
                ;;
            s)
                mode=${mode:-"server"}
                SERVER="$OPTARG"
                if [[ "$mode" == "server" ]]; then ENTITY=${SERVER}; fi
                if [[ "$SERVER" =~ _mod ]]; then SERVER=${SERVER:0:-4}_modified; fi
                ;;
            p)
                PORT="$OPTARG"
                validate_port "$PORT"
                ;;
            n)
                DOCKER_NETWORK="$OPTARG"
                ;;
            *)
                usage
                exit 1
                ;;
        esac
    done

    # Check if required arguments are provided
    if [[ -z "$mode" ]] || [[ -z "$SERVER" ]] || [[ -z "$PORT" ]]; then
        usage
        exit 1
    fi
}

# Function to setup and run Docker container
setup_docker() {
    if [[ "$ENTITY" =~ _mod ]]; then
        IMAGE_OPENSSL="presto-content-filtering-tls:openssl-3.0.1"
        TLS_ENTITY=s_${ENTITY:0:-4}
        CONTAINER_NAME=${ENTITY:0:-4}_modified
    else
        IMAGE_OPENSSL="pile-tls--openssl:3.0.1"
        TLS_ENTITY=s_${ENTITY}
        CONTAINER_NAME=${ENTITY}
    fi

    TARGET_SERVER=$(docker ps --filter name=${SERVER} --format '{{.Names}}' |grep -wE "${SERVER}")
    # TARGET_PORT=$(docker ps --filter name=${SERVER} --format '{{.Ports}}' |\
    #               awk -F',' '{split($1,list_ports,"->|:"); print list_ports[2]}')
    docker inspect ${SERVER} --format '{{ .NetworkSettings.Ports }}' 2>/dev/null |grep -w ${PORT} &>/dev/null
    IS_PORT_EXPOSED=$?
    if [[ "$mode" == "client" ]]; then
        if [[ "$SERVER" == "$TARGET_SERVER" && $IS_PORT_EXPOSED -eq 0 ]]; then
            S_TLS_ENTITY_ARGS="-connect ${SERVER}:${PORT} -trace"
            EXPOSE_PORT=""
        else
            # echo "$SERVER $TARGET_SERVER $PORT $IS_PORT_EXPOSED"
            echo "[ERRORS] : Temporary failure in name resolution."
            echo "           Please make sure that the server is running and named server or server_modified."
            echo "           Ensure that the requested port is available."
            exit 1
        fi
    elif [[ "$mode" == "server" ]]; then
        if [[ $IS_PORT_EXPOSED -ne 0 ]]; then
            S_TLS_ENTITY_ARGS="-debug -accept ${PORT} -cert /home/server.crt -key /home/server.key"
            EXPOSE_PORT="-p ${PORT}:${PORT}"
        else
            echo "The requested port is not available."
            exit 1
        fi
    else
        usage
        exit 1
    fi

    DOCKER_NETWORK=${DOCKER_NETWORK:-"tls_net"}
    docker network ls |grep -q $DOCKER_NETWORK || docker network create $DOCKER_NETWORK
    docker kill ${CONTAINER_NAME} &> /dev/null
    docker run -id --rm ${EXPOSE_PORT} --name ${CONTAINER_NAME} --network ${DOCKER_NETWORK} ${IMAGE_OPENSSL}
    docker exec -i ${CONTAINER_NAME} openssl ${TLS_ENTITY} ${S_TLS_ENTITY_ARGS}
}

# Main script execution
parse_arguments "$@"
setup_docker
