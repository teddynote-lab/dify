#!/bin/bash

#################################################################################
# Azure VM Storage Setup Script for Dify
#
# This script automates the process of mounting external storage and migrating
# Dify volumes on Azure VMs. It provides Azure-specific optimizations including
# Azure CLI integration, disk tagging, backup configurations, and monitoring.
#
# Features:
# - Automatic Azure disk detection and mounting
# - GPT partitioning and ext4 filesystem creation
# - Automatic backup and rollback capabilities
# - Azure CLI integration for resource management
# - Comprehensive logging and monitoring
# - fstab configuration for persistent mounting
#
# Usage: sudo ./azure-storage-setup.sh [OPTIONS]
#
# Author: Generated for Dify mySUNI deployment
# Version: 2.0.0
#################################################################################

set -euo pipefail

# Script configuration
SCRIPT_NAME="azure-storage-setup"
LOG_DIR="/var/log/dify-azure"
LOG_FILE="$LOG_DIR/$SCRIPT_NAME-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/opt/dify-backups"
MOUNT_POINT="/opt/dify-data"
DIFY_BASE_DIR="/Users/teddy/Dev/github/10-hsad-dify/dify"
AZURE_RESOURCE_GROUP=""
AZURE_VM_NAME=""
TARGET_DISK_SIZE="1T"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
DETECTED_DISK=""
EXISTING_DIFY_VOLUMES=()
AZURE_SUBSCRIPTION_ID=""
AZURE_REGION=""

#################################################################################
# Utility Functions
#################################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Log to console with colors
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        *)
            echo "[$level] $message"
            ;;
    esac
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root. Please use sudo."
        exit 1
    fi
}

check_dependencies() {
    log "INFO" "Checking dependencies..."

    local missing_deps=()

    # Check for required commands
    command -v lsblk >/dev/null 2>&1 || missing_deps+=("util-linux")
    command -v parted >/dev/null 2>&1 || missing_deps+=("parted")
    command -v mkfs.ext4 >/dev/null 2>&1 || missing_deps+=("e2fsprogs")
    command -v docker >/dev/null 2>&1 || missing_deps+=("docker")

    # Check for Azure CLI (optional but recommended)
    if ! command -v az >/dev/null 2>&1; then
        log "WARN" "Azure CLI not found. Some Azure-specific features will be disabled."
        log "WARN" "Install with: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing_deps[*]}"
        log "INFO" "Please install with: apt update && apt install -y ${missing_deps[*]}"
        exit 1
    fi

    log "SUCCESS" "All dependencies are satisfied"
}

detect_azure_environment() {
    log "INFO" "Detecting Azure environment..."

    # Check if running on Azure VM
    if curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" >/dev/null 2>&1; then
        log "SUCCESS" "Azure VM detected"

        # Get Azure metadata
        local metadata=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01")
        AZURE_SUBSCRIPTION_ID=$(echo "$metadata" | python3 -c "import sys, json; print(json.load(sys.stdin)['compute']['subscriptionId'])" 2>/dev/null || echo "")
        AZURE_REGION=$(echo "$metadata" | python3 -c "import sys, json; print(json.load(sys.stdin)['compute']['location'])" 2>/dev/null || echo "")
        AZURE_VM_NAME=$(echo "$metadata" | python3 -c "import sys, json; print(json.load(sys.stdin)['compute']['name'])" 2>/dev/null || echo "")
        AZURE_RESOURCE_GROUP=$(echo "$metadata" | python3 -c "import sys, json; print(json.load(sys.stdin)['compute']['resourceGroupName'])" 2>/dev/null || echo "")

        log "INFO" "Azure VM Name: $AZURE_VM_NAME"
        log "INFO" "Resource Group: $AZURE_RESOURCE_GROUP"
        log "INFO" "Region: $AZURE_REGION"
        log "INFO" "Subscription: $AZURE_SUBSCRIPTION_ID"
    else
        log "WARN" "Not running on Azure VM or metadata service unavailable"
    fi
}

#################################################################################
# Azure CLI Integration Functions
#################################################################################

setup_azure_cli() {
    if command -v az >/dev/null 2>&1; then
        log "INFO" "Setting up Azure CLI integration..."

        # Check if already logged in
        if az account show >/dev/null 2>&1; then
            log "SUCCESS" "Azure CLI already authenticated"
            return 0
        fi

        # Try to login with managed identity
        if [[ -n "$AZURE_SUBSCRIPTION_ID" ]]; then
            log "INFO" "Attempting Azure CLI login with managed identity..."
            if az login --identity >/dev/null 2>&1; then
                az account set --subscription "$AZURE_SUBSCRIPTION_ID" >/dev/null 2>&1
                log "SUCCESS" "Azure CLI authenticated with managed identity"
                return 0
            fi
        fi

        log "WARN" "Azure CLI authentication failed. Manual login may be required."
        log "INFO" "Run 'az login' manually for full Azure integration features."
    fi
}

tag_azure_disk() {
    local disk_name="$1"

    if command -v az >/dev/null 2>&1 && az account show >/dev/null 2>&1; then
        log "INFO" "Tagging Azure disk: $disk_name"

        az disk update \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --name "$disk_name" \
            --set tags.Purpose="DifyStorage" \
            --set tags.Environment="Production" \
            --set tags.ManagedBy="dify-storage-setup" \
            --set tags.CreatedDate="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            >/dev/null 2>&1 || log "WARN" "Failed to tag disk $disk_name"
    fi
}

setup_azure_backup() {
    local disk_name="$1"

    if command -v az >/dev/null 2>&1 && az account show >/dev/null 2>&1; then
        log "INFO" "Setting up Azure backup policy for disk: $disk_name"

        # Create backup vault if not exists
        local backup_vault="dify-backup-vault-${AZURE_REGION}"
        if ! az backup vault show --resource-group "$AZURE_RESOURCE_GROUP" --name "$backup_vault" >/dev/null 2>&1; then
            log "INFO" "Creating Azure backup vault: $backup_vault"
            az backup vault create \
                --resource-group "$AZURE_RESOURCE_GROUP" \
                --name "$backup_vault" \
                --location "$AZURE_REGION" \
                >/dev/null 2>&1 || log "WARN" "Failed to create backup vault"
        fi

        # Enable backup for the disk
        az backup protection enable-for-vm \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --vault-name "$backup_vault" \
            --vm "$AZURE_VM_NAME" \
            --policy-name "DefaultPolicy" \
            >/dev/null 2>&1 || log "WARN" "Failed to enable backup for VM"
    fi
}

#################################################################################
# Disk Management Functions
#################################################################################

detect_target_disk() {
    log "INFO" "Detecting target disk for Dify storage..."

    # List all available disks with their sizes
    local disks=($(lsblk -nd -o NAME,SIZE | grep -E "${TARGET_DISK_SIZE}|1000" | awk '{print $1}'))

    if [[ ${#disks[@]} -eq 0 ]]; then
        log "ERROR" "No suitable disk found with size ${TARGET_DISK_SIZE}"
        log "INFO" "Available disks:"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
        exit 1
    fi

    # Find unpartitioned disk
    for disk in "${disks[@]}"; do
        if ! lsblk "/dev/$disk" | grep -q part; then
            DETECTED_DISK="/dev/$disk"
            log "SUCCESS" "Detected unpartitioned disk: $DETECTED_DISK"
            break
        fi
    done

    if [[ -z "$DETECTED_DISK" ]]; then
        log "ERROR" "No unpartitioned disk found with size ${TARGET_DISK_SIZE}"
        log "INFO" "Available disks:"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
        exit 1
    fi

    # Verify disk is not mounted
    if mount | grep -q "$DETECTED_DISK"; then
        log "ERROR" "Disk $DETECTED_DISK is already mounted"
        exit 1
    fi
}

create_partition_and_filesystem() {
    local disk="$1"
    local partition="${disk}1"

    log "INFO" "Creating GPT partition table on $disk..."

    # Create GPT partition table
    parted -s "$disk" mklabel gpt

    # Create primary partition using entire disk
    parted -s "$disk" mkpart primary ext4 0% 100%

    # Wait for partition to be available
    sleep 2
    partprobe "$disk"
    sleep 2

    log "INFO" "Creating ext4 filesystem on $partition..."

    # Create ext4 filesystem with optimizations for large files
    mkfs.ext4 -F -L "dify-storage" \
        -O ^has_journal \
        -E lazy_itable_init=0,lazy_journal_init=0 \
        "$partition"

    log "SUCCESS" "Filesystem created successfully on $partition"
}

create_mount_point() {
    log "INFO" "Creating mount point: $MOUNT_POINT"

    if [[ -d "$MOUNT_POINT" ]]; then
        log "WARN" "Mount point $MOUNT_POINT already exists"

        # Check if it's already mounted
        if mount | grep -q "$MOUNT_POINT"; then
            log "ERROR" "Mount point $MOUNT_POINT is already in use"
            exit 1
        fi
    else
        mkdir -p "$MOUNT_POINT"
    fi

    # Set appropriate permissions
    chown root:root "$MOUNT_POINT"
    chmod 755 "$MOUNT_POINT"
}

mount_disk() {
    local partition="${DETECTED_DISK}1"

    log "INFO" "Mounting $partition to $MOUNT_POINT..."

    # Mount with optimized options
    mount -t ext4 -o defaults,noatime,errors=remount-ro "$partition" "$MOUNT_POINT"

    # Verify mount
    if mount | grep -q "$MOUNT_POINT"; then
        log "SUCCESS" "Disk mounted successfully at $MOUNT_POINT"
    else
        log "ERROR" "Failed to mount disk"
        exit 1
    fi
}

update_fstab() {
    local partition="${DETECTED_DISK}1"
    local uuid=$(blkid -s UUID -o value "$partition")

    log "INFO" "Updating /etc/fstab for persistent mounting..."

    # Create backup of fstab
    cp /etc/fstab "/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"

    # Add entry to fstab using UUID
    echo "UUID=$uuid $MOUNT_POINT ext4 defaults,noatime,errors=remount-ro 0 2" >> /etc/fstab

    # Verify fstab syntax
    if mount -a; then
        log "SUCCESS" "fstab updated successfully"
    else
        log "ERROR" "fstab syntax error, restoring backup"
        cp /etc/fstab.backup.* /etc/fstab
        exit 1
    fi
}

#################################################################################
# Dify Volume Migration Functions
#################################################################################

detect_dify_volumes() {
    log "INFO" "Detecting existing Dify Docker volumes..."

    if ! command -v docker >/dev/null 2>&1; then
        log "WARN" "Docker not found, skipping volume detection"
        return
    fi

    # Find Dify-related volumes
    EXISTING_DIFY_VOLUMES=($(docker volume ls --format "{{.Name}}" | grep -E "(dify|docker)" | head -10))

    if [[ ${#EXISTING_DIFY_VOLUMES[@]} -gt 0 ]]; then
        log "INFO" "Found ${#EXISTING_DIFY_VOLUMES[@]} Dify volumes:"
        for volume in "${EXISTING_DIFY_VOLUMES[@]}"; do
            log "INFO" "  - $volume"
        done
    else
        log "INFO" "No existing Dify volumes found"
    fi
}

create_backup() {
    log "INFO" "Creating backup of existing Dify data..."

    mkdir -p "$BACKUP_DIR"
    local backup_timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_archive="$BACKUP_DIR/dify-backup-$backup_timestamp.tar.gz"

    # Create Docker volumes backup
    if [[ ${#EXISTING_DIFY_VOLUMES[@]} -gt 0 ]]; then
        log "INFO" "Backing up Docker volumes..."

        for volume in "${EXISTING_DIFY_VOLUMES[@]}"; do
            local volume_backup_dir="$BACKUP_DIR/volumes/$volume"
            mkdir -p "$volume_backup_dir"

            # Use a temporary container to copy volume data
            docker run --rm \
                -v "$volume:/source:ro" \
                -v "$volume_backup_dir:/backup" \
                alpine:latest \
                sh -c "cd /source && cp -ar . /backup/" || log "WARN" "Failed to backup volume $volume"
        done

        # Create compressed archive
        tar -czf "$backup_archive" -C "$BACKUP_DIR" volumes/
        log "SUCCESS" "Docker volumes backed up to $backup_archive"
    fi

    # Backup Dify configuration files
    if [[ -d "$DIFY_BASE_DIR" ]]; then
        log "INFO" "Backing up Dify configuration..."
        tar -czf "$BACKUP_DIR/dify-config-$backup_timestamp.tar.gz" \
            -C "$(dirname "$DIFY_BASE_DIR")" \
            "$(basename "$DIFY_BASE_DIR")" \
            --exclude="node_modules" \
            --exclude=".git" \
            --exclude="*.log" || log "WARN" "Failed to backup Dify configuration"
    fi
}

migrate_volumes() {
    log "INFO" "Migrating Dify volumes to new storage..."

    # Create directories for each volume
    for volume in "${EXISTING_DIFY_VOLUMES[@]}"; do
        local volume_dir="$MOUNT_POINT/volumes/$volume"
        mkdir -p "$volume_dir"

        # Copy data from backup if available
        local backup_dir="$BACKUP_DIR/volumes/$volume"
        if [[ -d "$backup_dir" ]]; then
            log "INFO" "Restoring volume $volume..."
            cp -ar "$backup_dir/"* "$volume_dir/"
        fi

        # Set appropriate permissions
        chown -R 1001:0 "$volume_dir"
        chmod -R g+rwX "$volume_dir"
    done

    # Create symbolic links from default Docker volume location
    local docker_volumes_path="/var/lib/docker/volumes"
    if [[ -d "$docker_volumes_path" ]]; then
        for volume in "${EXISTING_DIFY_VOLUMES[@]}"; do
            local link_path="$docker_volumes_path/$volume"
            local target_path="$MOUNT_POINT/volumes/$volume"

            # Remove existing volume directory/link
            if [[ -L "$link_path" ]]; then
                rm "$link_path"
            elif [[ -d "$link_path" ]]; then
                mv "$link_path" "${link_path}.backup.$(date +%Y%m%d-%H%M%S)"
            fi

            # Create symbolic link
            ln -sf "$target_path" "$link_path"
            log "INFO" "Created symbolic link: $link_path -> $target_path"
        done
    fi
}

#################################################################################
# Monitoring and Health Check Functions
#################################################################################

setup_monitoring() {
    log "INFO" "Setting up storage monitoring..."

    # Create monitoring script
    cat > /usr/local/bin/dify-storage-monitor.sh << 'EOF'
#!/bin/bash

MOUNT_POINT="/opt/dify-data"
LOG_FILE="/var/log/dify-azure/storage-monitor.log"
ALERT_THRESHOLD=85  # Alert when disk usage exceeds 85%

mkdir -p "$(dirname "$LOG_FILE")"

# Check disk usage
usage=$(df "$MOUNT_POINT" | awk 'NR==2 {print $5}' | sed 's/%//')

if [[ $usage -gt $ALERT_THRESHOLD ]]; then
    echo "$(date): WARNING - Disk usage at ${usage}% (threshold: ${ALERT_THRESHOLD}%)" >> "$LOG_FILE"

    # Send alert via Azure CLI if available
    if command -v az >/dev/null 2>&1; then
        az monitor metrics alert create \
            --name "dify-storage-alert" \
            --description "Dify storage usage high" \
            --severity 2 \
            >/dev/null 2>&1 || true
    fi
fi

# Check mount status
if ! mount | grep -q "$MOUNT_POINT"; then
    echo "$(date): ERROR - Mount point $MOUNT_POINT is not mounted" >> "$LOG_FILE"
fi

# Log current status
echo "$(date): Storage usage: ${usage}%" >> "$LOG_FILE"
EOF

    chmod +x /usr/local/bin/dify-storage-monitor.sh

    # Add to crontab for regular monitoring
    (crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/dify-storage-monitor.sh") | crontab -

    log "SUCCESS" "Storage monitoring configured (runs every 15 minutes)"
}

perform_health_check() {
    log "INFO" "Performing system health check..."

    local errors=0

    # Check mount point
    if ! mount | grep -q "$MOUNT_POINT"; then
        log "ERROR" "Mount point $MOUNT_POINT is not mounted"
        ((errors++))
    fi

    # Check disk space
    local usage=$(df "$MOUNT_POINT" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $usage -gt 90 ]]; then
        log "WARN" "Disk usage is high: ${usage}%"
    fi

    # Check filesystem
    if ! fsck -n "${DETECTED_DISK}1" >/dev/null 2>&1; then
        log "ERROR" "Filesystem check failed"
        ((errors++))
    fi

    # Check Docker volumes
    for volume in "${EXISTING_DIFY_VOLUMES[@]}"; do
        local volume_path="$MOUNT_POINT/volumes/$volume"
        if [[ ! -d "$volume_path" ]]; then
            log "ERROR" "Volume directory missing: $volume_path"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log "SUCCESS" "Health check passed"
        return 0
    else
        log "ERROR" "Health check failed with $errors errors"
        return 1
    fi
}

#################################################################################
# Rollback Functions
#################################################################################

create_rollback_script() {
    log "INFO" "Creating rollback script..."

    cat > /usr/local/bin/dify-storage-rollback.sh << EOF
#!/bin/bash

# Dify Storage Rollback Script
# Generated by: $SCRIPT_NAME
# Date: $(date)

set -euo pipefail

MOUNT_POINT="$MOUNT_POINT"
BACKUP_DIR="$BACKUP_DIR"
DETECTED_DISK="$DETECTED_DISK"

echo "Starting Dify storage rollback..."

# Stop Docker services
if command -v docker >/dev/null 2>&1; then
    echo "Stopping Docker services..."
    docker compose -f /path/to/docker-compose.yaml down || true
fi

# Unmount the disk
if mount | grep -q "\$MOUNT_POINT"; then
    echo "Unmounting \$MOUNT_POINT..."
    umount "\$MOUNT_POINT"
fi

# Remove fstab entry
echo "Removing fstab entry..."
sed -i "\\|\$MOUNT_POINT|d" /etc/fstab

# Restore volume symbolic links
for volume in ${EXISTING_DIFY_VOLUMES[@]}; do
    link_path="/var/lib/docker/volumes/\$volume"
    backup_path="\${link_path}.backup.*"

    if [[ -L "\$link_path" ]]; then
        rm "\$link_path"
    fi

    if ls \$backup_path 1> /dev/null 2>&1; then
        latest_backup=\$(ls -t \$backup_path | head -1)
        mv "\$latest_backup" "\$link_path"
        echo "Restored volume: \$volume"
    fi
done

echo "Rollback completed. Please restart your services manually."
EOF

    chmod +x /usr/local/bin/dify-storage-rollback.sh
    log "SUCCESS" "Rollback script created: /usr/local/bin/dify-storage-rollback.sh"
}

#################################################################################
# Main Functions
#################################################################################

show_usage() {
    cat << EOF
Usage: sudo $0 [OPTIONS]

Azure VM Storage Setup Script for Dify

This script automates the setup of external storage for Dify on Azure VMs,
including disk detection, partitioning, mounting, and volume migration.

OPTIONS:
    -d, --disk-size SIZE    Target disk size (default: 1T)
    -m, --mount-point PATH  Mount point for external storage (default: /opt/dify-data)
    -b, --backup-dir PATH   Backup directory (default: /opt/dify-backups)
    -h, --help             Show this help message
    --dry-run              Show what would be done without making changes
    --skip-backup          Skip backup creation (not recommended)
    --skip-migration       Skip volume migration
    --rollback             Run rollback procedure

EXAMPLES:
    # Basic setup with defaults
    sudo $0

    # Specify custom disk size and mount point
    sudo $0 --disk-size 2T --mount-point /mnt/dify

    # Dry run to see what would be done
    sudo $0 --dry-run

    # Rollback changes
    sudo $0 --rollback

For more information, see the documentation in MANUAL.md
EOF
}

main() {
    local dry_run=false
    local skip_backup=false
    local skip_migration=false
    local rollback=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--disk-size)
                TARGET_DISK_SIZE="$2"
                shift 2
                ;;
            -m|--mount-point)
                MOUNT_POINT="$2"
                shift 2
                ;;
            -b|--backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --skip-backup)
                skip_backup=true
                shift
                ;;
            --skip-migration)
                skip_migration=true
                shift
                ;;
            --rollback)
                rollback=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Run rollback if requested
    if [[ "$rollback" == true ]]; then
        if [[ -f "/usr/local/bin/dify-storage-rollback.sh" ]]; then
            log "INFO" "Running rollback script..."
            /usr/local/bin/dify-storage-rollback.sh
        else
            log "ERROR" "Rollback script not found"
            exit 1
        fi
        exit 0
    fi

    # Show banner
    echo
    log "INFO" "Starting Dify Azure Storage Setup"
    log "INFO" "Target disk size: $TARGET_DISK_SIZE"
    log "INFO" "Mount point: $MOUNT_POINT"
    log "INFO" "Backup directory: $BACKUP_DIR"
    log "INFO" "Log file: $LOG_FILE"
    echo

    if [[ "$dry_run" == true ]]; then
        log "INFO" "DRY RUN MODE - No changes will be made"
        echo
    fi

    # Pre-flight checks
    check_root
    check_dependencies
    detect_azure_environment
    setup_azure_cli

    if [[ "$dry_run" == true ]]; then
        log "INFO" "Dry run completed. Use without --dry-run to apply changes."
        exit 0
    fi

    # Main execution
    detect_target_disk
    detect_dify_volumes

    # Create backup unless skipped
    if [[ "$skip_backup" != true ]]; then
        create_backup
    fi

    # Disk setup
    create_partition_and_filesystem "$DETECTED_DISK"
    create_mount_point
    mount_disk
    update_fstab

    # Azure-specific features
    if [[ -n "$AZURE_RESOURCE_GROUP" ]] && command -v az >/dev/null 2>&1; then
        local disk_name=$(basename "$DETECTED_DISK")
        tag_azure_disk "$disk_name"
        setup_azure_backup "$disk_name"
    fi

    # Volume migration unless skipped
    if [[ "$skip_migration" != true ]]; then
        migrate_volumes
    fi

    # Setup monitoring and health checks
    setup_monitoring
    create_rollback_script

    # Final health check
    if perform_health_check; then
        log "SUCCESS" "Azure storage setup completed successfully!"
        echo
        log "INFO" "Next steps:"
        log "INFO" "1. Restart Docker services: docker compose up -d"
        log "INFO" "2. Verify Dify is working correctly"
        log "INFO" "3. Monitor storage usage with: df -h $MOUNT_POINT"
        log "INFO" "4. View logs: tail -f $LOG_FILE"
        echo
        log "INFO" "Rollback script available at: /usr/local/bin/dify-storage-rollback.sh"
    else
        log "ERROR" "Setup completed with errors. Check logs for details."
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi