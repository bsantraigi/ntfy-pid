#!/bin/bash

# Usage: ./job_monitor.sh PID JOB_NAME [NTFY_TOPIC]

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 PID JOB_NAME [NTFY_TOPIC]"
    echo "Example: $0 1234 \"Database Backup\" my-notification-topic"
    exit 1
fi

PID=$1
JOB_NAME=$2
NTFY_TOPIC=${3:-"job-notifications"}  # Default topic if not provided

# Check if ntfy is installed
if ! command -v ntfy &> /dev/null; then
    echo "Error: ntfy command not found. Please install it first."
    echo "Visit https://ntfy.sh/docs/install/ for installation instructions."
    exit 1
fi

# Check if PID is a number
if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    echo "Error: PID must be a number"
    exit 1
fi

# Check if the process exists
if ! ps -p $PID > /dev/null; then
    echo "Error: Process with PID $PID does not exist"
    exit 1
fi

# Get the original command that was run
if command -v ps &> /dev/null; then
    # Try different ps formats based on system
    if ps -p $PID -o cmd= &> /dev/null; then
        ORIGINAL_CMD=$(ps -p $PID -o cmd= 2>/dev/null)
    elif ps -p $PID -o args= &> /dev/null; then
        ORIGINAL_CMD=$(ps -p $PID -o args= 2>/dev/null)
    elif ps -p $PID -o command= &> /dev/null; then
        ORIGINAL_CMD=$(ps -p $PID -o command= 2>/dev/null)
    else
        ORIGINAL_CMD="Could not determine original command"
    fi
    
    # Fallback to /proc on Linux systems
    if [ -z "$ORIGINAL_CMD" ] && [ -d "/proc/$PID" ] && [ -r "/proc/$PID/cmdline" ]; then
        ORIGINAL_CMD=$(tr '\0' ' ' < /proc/$PID/cmdline)
    fi
else
    ORIGINAL_CMD="Could not determine original command (ps not available)"
fi

echo "Monitoring job \"$JOB_NAME\" with PID $PID..."
echo "Original command: $ORIGINAL_CMD"
echo "Will send notification to topic '$NTFY_TOPIC' when job completes"

# Start time for duration calculation
START_TIME=$(date +%s)

# Wait for the process to finish
while ps -p $PID > /dev/null; do
    sleep 5
done

# End time and duration calculation
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_FORMAT=$(date -u -d @${DURATION} +"%H:%M:%S")

# Get exit code if available (might not be reliable)
if [ -f "/proc/$PID/status" ]; then
    EXIT_CODE=$(grep -i "exit_code" /proc/$PID/status | awk '{print $2}')
else
    EXIT_CODE="Unknown"
fi

# Determine if the job succeeded or failed
if [ "$EXIT_CODE" = "0" ]; then
    STATUS="Success ✅"
    PRIORITY="default"
    TAGS="white_check_mark,rocket"
else
    STATUS="Failed ❌"
    PRIORITY="high"
    TAGS="x,warning"
fi

# Hostname and user info
HOST=$(hostname)
USER=$(whoami)

# Create notification message
TITLE="Job Complete: $JOB_NAME"
MESSAGE="Status: $STATUS
Duration: $DURATION_FORMAT
Command: $ORIGINAL_CMD
Host: $HOST
User: $USER
PID: $PID
Completed: $(date '+%Y-%m-%d %H:%M:%S')"

# Send notification using ntfy CLI
ntfy publish \
    --title "$TITLE" \
    --priority "$PRIORITY" \
    --tags "$TAGS" \
    "$NTFY_TOPIC" \
    "$MESSAGE"

echo "Job monitoring complete. Notification sent."
exit 0
