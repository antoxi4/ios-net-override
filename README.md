# iOS Net Override

Domain Redirect Guard is a lightweight networking tool that lets you override a domain’s destination IP without touching DNS records.

## Build Status

[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![iOS](https://img.shields.io/badge/iOS-17.0+-green.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Prerequisites

Before building and running this project, ensure you have:

### Development Environment
- **macOS**: Sonoma 14.0 or later
- **Xcode**: 15.0 or later
- **iOS Device**: Physical device with iOS 17.0 or later (required for network extensions)

### Apple Developer Account
- **Active Apple Developer Program membership** (required for:
  - Network Extension entitlements
  - App Groups capability
  - Code signing and provisioning profiles)

### Capabilities & Entitlements
The project requires the following capabilities:
- **Network Extensions**: `dns-proxy`
- **App Groups**: Shared data between main app and extension

## Running

### Building the Project

1. **Clone the repository**
   ```bash
   git clone https://github.com/antoxi4/ios-net-override.git
   cd ios-net-override
   ```

2. **Configure App Identifiers** (Automated)
   
   Run the setup script to automatically configure all bundle identifiers:
   ```bash
   ./setup.sh
   ```
   
   Enter your base bundle identifier when prompted (e.g., `com.yourname.NetOverride`).
   The script will automatically update:
   - `AppConfig.swift`
   - Project bundle identifiers
   - Entitlements files with app group
   
   <details>
   <summary>Manual Configuration (Alternative)</summary>
   
   If you prefer to configure manually:
   - Open `AppConfig.swift` in the project root
   - Update the following values:
     ```swift
     case appExtensionBundleIdentifier = "your.bundle.id.netextension"
     case appGroupIdentifier = "group.your.bundle.id"
     ```
   - Update bundle identifiers in Xcode project settings
   - Update app group in both entitlements files
   </details>

3. **Create App Group in Apple Developer Account**
   - Go to [Apple Developer Account - App Groups](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
   - Create a new App Group with the identifier from step 2 (e.g., `group.com.yourname.NetOverride`)

4. **Configure code signing in Xcode**
   ```bash
   open NetOverride.xcodeproj
   ```
   - Select the `NetOverride` project in the navigator
   - For each target (`NetOverride` and `netextension`):
     - Go to "Signing & Capabilities"
     - Select your development team
     - Verify bundle identifiers are correct
     - Ensure App Groups capability shows your app group
     - Ensure provisioning profiles are valid

5. **Build and Run**
   - Connect your iOS device (network extensions don't work in Simulator)
   - Select your device from the scheme menu
   - Press `⌘R` or click the Run button

### Distribution & Deployment

⚠️ **Important Limitation:**

This app **cannot be distributed via TestFlight or the App Store** due to Apple's restrictions on DNS Proxy Network Extensions. Apps using `dns-proxy` network extensions can only run with **development provisioning profiles**.

**To use this app:**
1. Build the project in Xcode with your Apple Developer account
2. Use a **development provisioning profile** (not Ad-Hoc or App Store)
3. Install directly on your registered development device
4. You can register up to 100 devices per year in your Apple Developer account

**Note:** This limitation is an Apple security policy for DNS Proxy Network Extensions to prevent unauthorized network interception. Only development builds and MDM-managed enterprise deployments are supported.

## Contribution Rules

We welcome contributions! Please follow these guidelines:

### Code Style

- **Swift Style Guide**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **Formatting**: Use consistent indentation (4 spaces)
- **MARK Comments**: Organize code with `// MARK: - Section Name`
- **Naming Conventions**:
  - Classes/Structs: `PascalCase`
  - Functions/Variables: `camelCase`
  - Constants: `camelCase` or `UPPER_CASE` for static constants

### Git Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. **Commit message format**
   ```
   type: brief description
   
   Detailed explanation (if needed)
   
   Types: feat, fix, docs, refactor, test, chore
   ```
   
   Examples:
   - `feat: add wildcard domain support`
   - `fix: resolve memory leak in DNS parser`
   - `docs: update installation instructions`

3. **Keep commits focused**
   - One logical change per commit
   - Commit message should clearly describe what and why

4. **Pull Request guidelines**
   - Provide a clear and meaningfull title
   - Provide a clear description of changes
   - Reference related issues (if any)
   - Ensure all tests pass
   - Update documentation if needed

### Code Review Process

1. **Before submitting:**
   - Build succeeds without warnings
   - Code follows project style guidelines
   - No debug code or commented-out blocks
   - Logging uses `Logger` utility (not `print` or `NSLog`)

2. **PR Review:**
   - At least one approval required from repository owner
   - Address all review comments
   - Keep PR scope focused

3. **After approval:**
   - Squash commits if needed
   - Merge to main branch

### Testing

- Test on physical iOS devices (network extensions don't work in Simulator)
- Verify both enabled and disabled states work correctly
- Test with multiple domain configurations
- Check for memory leaks and performance issues

### Issue Reporting

When reporting bugs, include:
- iOS version
- Device model
- Steps to reproduce
- Expected vs actual behavior
- Console logs (if applicable)

### Feature Requests

- Open an issue with the `enhancement` label
- Describe the use case
- Explain expected behavior
- Provide mockups or examples (if applicable)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **Author**: Anton Yashyn
- **GitHub**: [@antoxi4](https://github.com/antoxi4)
- **Repository**: [ios-net-override](https://github.com/antoxi4/ios-net-override)

**Note**: This project requires a physical iOS device for testing. Network extensions do not work in the iOS Simulator.
