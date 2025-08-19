# /history Command

**Usage**: `/history [search_query] [--options]`

**Purpose**: Search through Claude Code CLI conversation history stored in `.claude/projects` using intelligent execution optimization and multiple search strategies.

## Command Architecture

**`/history` uses `/execute`** for intelligent workflow optimization as requested by the user.

**Composition Pattern**: This command delegates to `/execute` which provides:
- Task complexity analysis 
- Execution strategy optimization
- Parallel processing when beneficial
- Resource-efficient search coordination

## Usage Examples

```bash
# Basic keyword search
/history "git merge conflicts"

# Search with date filter  
/history "database migration" --date "2025-08-01"

# Search specific project
/history "authentication bug" --project "worldarchitect.ai"

# Search by command type
/history --type "tool_use" --keyword "pytest"

# Complex search with multiple filters
/history "performance issue" --date "2025-08" --project "worldarchitect" --limit 10

# Search by git branch
/history "feature branch" --branch "dev1754"

# Fuzzy search for typos
/history "databse migratoin" --fuzzy

# Recent conversations only
/history "latest deployment" --recent 7  # last 7 days
```

## Search Capabilities

### Text Matching Strategies
1. **Exact Match**: Default behavior for precise keyword search
2. **Case-Insensitive**: Automatic case normalization  
3. **Tokenized Search**: Finds keywords within sentences
4. **Fuzzy Search**: `--fuzzy` flag for handling typos and variations

### Filter Options

#### Time-Based Filters
- `--date "YYYY-MM-DD"` - Exact date match
- `--date "YYYY-MM"` - Month match
- `--after "YYYY-MM-DD"` - After specific date
- `--before "YYYY-MM-DD"` - Before specific date  
- `--recent N` - Last N days

#### Project/Context Filters
- `--project "name"` - Filter by project directory path
- `--cwd "/path"` - Filter by working directory
- `--branch "branch-name"` - Filter by git branch

#### Message Type Filters  
- `--type "user|assistant|summary|tool_use"` - Filter by message type (including tool executions)
- `--user-type "external"` - Filter by user type
- `--has-tools` - Convenience flag equivalent to `--type "tool_use"` or messages with tool activity
- `--has-errors` - Messages with error indicators

#### Output Control
- `--limit N` - Maximum results (default: 20)
- `--context N` - Lines of context around matches (default: 2)
- `--format "json|text|table"` - Output format (default: text)
- `--files-only` - Show only matching file names

## Implementation Details

### Performance Optimization (Based on Research)
1. **Streaming JSONL Processing**: Line-by-line parsing to avoid memory issues
2. **Pre-filtering Pipeline**: Filter by high-selectivity metadata first (date, project, session)
3. **Parallel File Processing**: Process multiple conversation files concurrently
4. **Smart File Discovery**: Efficiently locate candidate files by directory structure

### Search Algorithm
```
1. Parse search query and extract filters
2. Discover candidate files based on project/date filters
3. For each file (in parallel):
   - Stream parse JSONL line by line
   - Pre-filter by metadata (timestamp, cwd, branch)
   - Apply text search to message content
   - Collect matches with context
4. Aggregate, rank, and format results
5. Apply output limits and formatting
```

### File Format Understanding
Based on research of `.claude/projects` structure:

**Directory Structure**:
```
.claude/projects/
├── -home-jleechan-projects-worldarchitect-ai/
│   ├── uuid1.jsonl
│   ├── uuid2.jsonl
│   └── ...
└── -home-jleechan-projects-other-project/
    └── ...
```

Note on naming: project directories are sanitized absolute paths where `/` is replaced with `-` (e.g., `/home/jleechan/projects/worldarchitect.ai` → `-home-jleechan-projects-worldarchitect-ai`). On Windows, backslashes `\` are normalized similarly.

**JSONL Format** (per conversation file):
```jsonl
{"type":"summary","summary":"Conversation summary","leafUuid":"uuid"}
{"parentUuid":null,"userType":"external","cwd":"/path","sessionId":"uuid","version":"1.0.67","gitBranch":"main","type":"user","message":{"role":"user","content":"user message"},"uuid":"uuid","timestamp":"2025-08-09T..."}
{"parentUuid":"uuid","type":"assistant","message":{"role":"assistant","content":"assistant response"},"uuid":"uuid","timestamp":"2025-08-09T..."}
```

Detection rules:
- Tool usage: records with `type:"tool_use"` or `message.toolCalls`/`toolUse` present.
- Errors: `error:true` at top-level, or `message.level in {"error","fatal"}`, or `message.content` containing standardized error markers.
Document any repository-specific variations here to keep the filters accurate.

### Integration with `/execute`

The `/history` command delegates its execution to `/execute` with a comprehensive task description that includes secure file access:

```
/execute Search through Claude Code CLI conversation history using secure file access:
- Query: [user_search_query]
- Filters: [parsed_filter_options] 
- Strategy: Python glob + JSONL stream processing for security compliance
- Access Method: Use python3 with glob.glob(os.path.expanduser('~/.claude/projects/*/*.jsonl'))
- Security: Direct access to user's home directory without workspace symlinks
- Algorithm: Python file discovery → JSONL parsing → Text search → Context extraction → Results formatting
- Output: Formatted search results with conversation context
```

This allows `/execute` to:
- Analyze the search complexity (number of files, query complexity)
- Choose optimal execution strategy (parallel vs sequential)
- Handle resource management and error recovery
- Provide intelligent progress reporting

## Output Format

### Default Text Format
```
=== Conversation History Search Results ===
Query: "git merge conflicts"
Found: 3 matches in 2 conversations

📁 worldarchitect.ai | 📅 2025-08-01 | 🌿 dev1754132318
💬 "I need help resolving git merge conflicts in the authentication module..."
   Context: Discussion about merge strategy and conflict resolution tools
   File: 7859c820-1ba2-41c5-9db1-22c6814455e6.jsonl

📁 worldarchitect.ai | 📅 2025-07-28 | 🌿 main  
💬 "The git merge created conflicts in package.json..."
   Context: Package dependency conflicts during feature merge
   File: a1b2c3d4-e5f6-7890-abcd-ef1234567890.jsonl
```

### JSON Format (`--format json`)
```json
{
  "query": "git merge conflicts",
  "total_matches": 3,
  "total_files": 2,
  "results": [
    {
      "conversation_id": "7859c820-1ba2-41c5-9db1-22c6814455e6",
      "project": "worldarchitect.ai", 
      "date": "2025-08-01",
      "branch": "dev1754132318",
      "match": {
        "message": "I need help resolving git merge conflicts...",
        "context": ["Previous message...", "Matched message", "Next message..."],
        "timestamp": "2025-08-01T11:00:11.845Z"
      }
    }
  ]
}
```

### Table Format (`--format table`)
```
Query: git merge conflicts | Matches: 3 | Files: 2
┌──────────────────────┬───────────────┬──────────────┬───────────────┬──────────────────────────────────────┐
│ conversation_id      │ project       │ date         │ branch        │ message_snippet                      │
├──────────────────────┼───────────────┼──────────────┼───────────────┼──────────────────────────────────────┤
│ 7859c820-...-55e6    │ worldarchitect│ 2025-08-01   │ dev1754132318 │ I need help resolving git merge ...  │
│ a1b2c3d4-...-7890    │ worldarchitect│ 2025-07-28   │ main          │ The git merge created conflicts ...  │
└──────────────────────┴───────────────┴──────────────┴───────────────┴──────────────────────────────────────┘
```

## Error Handling

- **Missing Directory**: Graceful handling if `.claude/projects` doesn't exist
- **Corrupted JSONL**: Skip malformed lines with warning
- **Permission Issues**: Clear error messages for access problems  
- **Large Result Sets**: Automatic pagination and memory management
- **No Matches**: Helpful suggestions for refining search query

## Integration Features

### Secure File Access
The command uses secure direct access to `~/.claude/projects/` directory, avoiding symlink vulnerabilities while maintaining search functionality within the project workspace.

### Memory MCP Integration
Search patterns and frequently accessed conversations can be cached in Memory MCP for faster repeated searches.

### Command Composition  
Can be combined with other commands:
```bash
/history "database issue" | /learn    # Learn from historical database solutions
/history "deployment error" | /debug  # Debug with historical context
```

## Advanced Features

### Semantic Search (Future Enhancement)
- Leverage embeddings for conceptual similarity matching
- Find conversations about similar topics even with different keywords

### Query Intelligence
- Auto-suggest corrections for common typos
- Recommend related search terms based on conversation patterns
- Historical query analysis for better search suggestions

## Examples of Complex Searches

```bash
# Find all tool usage in August 2025
/history --type "tool_use" --date "2025-08" --format table

# Search for authentication-related conversations in specific project
/history "auth login password" --project "worldarchitect" --limit 5

# Find recent error discussions 
/history "error exception failed" --recent 14 --has-tools

# Fuzzy search with context
/history "databse migratoin problm" --fuzzy --context 5

# Find conversations about specific files
/history "main.py" --project "worldarchitect" --format json
```

This command provides comprehensive conversation history search capabilities while leveraging `/execute` for intelligent performance optimization as requested.