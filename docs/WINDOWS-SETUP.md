# Windows Setup Guide

**AppyDave Tools** - Complete Windows installation and configuration guide

---

## 🎯 Overview

This guide helps Windows users set up Ruby and install appydave-tools. The gem itself is cross-platform, but Ruby and some dependencies require Windows-specific setup.

**What you'll install:**
- Ruby (programming language)
- Git (version control)
- AppyDave Tools gem
- AWS CLI (for DAM S3 operations - optional)

**Time required:** 20-30 minutes

---

## ✅ Prerequisites

- **Windows 10 or Windows 11**
- **Administrator access** (for installations)
- **Internet connection**

---

## 📦 Installation Steps

### Step 1: Install Ruby (RubyInstaller)

**Why RubyInstaller?** It's the official Windows distribution with native extensions support.

**Installation:**

1. **Download RubyInstaller:**
   - Visit: https://rubyinstaller.org/downloads/
   - Download **Ruby+Devkit 3.3.x (x64)** (recommended) or **Ruby+Devkit 3.4.x (x64)** (latest)
   - Choose the version with **(x64)** for 64-bit Windows

2. **Run the installer:**
   - Double-click the downloaded `.exe` file
   - ✅ Check **"Add Ruby executables to your PATH"**
   - ✅ Check **"Associate .rb and .rbw files with this Ruby installation"**
   - Click **Install**

3. **Install MSYS2 toolchain:**
   - At the end of installation, a command prompt will appear
   - When asked "Which components shall be installed?", press **ENTER** (installs all)
   - This installs development tools needed for native gems
   - Wait for installation to complete (can take 5-10 minutes)

4. **Verify installation:**
   ```powershell
   ruby --version
   # Should show: ruby 3.3.x or 3.4.x

   gem --version
   # Should show: 3.x.x

   bundler --version
   # Should show: 2.x.x
   ```

**Troubleshooting:**
- If `ruby` command not found: Close and reopen PowerShell/Command Prompt
- If still not found: Add `C:\Ruby33-x64\bin` to PATH manually (adjust version number)

---

### Step 2: Install Git for Windows (Optional but Recommended)

**Why Git?** Required for development work and cloning repositories.

**Installation:**

1. **Download Git:**
   - Visit: https://git-scm.com/download/win
   - Download the 64-bit installer

2. **Run the installer:**
   - Use default settings for most options
   - **Important setting:** Choose **"Use Git from Git Bash and also from Windows Command Prompt"**
   - **Line ending setting:** Choose **"Checkout Windows-style, commit Unix-style"**

3. **Verify installation:**
   ```powershell
   git --version
   # Should show: git version 2.x.x
   ```

---

### Step 3: Install AppyDave Tools Gem

**Now you're ready to install the gem!**

```powershell
gem install appydave-tools
```

**Verify installation:**
```powershell
# Check gem is installed
gem list appydave-tools

# Test a command
gpt_context --help
dam help
```

**Expected output:** Help text should display without errors.

---

### Step 4: Configuration Setup

**Create configuration files:**

```powershell
# Create config directory (PowerShell)
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\appydave"

# Initialize configuration
ad_config -c
```

**This creates:**
- `%USERPROFILE%\.config\appydave\settings.json`
- `%USERPROFILE%\.config\appydave\channels.json`
- `%USERPROFILE%\.config\appydave\youtube_automation.json`

**Edit configuration files:**

```powershell
# Option 1: Edit in VS Code (if installed)
code "$env:USERPROFILE\.config\appydave"

# Option 2: Edit in Notepad
notepad "$env:USERPROFILE\.config\appydave\settings.json"
```

**Example Windows paths in settings.json:**
```json
{
  "video-projects-root": "C:\\Users\\YourName\\Videos\\video-projects",
  "ecamm-recording-folder": "C:\\Users\\YourName\\Videos\\Recordings",
  "download-folder": "C:\\Users\\YourName\\Downloads",
  "download-image-folder": "C:\\Users\\YourName\\Downloads\\images"
}
```

**⚠️ Important for Windows:**
- Use **double backslashes** (`\\`) or **forward slashes** (`/`) in JSON paths
- Don't use single backslashes (they're escape characters in JSON)

**Valid path formats:**
```json
"video-projects-root": "C:\\Users\\YourName\\Videos"    // ✅ Double backslash
"video-projects-root": "C:/Users/YourName/Videos"      // ✅ Forward slash
"video-projects-root": "C:\Users\YourName\Videos"      // ❌ Single backslash (breaks JSON)
```

---

### Step 5: AWS CLI (Optional - For DAM S3 Commands)

**Only needed if using:** `dam s3-up`, `dam s3-down`, `dam s3-status`, `dam s3-cleanup-*`

**Installation:**

1. **Download AWS CLI:**
   - Visit: https://aws.amazon.com/cli/
   - Download **AWS CLI MSI installer for Windows (64-bit)**

2. **Run the installer:**
   - Use default settings
   - Click through the installer

3. **Verify installation:**
   ```powershell
   aws --version
   # Should show: aws-cli/2.x.x
   ```

4. **Configure AWS credentials:**
   ```powershell
   aws configure
   ```

   You'll be prompted for:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., `us-east-1`)
   - Default output format (press ENTER for default)

**Alternative:** Use `.env` file in project directory (see Configuration guide).

---

## 🧪 Testing Your Setup

### Test 1: GPT Context (No AWS required)
```powershell
# Create a test project
mkdir C:\temp\test-project
cd C:\temp\test-project

# Create some files
echo "print('Hello')" > test.rb
echo "puts 'World'" > main.rb

# Test gpt_context
gpt_context -i "**/*.rb" -f tree
```

**Expected:** Should show a tree view of Ruby files.

### Test 2: Configuration Tool
```powershell
# List all configurations
ad_config -l

# View settings
ad_config -p settings
```

**Expected:** Should display your configuration without errors.

### Test 3: DAM Commands (Requires AWS setup)
```powershell
# List available brands
dam list

# Show help
dam help
```

**Expected:** Should show brand list or helpful error message.

---

## 🔧 Common Windows Issues

### Issue 1: "ruby: command not found"

**Cause:** Ruby not in PATH

**Solution:**
1. Close and reopen PowerShell/Command Prompt
2. If still not working, manually add to PATH:
   - Open **System Properties** → **Environment Variables**
   - Edit **Path** under **User variables**
   - Add: `C:\Ruby33-x64\bin` (adjust version number)
   - Click OK and restart terminal

### Issue 2: "Permission denied" when installing gem

**Cause:** Trying to install to system Ruby

**Solution 1 (Recommended):** Run as administrator:
```powershell
# Right-click PowerShell → "Run as Administrator"
gem install appydave-tools
```

**Solution 2:** Use `--user-install`:
```powershell
gem install --user-install appydave-tools
```

### Issue 3: Native extension build fails

**Symptoms:**
```
ERROR: Failed to build gem native extension
```

**Cause:** MSYS2 DevKit not installed

**Solution:**
1. Open Command Prompt
2. Run: `ridk install`
3. Choose option **3** (MSYS2 and MINGW development toolchain)
4. Try gem install again

### Issue 4: "cannot load such file -- bundler/setup"

**Cause:** Bundler not installed or wrong version

**Solution:**
```powershell
gem install bundler
```

### Issue 5: Git Bash vs PowerShell vs Command Prompt

**Which terminal to use?**

| Terminal | Pros | Cons | Recommended For |
|----------|------|------|-----------------|
| **PowerShell** | Native Windows, modern syntax | Different commands than Unix | General gem usage |
| **Git Bash** | Unix-like commands, familiar to Mac users | Not native Windows | Development work |
| **Command Prompt** | Simple, always available | Limited features | Quick commands |

**Recommendation:** Use **PowerShell** for gem commands, **Git Bash** for development.

### Issue 6: JSON path format errors

**Symptom:**
```
Error parsing settings.json: unexpected token
```

**Cause:** Single backslashes in JSON paths

**Solution:** Use double backslashes or forward slashes:
```json
// ❌ WRONG
"video-projects-root": "C:\Users\Name\Videos"

// ✅ CORRECT
"video-projects-root": "C:\\Users\\Name\\Videos"
"video-projects-root": "C:/Users/Name/Videos"
```

### Issue 7: AWS CLI not found after installation

**Solution:**
1. Close and reopen terminal
2. If still not working, add to PATH:
   - Add: `C:\Program Files\Amazon\AWSCLIV2`

---

## 📝 Windows-Specific Notes

### Path Separators
- Ruby handles both `\` and `/` in paths
- **Recommendation:** Use forward slashes (`/`) everywhere - they work on all platforms
- Example: `"C:/Users/Name/Videos"` instead of `"C:\\Users\\Name\\Videos"`

### Home Directory
- Mac/Linux: `~` or `$HOME` = `/Users/davidcruwys`
- Windows: `~` or `%USERPROFILE%` = `C:\Users\YourName`

### Configuration Locations
| Platform | Location |
|----------|----------|
| Mac/Linux | `~/.config/appydave/` |
| Windows | `C:\Users\YourName\.config\appydave\` or `%USERPROFILE%\.config\appydave\` |

### Line Endings
- Windows uses `CRLF` (`\r\n`)
- Mac/Linux uses `LF` (`\n`)
- Git should handle this automatically (with correct Git config)
- Ruby gems handle both formats

### External Drives
- Mac: `/Volumes/T7/`
- Windows: `E:\` or `F:\` (drive letters vary)

**DAM SSD Configuration Example (Windows):**
```json
"locations": {
  "video_projects": "C:/Users/YourName/Videos/video-projects/v-appydave",
  "ssd_backup": "E:/youtube-PUBLISHED/appydave"
}
```

---

## 🚀 Next Steps

After setup is complete:

1. **Read the main documentation:**
   - [README.md](../README.md) - Overview of all tools
   - [Configuration Guide](./configuration/README.md) - Detailed config setup
   - [DAM Usage Guide](./dam/usage.md) - Video project management

2. **Try basic commands:**
   ```powershell
   # GPT Context
   gpt_context --help

   # Configuration
   ad_config -l

   # DAM (if configured)
   dam list
   ```

3. **For development work:**
   - Clone the repository: `git clone https://github.com/appydave/appydave-tools`
   - Run: `cd appydave-tools`
   - Setup: `bundle install`
   - Tests: `bundle exec rspec`

---

## 💬 Getting Help

**Documentation:**
- [Main README](../README.md)
- [Configuration Guide](./configuration/README.md)
- [DAM Usage](./dam/usage.md)

**Issues:**
- GitHub Issues: https://github.com/appydave/appydave-tools/issues
- Label your issue with `platform: windows`

**Community:**
- YouTube: [@AppyDave](https://youtube.com/@appydave)
- Website: [appydave.com](https://appydave.com)

---

## 📚 Additional Resources

**Ruby on Windows:**
- Official guide: https://rubyinstaller.org/
- Ruby documentation: https://ruby-doc.org/

**Windows Terminal:**
- Modern terminal app: https://aka.ms/terminal
- Supports tabs, themes, and better Unicode support

**AWS CLI:**
- User guide: https://docs.aws.amazon.com/cli/latest/userguide/
- Configuration: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

---

**Last Updated:** 2025-11-10
**Tested On:** Windows 10, Windows 11
**Ruby Versions:** 3.3.x, 3.4.x
