# Integration Command

**Purpose**: Create fresh branch from main and cleanup test servers

**Action**: Stop test server → Run `./integrate.sh` script → Clean environment

**Usage**:
- `/integrate` - Creates dev{timestamp} branch
- `/integrate [branch-name]` - Creates branch with custom name
- `/integrate --force` - Override safety checks

**Examples**:
- `/integrate` - Creates dev1752251680 branch
- `/integrate newb` - Creates newb branch
- `/integrate feature/my-feature` - Creates feature/my-feature branch
- `/integrate fix/bug-123 --force` - Creates fix/bug-123 branch, overriding checks

**Enhanced Implementation**:
- **Auto-Learning**: Automatically trigger `/learn` to capture insights from completed work
- Stop test server for current branch (if running)
- Execute `./integrate.sh` script with optional branch name
- Creates new branch from latest main
- Ensures clean starting point for new features
- Pulls latest changes from main
- Sets up custom or timestamp-based branch naming
- Cleans up branch-specific test server resources
- **Learning Documentation**: Capture and document patterns from previous branch work

**Test Server Integration**:
- Automatically stops test server for current branch before integration
- Removes branch-specific PID and log files
- Ensures no orphaned server processes
- New branch starts with clean server state
- Use `/push` to start server for new branch
