# List Commands Command

**Purpose**: Display all available slash commands with descriptions

**Action**: Show comprehensive list of all slash commands and their purposes

**Usage**: `/list`

**Available Commands**:
- `/pr [task]` - End-to-end implementation from idea to working PR
- `/perp <query>` - Multi-engine search across Claude, DuckDuckGo, and Perplexity
- `/handoff [task] [description]` - Create structured task handoff with PR and worker prompt
- `/execute` or `/e` - Execute tasks with TodoWrite circuit breaker
- `/think [mode]` - Enable sequential thinking for complex analysis
- `/thinku` - Direct alias for `/think ultra` (maximum-depth analysis)
- `/learn [topic]` - Capture learnings and update documentation
- `/header` - Get git branch status for mandatory response header
- `/newbranch` or `/nb` - Create new branch from latest main
- `/4layer` or `/tddf` - Test-driven development protocol
- `/testui` - Run browser tests with mock APIs
- `/testuif` - Run browser tests with real APIs
- `/testhttp` - Run HTTP tests with mock APIs
- `/coverage` - Generate test coverage reports
- `/push` - Smart git push with PR creation/update and test server
- `/pushlite` or `/pushl` - Simple push without automation
- `/review` - Automated code review process
- `/archreview` or `/arch` - Architecture and design review with dual-perspective analysis
- `/reviewdeep` or `/reviewd` - Deep review with ultra thinking mode (12-point analysis)

**Implementation**:
- Display all available slash commands
- Include purpose and brief description for each
- Show command aliases where applicable
- Provide usage examples

## Testing Commands (Real-Mode Testing Framework)
- `/teste` - Run end-to-end tests with mock services (fast, free)
- `/tester` - Run end-to-end tests with real services (costs money)
- `/testerc` - Run end-to-end tests with real services + data capture

## Other Commands
- Additional slash commands as defined in other .md files in this directory
