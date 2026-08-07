#!/bin/bash

# Ensure UTF-8 output support
export LANG=C.UTF-8 2>/dev/null

echo "================================================================================"
echo "                   POD TOPOLOGY DISTRIBUTION REPORT                             "
echo "================================================================================"
echo ""

echo "NODES AND THEIR ZONES:"
echo "--------------------------------------------------------------------------------"
printf "%-40s %s\n" "NODE" "ZONE"
echo "--------------------------------------------------------------------------------"

# Fetch Nodes
NODES_RAW=$(kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone --no-headers | tr -d '\r')
echo "$NODES_RAW" | sort | awk '{printf "%-40s %s\n", $1, $2}'

echo ""
echo "PODS DISTRIBUTION BY APPLICATION:"
echo "--------------------------------------------------------------------------------"
printf "%-12s %-40s %-40s %s\n" "APP" "POD" "NODE" "ZONE"
echo "--------------------------------------------------------------------------------"

# Fetch Pods
PODS_RAW=$(kubectl get pods -o json | jq -r '
.items[] | 
[
  (.metadata.labels."app.kubernetes.io/name" // "unknown"),
  .metadata.name,
  (.spec.nodeName // "none")
] | @tsv
' | tr -d '\r')

# Combine Nodes and Pods into AWK with clean trimmed fields
awk -F'\t' -v target_zones="us-east-1a,us-east-1b,us-east-1c" '
function trim(s) {
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
    return s
}
BEGIN {
    split(target_zones, zones, ",")
}
# Processing Nodes Data (from first input)
NR == FNR {
    # Split space-separated node and zone
    split($0, node_parts, /[ \t]+/)
    node_name = trim(node_parts[1])
    zone_name = trim(node_parts[2])
    if (node_name != "") {
        node_zone[node_name] = zone_name
    }
    next
}
# Processing Pods Data (from second input)
{
    app  = trim($1)
    pod  = trim($2)
    node = trim($3)
    if (app == "") next

    zone = (node in node_zone) ? node_zone[node] : "Unknown"

    # Save pod info for sorting/printing
    pod_rows[app "\t" pod] = sprintf("%-12s %-40s %-40s %s", app, pod, node, zone)
    
    # Track app and counts
    apps[app] = 1
    counts[app "," zone]++
}
END {
    # Print sorted pod table
    for (key in pod_rows) {
        print pod_rows[key] | "sort"
    }
    close("sort")

    print ""
    print "ZONE DISTRIBUTION SUMMARY:"
    print "--------------------------------------------------------------------------------"

    # Sort apps alphabetically
    n = asorti(apps, sorted_apps)
    
    for (i = 1; i <= n; i++) {
        app = sorted_apps[i]
        print ""
        print "[APP]: " app
        
        for (z in zones) {
            zone = zones[z]
            cnt = counts[app "," zone] + 0
            
            if (cnt > 0) {
                printf "  %-15s %-2d pods [OK]\n", zone ":", cnt
            } else {
                printf "  %-15s %-2d pods [WARNING - No pods in this zone]\n", zone ":", cnt
            }
        }
    }
}
' <(echo "$NODES_RAW") <(echo "$PODS_RAW")

echo ""
echo "--------------------------------------------------------------------------------"
echo "Topology spread analysis complete!"
echo ""