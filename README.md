# Job Monitor with Notification

A bash script that monitors a job by its process ID (PID) and sends a notification via [ntfy](https://ntfy.sh/) when the job completes or terminates. The notification includes details about the job status, duration, and the original command that was run.

## Features

- Monitors any process by its PID
- Detects when the process completes or terminates
- Calculates job duration accurately
- Determines success (exit code 0) or failure status
- Includes the original command that was executed
- Sends a formatted notification with:
  - Success/failure indication with appropriate icons
  - Job duration in HH:MM:SS format
  - Original command that was run
  - Hostname and username details
  - Proper priority (high for failures)
  - Timestamp of completion

## Requirements

- Bash shell
- [ntfy CLI](https://ntfy.sh/docs/install/) installed

- Linux/Unix system with `ps` command available

## Installation

1. Download the script:
   ```bash
   curl -O https://github.com/bsantraigi/ntfy-pid/raw/refs/heads/main/ntfy-pid.sh
   ```

2. Make it executable:
   ```bash
   chmod +x ntfy-pid.sh
   ```

3. Install ntfy if not already installed:
  ```bash
  # Get the binary
  wget https://github.com/binwiederhier/ntfy/releases/download/v2.11.0/ntfy_2.11.0_linux_amd64.tar.gz
  tar zxvf ntfy_2.11.0_linux_amd64.tar.gz
  sudo cp -a ntfy_2.11.0_linux_amd64/ntfy /usr/local/bin/ntfy
  sudo mkdir /etc/ntfy && sudo cp ntfy_2.11.0_linux_amd64/{client,server}/*.yml /etc/ntfy
  
  # Change the URL
  mkdir -p $HOME/.config/ntfy/
  sudo bash -c "echo default-host: https://ntfy.mydomain.com >> /etc/ntfy/client.yml"
  echo "default-host: https://ntfy.mydomain.com" > $HOME/.config/ntfy/client.yml
  ```

## Usage

```bash
./job_monitor.sh PID "Job Name" [ntfy-topic]
```

### Parameters

- `PID`: The process ID to monitor
- `Job Name`: A descriptive name for the job (use quotes for names with spaces)
- `ntfy-topic` (optional): The ntfy topic to send notifications to (defaults to "job-notifications")

### Examples

Monitor a database backup process:
```bash
./job_monitor.sh 1234 "Database Backup" db-notifications
```

Monitor a long-running script:
```bash
./job_monitor.sh 5678 "Data Processing Script"
```

### Workflow Integration

You can start a job and immediately set up monitoring:
```bash
# Start a job in the background and capture its PID
long_running_command & 
JOB_PID=$!

# Start monitoring the job
./job_monitor.sh $JOB_PID "Long Running Job" my-notifications
```

## Notification Example

When the job completes, you will receive a notification with details like:

```
Job Complete: Database Backup
----------------------------
Status: Success ✅
Duration: 00:45:23
Command: mysqldump -u root -p mydatabase > backup.sql
Host: server-name
User: admin
PID: 1234
Completed: 2025-03-30 14:32:15
```

## Troubleshooting

- If you receive the error "ntfy command not found", make sure to install the ntfy CLI following the instructions at https://ntfy.sh/docs/install/
- If the original command appears empty, the script will automatically try alternative methods to determine it, but some systems may have limitations on what process information is accessible.

## License

This script is released under the MIT License.
