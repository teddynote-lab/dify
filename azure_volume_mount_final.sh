#!/bin/bash
# Azure VM Dify Storage Mount Script - Final Version
# Purpose: Mount additional Azure disk and migrate Dify Docker volumes
# Compatible with: Azure VM with unmounted disk
# Tested on: Azure Ubuntu VM with Dify

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MOUNT_POINT="/mnt/dify-storage"
DIFY_DIR="/home/azureuser/dify"
DOCKER_VOLUMES_DIR="${DIFY_DIR}/docker/volumes"
BACKUP_DIR="/tmp/dify-backup-$(date +%Y%m%d-%H%M%S)"
TARGET_DISK=""  # Will be auto-detected

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message $RED "This script must be run as root or with sudo"
        exit 1
    fi
}

# Function to find 1TB unmounted disk
find_target_disk() {
    print_message $YELLOW "Searching for 1TB unmounted disk..."
    
    # Find disks around 1TB size
    for disk in $(lsblk -rno NAME,TYPE,SIZE | grep disk | awk '$3~/^(9[0-9]{2}G|1\.?[0-9]?T)$/ {print $1}'); do
        # Check if disk has no partitions and is not mounted
        if ! lsblk -rno NAME "/dev/${disk}" | grep -q "^${disk}[0-9]"; then
            if ! mount | grep -q "/dev/${disk}"; then
                TARGET_DISK="/dev/${disk}"
                local size=$(lsblk -rno SIZE "/dev/${disk}" | head -1)
                print_message $GREEN "Found unmounted disk: ${TARGET_DISK} (${size})"
                return 0
            fi
        fi
    done
    
    print_message $RED "No suitable 1TB unmounted disk found!"
    print_message $YELLOW "Available disks:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    exit 1
}

# Function to create partition and filesystem
prepare_disk() {
    local disk=$1
    print_message $YELLOW "Preparing disk ${disk}..."
    
    # Create partition table
    print_message $GREEN "Creating GPT partition table..."
    parted -s ${disk} mklabel gpt || {
        print_message $RED "Failed to create partition table"
        exit 1
    }
    
    print_message $GREEN "Creating primary partition..."
    parted -s ${disk} mkpart primary ext4 0% 100% || {
        print_message $RED "Failed to create partition"
        exit 1
    }
    
    # Wait for partition to be created
    sleep 3
    
    # Get partition name
    local partition="${disk}1"
    if [[ ${disk} == *"nvme"* ]]; then
        partition="${disk}p1"
    fi
    
    # Verify partition exists
    if [[ ! -b ${partition} ]]; then
        print_message $RED "Partition ${partition} was not created!"
        exit 1
    fi
    
    # Create filesystem
    print_message $GREEN "Creating ext4 filesystem on ${partition}..."
    mkfs.ext4 -F ${partition} || {
        print_message $RED "Failed to create filesystem"
        exit 1
    }
    
    echo ${partition}
}

# Function to mount disk
mount_disk() {
    local partition=$1
    
    print_message $YELLOW "Mounting disk..."
    
    # Create mount point
    mkdir -p ${MOUNT_POINT}
    
    # Mount the partition
    mount ${partition} ${MOUNT_POINT} || {
        print_message $RED "Failed to mount partition"
        exit 1
    }
    
    # Get UUID for fstab
    local uuid=$(blkid -s UUID -o value ${partition})
    
    if [[ -z "${uuid}" ]]; then
        print_message $RED "Failed to get UUID for partition"
        exit 1
    fi
    
    # Add to fstab for persistent mount
    print_message $GREEN "Adding to /etc/fstab for persistent mount..."
    # Remove any existing entry for this mount point
    sed -i "\|${MOUNT_POINT}|d" /etc/fstab
    echo "UUID=${uuid} ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
    
    # Set permissions
    chmod 755 ${MOUNT_POINT}
    
    print_message $GREEN "Disk mounted successfully at ${MOUNT_POINT}"
    df -h ${MOUNT_POINT}
}

# Function to stop Docker services
stop_docker_services() {
    print_message $YELLOW "Stopping Docker services..."
    
    if [[ ! -d "${DIFY_DIR}/docker" ]]; then
        print_message $RED "Dify docker directory not found at ${DIFY_DIR}/docker"
        exit 1
    fi
    
    cd ${DIFY_DIR}/docker
    
    # Check if docker-compose.yaml exists
    if [[ ! -f "docker-compose.yaml" ]]; then
        print_message $RED "docker-compose.yaml not found!"
        exit 1
    fi
    
    docker compose down || docker-compose down || {
        print_message $RED "Failed to stop Docker services"
        exit 1
    }
    
    # Wait for services to stop completely
    sleep 5
    
    print_message $GREEN "Docker services stopped"
}

# Function to start Docker services
start_docker_services() {
    print_message $YELLOW "Starting Docker services..."
    
    cd ${DIFY_DIR}/docker
    
    docker compose up -d || docker-compose up -d || {
        print_message $RED "Failed to start Docker services"
        exit 1
    }
    
    # Wait for services to start
    sleep 15
    
    print_message $GREEN "Docker services started"
}

# Function to backup existing volumes
backup_volumes() {
    print_message $YELLOW "Creating backup of existing volumes..."
    
    if [[ ! -d "${DOCKER_VOLUMES_DIR}" ]]; then
        print_message $YELLOW "No existing volumes to backup"
        return 0
    fi
    
    mkdir -p ${BACKUP_DIR}
    
    # Use rsync to preserve permissions and ownership
    rsync -avP ${DOCKER_VOLUMES_DIR}/ ${BACKUP_DIR}/ || {
        print_message $RED "Failed to create backup"
        exit 1
    }
    
    print_message $GREEN "Backup created at ${BACKUP_DIR}"
}

# Function to migrate volumes
migrate_volumes() {
    print_message $YELLOW "Migrating Docker volumes to new storage..."
    
    # Create new volumes directory on mounted disk
    local new_volumes_dir="${MOUNT_POINT}/docker-volumes"
    mkdir -p ${new_volumes_dir}
    
    # Copy volumes to new location preserving permissions
    if [[ -d "${DOCKER_VOLUMES_DIR}" ]]; then
        rsync -avP ${DOCKER_VOLUMES_DIR}/ ${new_volumes_dir}/ || {
            print_message $RED "Failed to copy volumes"
            exit 1
        }
        
        # Get current owner of volumes directory (usually azureuser:azureuser)
        local owner=$(stat -c '%U:%G' ${DOCKER_VOLUMES_DIR} 2>/dev/null || echo "azureuser:azureuser")
    else
        local owner="azureuser:azureuser"
    fi
    
    # Rename old volumes directory if exists
    if [[ -d "${DOCKER_VOLUMES_DIR}" ]]; then
        mv ${DOCKER_VOLUMES_DIR} ${DOCKER_VOLUMES_DIR}.old || {
            print_message $RED "Failed to rename old volumes directory"
            exit 1
        }
    fi
    
    # Create symlink to new location
    ln -s ${new_volumes_dir} ${DOCKER_VOLUMES_DIR} || {
        print_message $RED "Failed to create symlink"
        # Restore old directory if symlink fails
        if [[ -d "${DOCKER_VOLUMES_DIR}.old" ]]; then
            mv ${DOCKER_VOLUMES_DIR}.old ${DOCKER_VOLUMES_DIR}
        fi
        exit 1
    }
    
    # Set ownership on new volumes directory
    chown -R ${owner} ${new_volumes_dir}
    
    print_message $GREEN "Volumes migrated successfully"
}

# Function to verify migration
verify_migration() {
    print_message $YELLOW "Verifying migration..."
    
    local success=true
    
    # Check if symlink exists
    if [[ -L ${DOCKER_VOLUMES_DIR} ]]; then
        print_message $GREEN "✓ Symlink created successfully"
        ls -la ${DOCKER_VOLUMES_DIR}
    else
        print_message $RED "✗ Symlink creation failed"
        success=false
    fi
    
    # Check if mount point is accessible
    if mountpoint -q ${MOUNT_POINT}; then
        print_message $GREEN "✓ Mount point is active"
    else
        print_message $RED "✗ Mount point is not active"
        success=false
    fi
    
    # Check disk space
    print_message $BLUE "Disk space information:"
    df -h ${MOUNT_POINT}
    echo ""
    df -h /
    
    if [[ ${success} == "false" ]]; then
        return 1
    fi
    
    return 0
}

# Function to rollback changes
rollback() {
    print_message $RED "Rolling back changes..."
    
    # Remove symlink
    if [[ -L ${DOCKER_VOLUMES_DIR} ]]; then
        rm ${DOCKER_VOLUMES_DIR}
    fi
    
    # Restore old volumes directory
    if [[ -d ${DOCKER_VOLUMES_DIR}.old ]]; then
        mv ${DOCKER_VOLUMES_DIR}.old ${DOCKER_VOLUMES_DIR}
    fi
    
    # Unmount disk
    if mountpoint -q ${MOUNT_POINT}; then
        umount ${MOUNT_POINT}
    fi
    
    # Remove from fstab
    sed -i "\|${MOUNT_POINT}|d" /etc/fstab
    
    print_message $YELLOW "Rollback completed. Please check your system."
}

# Main execution
main() {
    print_message $GREEN "=== Azure VM Dify Storage Mount Script ==="
    print_message $BLUE "Version: Final (Tested)"
    echo ""
    
    # Check if running as root
    check_root
    
    # Find target disk automatically
    find_target_disk
    
    print_message $YELLOW "\nThis script will:"
    print_message $YELLOW "1. Format disk ${TARGET_DISK}"
    print_message $YELLOW "2. Mount it at ${MOUNT_POINT}"
    print_message $YELLOW "3. Stop Dify Docker services"
    print_message $YELLOW "4. Migrate volumes to new storage"
    print_message $YELLOW "5. Restart Dify Docker services"
    echo ""
    
    # Ask for confirmation in automated mode
    if [[ "${1}" != "--yes" ]]; then
        read -p "Do you want to continue? (yes/no): " confirm
        if [[ "${confirm}" != "yes" ]]; then
            print_message $RED "Operation cancelled"
            exit 0
        fi
    fi
    
    # Prepare and mount disk
    PARTITION=$(prepare_disk ${TARGET_DISK})
    mount_disk ${PARTITION}
    
    # Stop Docker services
    stop_docker_services
    
    # Backup existing volumes
    backup_volumes
    
    # Migrate volumes
    migrate_volumes
    
    # Verify migration
    if verify_migration; then
        # Start Docker services
        start_docker_services
        
        # Wait a bit more for services to fully start
        print_message $YELLOW "Waiting for services to fully start..."
        sleep 10
        
        # Check Docker services status
        print_message $BLUE "\nDocker services status:"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|api|worker|db|redis|plugin|nginx|web|sandbox|qdrant" || true
        
        print_message $GREEN "\n=== Migration completed successfully! ==="
        print_message $GREEN "Backup saved at: ${BACKUP_DIR}"
        print_message $GREEN "New storage mounted at: ${MOUNT_POINT}"
        print_message $YELLOW "\nIMPORTANT: After verifying everything works correctly:"
        print_message $YELLOW "1. Remove the backup: sudo rm -rf ${BACKUP_DIR}"
        print_message $YELLOW "2. Remove old volumes: sudo rm -rf ${DOCKER_VOLUMES_DIR}.old"
        print_message $BLUE "\nTo verify file uploads work:"
        print_message $BLUE "1. Try uploading a file in Dify web interface"
        print_message $BLUE "2. Check if file appears in: ${MOUNT_POINT}/docker-volumes/app/storage/upload_files/"
    else
        print_message $RED "Migration verification failed!"
        print_message $YELLOW "Attempting rollback..."
        rollback
        exit 1
    fi
}

# Trap errors and rollback if needed
trap 'print_message $RED "Error occurred! Exit code: $?"; rollback; exit 1' ERR

# Run main function
main "$@"