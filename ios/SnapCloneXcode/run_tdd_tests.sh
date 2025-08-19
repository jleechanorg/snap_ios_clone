#!/bin/bash

# TDD Integration Test Runner
# Purpose: Execute specific TDD tests to capture RED phase failures

cd "/Users/jleechan/projects/snap_ios_clone/ios/SnapCloneXcode"

echo "🚨 TDD RED PHASE EXECUTION"
echo "Purpose: Document architecture disconnection failures"
echo "Expected: ALL tests should FAIL to prove current broken state"
echo "=========================================="

# Run TDD Integration Tests
xcodebuild test \
    -project SnapClone.xcodeproj \
    -scheme SnapClone \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
    -only-testing:SnapCloneTests/TDDIntegrationTests \
    2>&1 | tee tdd_test_results.log

echo "=========================================="
echo "🎯 TDD RED PHASE COMPLETE"
echo "Results logged to: tdd_test_results.log"
echo "Next Step: Analyze failures to drive GREEN phase implementation"