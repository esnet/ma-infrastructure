#!/bin/bash

# Script to set up Workload Identity for External Secrets Operator on GKE
# Usage: ./setup-workload-identity.sh [options]

set -e

# Default values
PROJECT_ID=""
CLUSTER_NAME=""
CLUSTER_LOCATION="us-central1"
KSA_NAME="external-secrets-sa"
KSA_NAMESPACE="external-secrets"
GSA_NAME="external-secrets-gsa"

# Help function
show_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Set up Workload Identity for External Secrets Operator on GKE.

Required Options:
    -p, --project-id PROJECT_ID         GCP Project ID
    -c, --cluster-name CLUSTER_NAME     GKE Cluster name

Optional Options:
    -l, --location LOCATION             Cluster location (default: us-central1)
    -k, --ksa-name NAME                 Kubernetes Service Account name (default: external-secrets-sa)
    -n, --namespace NAMESPACE           Kubernetes namespace (default: external-secrets)
    -g, --gsa-name NAME                 Google Service Account name (default: external-secrets-gsa)
    -h, --help                          Display this help message

Examples:
    ${0##*/} -p my-project -c my-cluster
    ${0##*/} --project-id my-project --cluster-name my-cluster --location us-east1
    ${0##*/} -p my-project -c my-cluster -n kube-system -k my-ksa -g my-gsa
EOF
}

# Show help if no arguments provided
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-id)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --project-id requires a value" >&2
                exit 1
            fi
            PROJECT_ID="$2"
            shift 2
            ;;
        -c|--cluster-name)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --cluster-name requires a value" >&2
                exit 1
            fi
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -l|--location)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --location requires a value" >&2
                exit 1
            fi
            CLUSTER_LOCATION="$2"
            shift 2
            ;;
        -k|--ksa-name)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --ksa-name requires a value" >&2
                exit 1
            fi
            KSA_NAME="$2"
            shift 2
            ;;
        -n|--namespace)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --namespace requires a value" >&2
                exit 1
            fi
            KSA_NAMESPACE="$2"
            shift 2
            ;;
        -g|--gsa-name)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --gsa-name requires a value" >&2
                exit 1
            fi
            GSA_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PROJECT_ID" ]]; then
    echo "Error: Project ID is required" >&2
    echo ""
    show_help
    exit 1
fi

if [[ -z "$CLUSTER_NAME" ]]; then
    echo "Error: Cluster name is required" >&2
    echo ""
    show_help
    exit 1
fi

# Display configuration
echo "=== Workload Identity Setup Configuration ==="
echo "Project ID:        ${PROJECT_ID}"
echo "Cluster Name:      ${CLUSTER_NAME}"
echo "Cluster Location:  ${CLUSTER_LOCATION}"
echo "KSA Name:          ${KSA_NAME}"
echo "KSA Namespace:     ${KSA_NAMESPACE}"
echo "GSA Name:          ${GSA_NAME}"
echo "=============================================="
echo ""

# 1. Create Google Service Account for External Secrets
echo "Step 1: Creating Google Service Account..."
if gcloud iam service-accounts describe ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com --project=${PROJECT_ID} &>/dev/null; then
    echo "  → GSA already exists: ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
else
    gcloud iam service-accounts create ${GSA_NAME} \
        --display-name="External Secrets Operator" \
        --project=${PROJECT_ID}
    echo "  → GSA created: ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
fi

# Wait a moment for GSA to propagate
sleep 2

# 2. Grant Secret Manager permissions to the GSA
echo "Step 2: Granting Secret Manager permissions..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" \
    --condition=None

# 3. Create Kubernetes Service Account (if not exists)
echo "Step 3: Creating Kubernetes Service Account..."
kubectl create serviceaccount ${KSA_NAME} \
    --namespace ${KSA_NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -

# 4. Bind the Kubernetes SA to the Google SA using Workload Identity
echo "Step 4: Binding KSA to GSA..."
gcloud iam service-accounts add-iam-policy-binding \
    ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[${KSA_NAMESPACE}/${KSA_NAME}]" \
    --project=${PROJECT_ID}

# 5. Annotate the Kubernetes Service Account
echo "Step 5: Annotating Kubernetes Service Account..."
kubectl annotate serviceaccount ${KSA_NAME} \
    --namespace ${KSA_NAMESPACE} \
    iam.gke.io/gcp-service-account=${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --overwrite

echo ""
echo "✓ Workload Identity setup complete!"
echo "KSA: ${KSA_NAMESPACE}/${KSA_NAME}"
echo "GSA: ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
