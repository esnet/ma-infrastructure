#!/usr/bin/env sh
# Checks to see if CLI programs are installed

command -v kubectl >/dev/null 2>&1 || {
    echo >&2 "ERROR: I require kubectl but it is not installed.  Aborting."; exit 1;
}

command -v helm >/dev/null 2>&1 || {
    echo >&2 "ERROR: I require helm but it is not installed.  Aborting."; exit 1;
}

command -v kubeseal >/dev/null 2>&1 || {
    echo >&2 "ERROR: I require kubeseal but it is not installed.  Aborting."; exit 1;
}


if kubectl cluster-info; then
    CONTEXT=$(kubectl config current-context)
    printf "\nYou will be setting up an ArgoCd control repository for : %s\n" "${CONTEXT}";
    printf "Preflight check complete! No problems found.\n";
else
    printf "\nERROR: Kubectl not configured correctly. Check your .kube/config file.\n" >&2;
    exit 1;
fi
