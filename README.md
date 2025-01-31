# Directory Permission Sync

A Linux service that automatically maintains consistent ownership and permissions when files and directories are moved or created. The daemon watches a directory tree and ensures that any content moved into or created within a directory inherits the parent directory's ownership and predefined permission modes.

## Problem It Solves

In Linux filesystems, when files or directories are moved, they retain their original ownership and permissions rather than inheriting from their new parent directory. This can cause issues in shared environments where:
1. Files moved to a different directory should inherit new ownership/group ownership
2. Specific directories need to maintain consistent permissions for all contents
3. Different user groups need different access levels to different directories

## Features

- Monitors directory tree for moved or created files/directories
- Automatically updates ownership to match parent directory
- Sets consistent permissions (770 for directories, 660 for files)
- Handles nested directory structures
- Uses efficient inotify monitoring
- Full systemd integration
- Robust error handling and logging

## Installation

1. Install required packages:
```bash
# For RHEL/CentOS
sudo yum install inotify-tools

# For Ubuntu/Debian
sudo apt-get install inotify-tools
```

2. Copy the script:
```bash
sudo cp inotify-inherit.sh /opt/dwara/bin/
sudo chmod +x /opt/dwara/bin/inotify-inherit.sh
```

3. Install the systemd service:
```bash
sudo cp inotify-inherit.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable inotify-inherit
sudo systemctl start inotify-inherit
```

## Configuration

The script is configured through two main settings:

1. `WATCH_PARENT`: The root directory to monitor
2. Permission modes:
   - Directories: 770 (rwxrwx---)
   - Files: 660 (rw-rw----)

Modify these in the script if you need different settings.

## Use Cases

- Shared research directories where data needs to maintain specific group ownership
- Production environments where files need consistent permissions as they move through different stages
- Backup directories where moved files should inherit specific ownership/permissions
- Any scenario where directory location should determine file access patterns

## System Requirements

- Linux system with systemd
- inotify-tools package
- Sufficient inotify watches (see Troubleshooting)
- Root access for installation

## Troubleshooting

When working with large directory structures or high-activity filesystems, you might need to adjust two important kernel parameters:

### Inotify Watch Limit

If you have many subdirectories, increase the inotify watch limit:

```bash
# Check current watch limit
cat /proc/sys/fs/inotify/max_user_watches

# Increase watch limit (adjust number based on your needs)
echo "fs.inotify.max_user_watches = 1048576" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Each watch consumes approximately 1KB of kernel memory.

### Event Queue Size

If many file operations happen simultaneously, increase the event queue size:

```bash
# Check current queue size
cat /proc/sys/fs/inotify/max_queued_events

# Increase queue size (adjust based on your activity patterns)
echo "fs.inotify.max_queued_events = 1048576" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Each queued event consumes approximately 256 bytes of memory.

Choose these values based on:
- Number of directories being watched
- Frequency of file operations
- Available system memory
- Peak file operation patterns

## Known Limitations

- Only handles ownership and basic permissions (not ACLs)
- Must run as root to change ownership
- Watches entire directory tree under WATCH_PARENT
- Additional resource usage proportional to the number of watched directories

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)

## Acknowledgments

Developed to solve permission inheritance issues in shared storage environments. Special thanks to the inotify-tools developers for providing the underlying watch functionality.
