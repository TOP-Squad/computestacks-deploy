#!/bin/bash

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url)
      base_url="$2"
      shift
      ;;
    --poll-interval)
      poll_interval="$2"
      shift
      ;;
    --timeout)
      timeout="$2"
      shift
      ;;
    --username)
      username="$2"
      shift
      ;;
    --password)
      password="$2"
      shift
      ;;
    --container-id)
      container_id="$2"
      shift
      ;;
    *)
      echo "Error: Invalid argument: $1"
      exit 1
      ;;
  esac
  shift
done

# Set variables
rebuild_url="$base_url/api/container_services/$container_id/power/rebuild"
status_url="$base_url/api/container_services/$container_id"
poll_interval="${poll_interval:-1}"
timeout="${timeout:-120}"

# Function to perform the rebuild action
perform_rebuild() {
  echo "Initiating container rebuild..."
  start_time_rebuild=$(date +%s)
  curl -X PUT -u "$username:$password" "$rebuild_url"
}

# Function to check the container status
check_status() {
  echo "Checking container status..."
  start_time=$(date +%s)

  while true; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    # Check timeout
    if [ $elapsed_time -ge $timeout ]; then
      echo "Timeout reached. Container not online within $timeout seconds."
      exit 1
    fi

    # Perform GET request and check current_state
    response=$(curl -s -u "$username:$password" "$status_url")
    current_state=$(echo "$response" | jq -r '.container_service.current_state')

    echo "Current state: ${current_state} (${elapsed_time} seconds passed)"

    if [ "$current_state" = "online" ]; then
      end_time=$(date +%s)
      duration=$((end_time - start_time_rebuild))
      echo "Container is online. Time taken: ${duration} seconds."
      exit 0
    fi

    sleep $poll_interval
  done
}

# Main script
perform_rebuild
check_status
