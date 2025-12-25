# Adding Factory Package to Xcode - Step by Step

Since the project uses Xcode's File System Synchronized Groups, all Swift files are automatically included. You just need to add the Factory package dependency.

## Option 1: Via Xcode GUI (Recommended)

### Step 1: Open Project
```
1. Double-click: ChatushApp.xcodeproj
   or
2. From terminal: open ChatushApp.xcodeproj
```

### Step 2: Navigate to Package Dependencies
```
1. Click on "ChatushApp" project (blue icon) in the navigator
2. Select "ChatushApp" target (under TARGETS)
3. Click "General" tab at the top
4. Scroll down to "Frameworks, Libraries, and Embedded Content"
```

### Step 3: Add Package
```
1. Click the "+" button under the frameworks list
2. In the popup, click "Add Package Dependency..." (bottom left)
3. In the search field (top right), enter:
   https://github.com/hmlongco/Factory.git
4. Click "Add Package"
5. In version dialog:
   - Dependency Rule: "Up to Next Major Version"
   - Version: 2.3.0
6. Click "Add Package" again
7. Ensure "Factory" is selected
8. Add to Target: ChatushApp
9. Click "Add Package" one more time
```

### Step 4: Verify Installation
```
1. In project navigator, you should see:
   - "ChatushApp" folder
   - "ChatushSDK" folder
   - "Package Dependencies" folder (with Factory inside)
   
2. If you see Package Dependencies → Factory → ✅ You're ready!
```

### Step 5: Build
```
1. Select a simulator (iPhone 15 Pro recommended)
2. Press Cmd+B to build
3. Wait for dependencies to resolve (first time only)
4. If build succeeds: Press Cmd+R to run!
```

## Option 2: Via Package.swift (Alternative)

If you prefer to manually edit the project:

1. Close Xcode
2. Open `ChatushApp.xcodeproj/project.pbxproj` in a text editor
3. Find the `packageReferences` section
4. Add Factory reference (if not already there)
5. Save and reopen in Xcode
6. Xcode will auto-resolve dependencies

**Note**: The GUI method is simpler and less error-prone.

## Option 3: Via Terminal (For Automation)

```bash
cd /Users/bari.levi/Dev_env/Chatush

# This will open Xcode and you can follow GUI steps
open ChatushApp.xcodeproj
```

## Troubleshooting

### "Failed to resolve dependencies"
```
Solution:
1. File → Packages → Reset Package Caches
2. File → Packages → Update to Latest Package Versions
3. Clean Build Folder (Cmd+Shift+K)
4. Build again (Cmd+B)
```

### "No such module 'Factory'"
```
Solution:
1. Verify Factory appears under Package Dependencies
2. Check Target → Build Phases → Link Binary With Libraries
3. Factory should be listed there
4. If not, remove and re-add the package
```

### Files showing as red in navigator
```
Solution:
1. The project uses File System Synchronized Groups
2. Files should auto-appear from the file system
3. If missing: File → Add Files to "ChatushApp"
4. Select the missing folders and check "Create folder references"
```

### Build errors about @available
```
Solution:
1. Check deployment target is iOS 18.0+
2. Project Settings → Targets → ChatushApp → General
3. Minimum Deployments → iOS: 18.0
```

## Expected Build Output

First successful build should show:
```
✅ Fetching https://github.com/hmlongco/Factory.git
✅ Cloning Factory
✅ Compiling ChatushSDK (9 sources)
✅ Compiling Factory
✅ Building ChatushApp (18 sources)
✅ Build succeeded
```

## Verification Checklist

After adding Factory and building:

- [ ] No "No such module 'Factory'" errors
- [ ] No "Cannot find type 'Conversation'" errors
- [ ] No "Cannot find 'ChatMessage'" errors
- [ ] Build succeeds (Cmd+B)
- [ ] Can run on simulator (Cmd+R)
- [ ] App launches without crashes
- [ ] Can navigate between tabs
- [ ] Settings page loads

## Quick Test After Build

1. **Launch app** (Cmd+R)
2. **Go to Settings tab** (tap gear icon)
3. **Select "Mock" provider**
4. **Tap "Save Configuration"**
5. **Go to Chat tab** (tap message icon)
6. **Type "Hello"** and send
7. **See response** - should echo your message with a random response

If all above works: ✅ **Setup Complete!**

## Common Xcode Shortcuts

- `Cmd+B` - Build
- `Cmd+R` - Run
- `Cmd+.` - Stop
- `Cmd+Shift+K` - Clean Build Folder
- `Cmd+0` - Toggle Navigator
- `Cmd+Shift+Y` - Toggle Console

## Next Steps After Successful Build

1. Read `README.md` for feature overview
2. Test with Mock provider (no API key needed)
3. Get OpenAI API key for production testing
4. Explore all four tabs of the app
5. Try streaming responses
6. Test conversation history
7. Play with different settings

---

**Remember**: The project is fully implemented. You only need to add the Factory package dependency in Xcode, then build and run!
