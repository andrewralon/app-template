# 04 — Local Development

Day-to-day development workflow for building and iterating on your app locally.

---

## Opening the Project

Always open the project via the `.xcodeproj` (not a workspace unless you use CocoaPods):

```bash
cd App
xcodegen generate     # regenerate if project.yml changed
open __APP_NAME__.xcodeproj
```

Or open directly from Xcode: File → Open Recent.

---

## Xcode Essentials

### Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Build | ⌘B |
| Run | ⌘R |
| Stop | ⌘. |
| Test | ⌘U |
| Clean build folder | ⌘⇧K |
| Show navigator | ⌘1 |
| Show debug area | ⌘⇧Y |
| Jump to definition | ⌃⌘J or ⌘click |
| Quick Open | ⌘⇧O |
| Open quickly (symbol) | ⌘⌃⇧O |
| Refactor/Rename | Right-click → Refactor |

### Build Configurations

Use the scheme dropdown (next to the play button):

- **Debug** — for local development; faster builds, more debug info
- **Release** — for distribution; optimized, slower to build

For TestFlight, always archive using Release configuration.

### Schemes

Schemes control what gets built and tested. XcodeGen creates one scheme per target. You can add custom schemes for staging environments.

Edit schemes: Product → Scheme → Edit Scheme (⌘<)

---

## Build Settings You Should Know

In `App/project.yml`, these are the most important `settings`:

```yaml
settings:
  base:
    MARKETING_VERSION: 1.0.0          # What users see (1.2.3)
    CURRENT_PROJECT_VERSION: 1        # Build number (integer, increments each upload)
    SWIFT_VERSION: 5.10
    DEVELOPMENT_TEAM: __TEAM_ID__
    SWIFT_STRICT_CONCURRENCY: complete # Enforce actor isolation (Swift 6 readiness)
    ENABLE_HARDENED_RUNTIME: YES      # Required for notarization
    DEBUG_INFORMATION_FORMAT: dwarf-with-dsym  # For crash symbolication
```

---

## Swift Packages

Add dependencies via Swift Package Manager, defined in `project.yml`:

```yaml
packages:
  MyPackage:
    url: https://github.com/author/MyPackage
    from: 1.0.0
```

Regenerate, then open Xcode — it resolves packages automatically on first open.

To update a package:
- Xcode → File → Packages → Update to Latest Package Versions
- Or: `swift package update` (if using SPM directly)

---

## Code Style

### SwiftFormat

Automatically reformats code. The template includes `.swiftformat` with sensible defaults. Run before every commit:

```bash
swiftformat App/Sources
```

Run on a single file:
```bash
swiftformat App/Sources/__APP_NAME__/App/ContentView.swift
```

Add a build phase in Xcode to run it automatically: Xcode → target → Build Phases → + → New Run Script Phase:
```bash
if which swiftformat >/dev/null; then
  swiftformat --config "${SRCROOT}/../.swiftformat" "${SRCROOT}"
fi
```

### SwiftLint

Catches anti-patterns and style issues. Configure in `.swiftlint.yml`:

```yaml
excluded:
  - App/Tests
  - App/UITests
  - App/.build

disabled_rules:
  - trailing_whitespace  # swiftformat handles this

opt_in_rules:
  - closure_spacing
  - explicit_init
  - force_unwrapping  # warn on !
  - implicitly_unwrapped_optional
```

Run:
```bash
swiftlint App/Sources
swiftlint --fix App/Sources  # auto-fix where possible
```

---

## Environment Configuration

Avoid hardcoding environment-specific values. Use a Config.plist or build settings:

### Option A — Build Setting Variables

In `project.yml`:
```yaml
settings:
  configs:
    Debug:
      API_BASE_URL: https://api-dev.example.com
    Release:
      API_BASE_URL: https://api.example.com
```

In `Info.plist`:
```xml
<key>API_BASE_URL</key>
<string>$(API_BASE_URL)</string>
```

In Swift:
```swift
let baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? ""
```

### Option B — xcconfig Files

Create `Config.xcconfig` per environment and reference in `project.yml`:
```yaml
configFiles:
  Debug: Config/Debug.xcconfig
  Release: Config/Release.xcconfig
```

Never put secrets (API keys, passwords) in source control. Use environment variables or a `.env` file loaded at build time.

---

## Debugging

### Print Debugging
```swift
print("Value: \(someValue)")  // shows in Xcode console
```

### LLDB
When paused at a breakpoint:
```
po someVariable       # print object description
p someExpression      # evaluate expression
bt                    # show backtrace
frame variable        # show local variables
```

### Breakpoints
- Click the line number gutter to set a breakpoint
- Right-click breakpoint → Edit Breakpoint → add conditions or actions
- Xcode → Debug → Breakpoints → Exception Breakpoint (catches all thrown exceptions)

### Network Debugging
Use Proxyman or Charles to inspect simulator network traffic:
1. Install Proxyman: `brew install --cask proxyman`
2. Install Proxyman root certificate for the simulator
3. All HTTP traffic from the simulator will appear in Proxyman

### Memory Debugging
- Product → Profile → Leaks instrument
- Debug → Memory Graph Debugger (the three-circle icon in the debug bar)

---

## Working With SwiftUI Previews

SwiftUI Previews run in a separate process. Keep preview code fast and pure:

```swift
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Loading State") {
    ContentView(viewModel: .preview(state: .loading))
}
```

If previews crash frequently:
- Clean build folder: ⌘⇧K → ⌘B
- Restart Xcode (last resort)
- Check for static initializers that access files or network

---

## Organizing Features

Use the Feature folder pattern from the source structure:

```
Features/
└── Settings/
    ├── SettingsView.swift          # SwiftUI view
    ├── SettingsViewModel.swift     # @Observable or ObservableObject
    └── Models/
        └── SettingsModel.swift
```

### ViewModel Pattern (Swift Observation)

For iOS 17+, use `@Observable`:

```swift
import Observation

@Observable
final class HomeViewModel {
    var items: [Item] = []
    var isLoading = false
    var error: Error?

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await ItemService.shared.fetchAll()
        } catch {
            self.error = error
        }
    }
}
```

```swift
struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.loadItems() }
    }
}
```

---

## Useful Xcode Features

### Minimap
View → Minimap — a small file overview on the right edge. Useful for navigation in long files.

### Structured Editing
Ctrl+I — re-indent selected code  
Editor → Structure → Embed in Group (wraps selected views)

### Source Control
Xcode has built-in git UI: Source Control → Source Control Navigator (⌘2 in navigator).

### Code Snippets
Create reusable code templates: Editor → Create Code Snippet. Useful for your common SwiftUI view patterns.
