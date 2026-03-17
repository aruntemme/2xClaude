# 2x Claude

An iOS app with a home screen widget that shows when Claude's 2x usage promotion is active.

## Why?

Anthropic is running a [limited-time promotion](https://support.claude.com/en/articles/14063676-claude-march-2026-usage-promotion) (March 13–28, 2026) that **doubles usage limits** during off-peak hours — outside 8 AM–2 PM ET on weekdays. This applies automatically to Free, Pro, Max, and Team plans across all Claude platforms.

The problem: it's easy to lose track of whether you're in the 2x window or not. This app puts that info on your home screen so you can glance at your widget and know instantly if now is the right time to burn through those extra tokens.

## Requirements

- iOS 16.0+
- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (to generate the Xcode project)

## Setup

```bash
xcodegen generate
open TwoXClaude.xcodeproj
```
