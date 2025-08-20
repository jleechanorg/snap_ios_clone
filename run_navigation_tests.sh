#!/bin/bash

#
# SnapClone Navigation Test Runner
# Runs comprehensive UI automation tests for navigation verification
# Generated with Claude Code for TDD Green phase testing
#

set -e

echo "🚀 SnapClone Navigation Test Runner"
echo "======================================"
echo ""

# Configuration
PROJECT_PATH="/Users/jleechan/projects/snap_ios_clone/ios/SnapCloneXcode"
SCHEME="SnapClone"
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro,OS=latest"
TEST_RESULTS_DIR="$PROJECT_PATH/TestResults"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Xcode project exists
check_project() {
    print_status "Checking project structure..."
    
    if [ ! -d "$PROJECT_PATH" ]; then
        print_error "Project directory not found: $PROJECT_PATH"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_PATH/SnapClone.xcodeproj/project.pbxproj" ]; then
        print_error "Xcode project not found in: $PROJECT_PATH"
        exit 1
    fi
    
    print_success "Project structure verified"
}

# Clean previous test results
clean_results() {
    print_status "Cleaning previous test results..."
    
    if [ -d "$TEST_RESULTS_DIR" ]; then
        rm -rf "$TEST_RESULTS_DIR"
    fi
    
    mkdir -p "$TEST_RESULTS_DIR"
    print_success "Test results directory prepared"
}

# Build the app for testing
build_app() {
    print_status "Building app for testing..."
    
    cd "$PROJECT_PATH"
    
    # Clean build folder
    xcodebuild clean -project SnapClone.xcodeproj -scheme "$SCHEME" -destination "$DESTINATION" 2>/dev/null || {
        print_warning "Clean failed, continuing..."
    }
    
    # Build for testing
    xcodebuild build-for-testing \
        -project SnapClone.xcodeproj \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" || {
        print_error "Build failed"
        exit 1
    }
    
    print_success "App built successfully"
}

# Run specific test suite
run_test_suite() {
    local test_class="$1"
    local test_name="$2"
    
    print_status "Running $test_name tests..."
    
    cd "$PROJECT_PATH"
    
    # Run the tests
    xcodebuild test-without-building \
        -project SnapClone.xcodeproj \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
        -only-testing "SnapCloneTests/$test_class" \
        -resultBundlePath "$TEST_RESULTS_DIR/${test_class}_Results.xcresult" 2>&1 | tee "$TEST_RESULTS_DIR/${test_class}_output.log"
    
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        print_success "$test_name tests PASSED"
    else
        print_error "$test_name tests FAILED (exit code: $exit_code)"
        return $exit_code
    fi
}

# Generate test report
generate_report() {
    print_status "Generating test report..."
    
    local report_file="$TEST_RESULTS_DIR/navigation_test_report.md"
    
    cat > "$report_file" << EOF
# SnapClone Navigation Test Report

**Generated:** $(date)
**Test Environment:** iOS Simulator - iPhone 15 Pro
**Project:** SnapClone
**Test Focus:** Navigation Flow Verification

## Test Execution Summary

EOF

    # Check for test results
    if [ -f "$TEST_RESULTS_DIR/NavigationTests_output.log" ]; then
        echo "### NavigationTests Results" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
        tail -20 "$TEST_RESULTS_DIR/NavigationTests_output.log" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    if [ -f "$TEST_RESULTS_DIR/SnapCloneNavigationTests_output.log" ]; then
        echo "### SnapCloneNavigationTests Results" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
        tail -20 "$TEST_RESULTS_DIR/SnapCloneNavigationTests_output.log" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## Test Files Location

- Comprehensive Tests: \`ios/SnapCloneXcode/SnapCloneTests/SnapCloneNavigationTests.swift\`
- Original Tests: \`ios/SnapCloneXcode/SnapCloneTests/NavigationTests.swift\`
- Test Results: \`TestResults/\`

## Key Navigation Points Tested

1. **Login Flow:** Google Sign-In and Snapchat Sign-In buttons
2. **Main App Navigation:** Tab bar appearance after authentication
3. **Tab Switching:** Camera, Stories, Chat, Profile navigation
4. **Camera Controls:** Capture, FlipCamera, Flash button interactions
5. **Sign Out Flow:** Return to login screen verification
6. **Performance:** Navigation timing and stability testing

## Debugging Information

- Screenshots captured for each major navigation step
- Detailed logging with timing information
- Element existence and hittability verification
- Comprehensive error reporting with visual evidence

EOF

    print_success "Test report generated: $report_file"
}

# Open test results in Xcode (if available)
open_results() {
    print_status "Opening test results..."
    
    for result_bundle in "$TEST_RESULTS_DIR"/*.xcresult; do
        if [ -f "$result_bundle" ]; then
            print_status "Opening $result_bundle in Xcode..."
            open "$result_bundle" 2>/dev/null || {
                print_warning "Could not open results in Xcode"
            }
        fi
    done
}

# Main execution flow
main() {
    echo "Starting navigation test suite..."
    echo ""
    
    # Preparation
    check_project
    clean_results
    build_app
    
    echo ""
    print_status "=========================================="
    print_status "RUNNING NAVIGATION TESTS"
    print_status "=========================================="
    echo ""
    
    # Track test results
    local all_passed=true
    
    # Run original navigation tests
    if ! run_test_suite "NavigationTests" "Original Navigation"; then
        all_passed=false
    fi
    
    echo ""
    
    # Run comprehensive navigation tests
    if ! run_test_suite "SnapCloneNavigationTests" "Comprehensive Navigation"; then
        all_passed=false
    fi
    
    echo ""
    print_status "=========================================="
    print_status "TEST EXECUTION COMPLETE"
    print_status "=========================================="
    echo ""
    
    # Generate report
    generate_report
    
    # Show results summary
    if [ "$all_passed" = true ]; then
        print_success "🎉 ALL NAVIGATION TESTS PASSED!"
        print_success "Your navigation flow is working correctly."
    else
        print_error "❌ SOME TESTS FAILED"
        print_error "Check the test output above and the generated report for details."
        print_status "Test results and screenshots are available in: $TEST_RESULTS_DIR"
    fi
    
    echo ""
    print_status "Test artifacts:"
    print_status "  📊 Test Report: $TEST_RESULTS_DIR/navigation_test_report.md"
    print_status "  📸 Screenshots: Available in .xcresult bundles"
    print_status "  📝 Logs: $TEST_RESULTS_DIR/*_output.log"
    
    # Optionally open results
    if command -v open >/dev/null 2>&1; then
        echo ""
        read -p "Open test results in Xcode? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open_results
        fi
    fi
    
    # Return appropriate exit code
    if [ "$all_passed" = false ]; then
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo ""
        echo "SnapClone Navigation Test Runner"
        echo ""
        echo "This script runs comprehensive UI automation tests to verify"
        echo "the navigation flow in your SnapClone iOS app."
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "The script will:"
        echo "  1. Build the app for testing"
        echo "  2. Run navigation tests with detailed logging"
        echo "  3. Capture screenshots for debugging"
        echo "  4. Generate a comprehensive test report"
        echo ""
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information."
        exit 1
        ;;
esac