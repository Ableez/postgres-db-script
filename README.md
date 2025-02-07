# Local Database Docker Starter Script

This script simplifies the process of starting, stopping, restarting, and managing local development database containers using Docker. It supports PostgreSQL and offers a user-friendly interface for database creation and management.

## Features

*   **Easy Setup:** Quickly spin up a local database instance with a single command.
*   **Multiple Databases:** Manage multiple databases concurrently, each with its own name and port.
*   **Flexible Configuration:** Customize database name, port, user, and password.
*   **Command-Line Interface:** Control database operations through a simple and intuitive command-line interface.
*   **Data Persistence:** Database data is stored in a persistent volume, ensuring data is not lost between container restarts.
*   **Cross-Platform Compatibility:** Works on Linux, macOS, and Windows (via WSL).

## How to Use

1.  **Installation:** Ensure you have Docker installed on your system. For Windows, install WSL and Docker Desktop for Windows.

2.  **Clone the Repository (Optional):** If you've obtained the script from a repository, clone it to your local machine.

3.  **Run the Script:** Navigate to the script's directory in your terminal and execute it.

    *   **Linux/macOS:** `./start-database.sh`
    *   **Windows (WSL):** `./start-database.sh`

4.  **Interactive Mode:** Running the script without any arguments will start an interactive session, prompting you for database details.

5.  **Command-Line Options:** Use the following options for more control:

    ```bash
    ./start-database.sh [COMMAND] [OPTIONS]
    ```

    **Commands:**

    *   `start`: Start a new database container (default).
    *   `stop`: Stop a running database container.
    *   `restart`: Restart a database container.
    *   `remove`: Remove a database container (data will be deleted).
    *   `list`: List all database containers.
    *   `status`: Show status of all database containers.

    **Options:**

    *   `-h`, `--help`: Show this help message.
    *   `-n`, `--name`: Database name (default: `test`).
    *   `-p`, `--port`: Port number (default: `5432`).
    *   `-f`, `--force`: Force the operation without confirmation (use with caution).
    *   `-a`, `--all`: Apply operation to all containers (with `stop`/`remove`).

    **Examples:**

    ```bash
    ./start-database.sh start -n my_database -p 5433  # Start a database named 'my_database' on port 5433
    ./start-database.sh stop -n my_database          # Stop the 'my_database' container
    ./start-database.sh remove --all -f             # Forcefully remove all database containers
    ./start-database.sh list                       # List all database containers
    ./start-database.sh status                     # Show status of all containers
    ```

## How It Works

The script uses Docker to create and manage database containers. It performs the following steps:

1.  **Checks Dependencies:** Verifies that Docker is installed and running.
2.  **Parses Arguments:** Processes command-line options to determine the desired action and configuration.
3.  **Handles Commands:** Executes the specified command (start, stop, restart, remove, list, status).
4.  **Manages Containers:** Uses Docker commands to create, start, stop, restart, and remove containers.
5.  **Data Persistence:** Mounts a local directory as a volume in the container to persist database data.
6.  **Provides Information:** Displays connection details, including the connection URL, after successfully starting a database.

## Data Directory

Database data is stored in the `$HOME/docker_postgres_data` directory. Each database has its own subdirectory within this directory.  It's crucial to back up this directory if you need to preserve your data.

## Troubleshooting

*   **Permissions:** If you encounter permission errors, try running the script with `sudo` or adding your user to the `docker` group.
*   **Port Conflicts:** If the specified port is already in use, choose a different port.
*   **Docker Daemon:** Ensure the Docker daemon is running before running the script.
*   **Disk Space:** Ensure you have sufficient disk space available for the database data.

This script simplifies local database management for development.  If you have any issues or suggestions, please feel free to contribute!

follow me on X [ableezz](https://x.com/ableezz)
