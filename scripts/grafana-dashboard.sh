#!/bin/bash

# HomeLab Grafana Dashboard Deployment Script
# This script deploys dashboards to Grafana using the macvlan network

GRAFANA_IP="192.168.5.60"
GRAFANA_PORT="80"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
TEMP_IP="192.168.5.151"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy <file>    Deploy a dashboard JSON file to Grafana"
    echo "  list             List all dashboards"
    echo "  delete <uid>     Delete a dashboard by UID"
    echo "  test             Test Grafana API connectivity"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy configs/grafana/dashboards/homelab-dashboard.json"
    echo "  $0 list"
    echo "  $0 delete 289087f3-934d-4f79-b10e-162b12f88708"
    echo "  $0 test"
    echo ""
    echo "Dashboard files should be stored in: configs/grafana/dashboards/"
}

function test_connection() {
    print_info "Testing Grafana API connectivity..."
    
    response=$(docker run --rm --network homelab --ip ${TEMP_IP} alpine/curl:latest \
        -s -w "%{http_code}" \
        -u ${GRAFANA_USER}:${GRAFANA_PASS} \
        http://${GRAFANA_IP}:${GRAFANA_PORT}/api/health)
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        print_info "✅ Grafana API is accessible"
        echo "Health status: $body"
    else
        print_error "❌ Failed to connect to Grafana API (HTTP $http_code)"
        echo "Response: $body"
        return 1
    fi
}

function deploy_dashboard() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        print_error "Dashboard file '$file' not found"
        return 1
    fi
    
    print_info "Deploying dashboard from '$file'..."
    
    response=$(docker run --rm --network homelab --ip ${TEMP_IP} \
        -v "$(pwd)/$file:/dashboard.json" \
        alpine/curl:latest \
        -s -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -u ${GRAFANA_USER}:${GRAFANA_PASS} \
        -d @/dashboard.json \
        http://${GRAFANA_IP}:${GRAFANA_PORT}/api/dashboards/db)
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        print_info "✅ Dashboard deployed successfully"
        echo "$body" | grep -o '"url":"[^"]*"' | cut -d'"' -f4
    else
        print_error "❌ Failed to deploy dashboard (HTTP $http_code)"
        echo "Response: $body"
        return 1
    fi
}

function list_dashboards() {
    print_info "Listing all dashboards..."
    
    response=$(docker run --rm --network homelab --ip ${TEMP_IP} \
        alpine/curl:latest \
        -s -w "%{http_code}" \
        -u ${GRAFANA_USER}:${GRAFANA_PASS} \
        http://${GRAFANA_IP}:${GRAFANA_PORT}/api/search)
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        print_info "📊 Available dashboards:"
        echo "$body" | jq -r '.[] | "  - \(.title) (UID: \(.uid))"' 2>/dev/null || echo "$body"
    else
        print_error "❌ Failed to list dashboards (HTTP $http_code)"
        echo "Response: $body"
        return 1
    fi
}

function delete_dashboard() {
    local uid="$1"
    
    if [ -z "$uid" ]; then
        print_error "Dashboard UID is required"
        return 1
    fi
    
    print_info "Deleting dashboard with UID '$uid'..."
    
    response=$(docker run --rm --network homelab --ip ${TEMP_IP} \
        alpine/curl:latest \
        -s -w "%{http_code}" \
        -X DELETE \
        -u ${GRAFANA_USER}:${GRAFANA_PASS} \
        http://${GRAFANA_IP}:${GRAFANA_PORT}/api/dashboards/uid/${uid})
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        print_info "✅ Dashboard deleted successfully"
    else
        print_error "❌ Failed to delete dashboard (HTTP $http_code)"
        echo "Response: $body"
        return 1
    fi
}

# Main script logic
case "${1:-help}" in
    deploy)
        if [ -z "$2" ]; then
            print_error "Dashboard file is required"
            help
            exit 1
        fi
        deploy_dashboard "$2"
        ;;
    list)
        list_dashboards
        ;;
    delete)
        if [ -z "$2" ]; then
            print_error "Dashboard UID is required"
            help
            exit 1
        fi
        delete_dashboard "$2"
        ;;
    test)
        test_connection
        ;;
    help|--help|-h)
        help
        ;;
    *)
        print_error "Unknown command: $1"
        help
        exit 1
        ;;
esac
