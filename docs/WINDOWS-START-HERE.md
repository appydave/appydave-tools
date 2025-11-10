# 🪟 Windows User - Start Here!

**Welcome Jan!** This guide gets you set up with AppyDave Tools on Windows.

---

## 📖 Three Documents You Need

### 1. [WINDOWS-SETUP.md](./WINDOWS-SETUP.md) 👈 **START HERE**
**Complete installation guide for Windows**

What it covers:
- ✅ Installing Ruby (easy with RubyInstaller!)
- ✅ Installing AppyDave Tools gem
- ✅ Configuration setup
- ✅ AWS CLI installation (optional - only for S3 features)
- ✅ Troubleshooting common Windows issues

**Time:** 20-30 minutes

---

### 2. [dam/windows-testing-guide.md](./dam/windows-testing-guide.md)
**Testing guide for DAM commands on Windows**

What it covers:
- ✅ 30+ Windows-specific test scenarios
- ✅ Path format testing (C:/ vs C:\\)
- ✅ All DAM commands tested
- ✅ Terminal testing (PowerShell, Command Prompt, Git Bash)
- ✅ Performance benchmarks

**Time:** 2-3 hours for complete testing

---

### 3. [WINDOWS-COMPATIBILITY-REPORT.md](./WINDOWS-COMPATIBILITY-REPORT.md)
**Technical details and bug fixes (optional reading)**

What it covers:
- ✅ Code audit findings (95% Windows compatible!)
- ✅ Critical SSL bug - **FIXED!** ✅
- ✅ Platform compatibility analysis
- ✅ Known Windows limitations

**Time:** 10 minutes to skim

---

## 🚀 Quick Start (TL;DR)

### Step 1: Install Ruby (10 minutes)
1. Download RubyInstaller: https://rubyinstaller.org/downloads/
2. Choose **Ruby+Devkit 3.3.x (x64)** or **3.4.x (x64)**
3. Run installer:
   - ✅ Check "Add Ruby executables to your PATH"
   - ✅ Install MSYS2 DevKit when prompted
4. Verify: Open PowerShell and run:
   ```powershell
   ruby --version
   # Should show: ruby 3.3.x or 3.4.x
   ```

### Step 2: Install AppyDave Tools (1 minute)
```powershell
gem install appydave-tools
```

### Step 3: Configure (5 minutes)
```powershell
# Create config directory
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\appydave"

# Initialize configuration
ad_config -c

# Edit settings (use Notepad or VS Code)
notepad "$env:USERPROFILE\.config\appydave\settings.json"
```

**Important:** Use **forward slashes** in JSON paths!

**Example config:**
```json
{
  "video-projects-root": "C:/Users/Jan/Videos/video-projects"
}
```

❌ **WRONG:** `"C:\Users\Jan\Videos"` (breaks JSON)
✅ **CORRECT:** `"C:/Users/Jan/Videos"` or `"C:\\Users\\Jan\\Videos"`

### Step 4: Test Basic Commands (2 minutes)
```powershell
# Test configuration
ad_config -l

# Test GPT Context (no AWS required)
gpt_context --help

# Test DAM
dam help
dam list
```

### Step 5: AWS Setup (Optional - Only for S3 Features)
**Skip this if you're not using S3 operations (dam s3-up, dam s3-down, etc.)**

1. Download AWS CLI: https://aws.amazon.com/cli/
2. Install (use default settings)
3. Configure:
   ```powershell
   aws configure
   ```
   Enter your AWS credentials when prompted

---

## ✅ What Works on Windows

**All core features work identically to Mac/Linux:**
- ✅ GPT Context gathering
- ✅ YouTube Manager
- ✅ Subtitle Processor
- ✅ Configuration management
- ✅ DAM commands (list, S3 operations, archive, manifest, sync-ssd)

**The only differences:**
- Use drive letters (C:, E:) instead of /Users/ or /Volumes/
- Use PowerShell instead of Terminal
- Install Ruby via RubyInstaller instead of rbenv/RVM

---

## 🆘 Common Issues

### "ruby: command not found"
**Solution:** Close and reopen PowerShell. If still broken, add Ruby to PATH:
- System Properties → Environment Variables → Path → Add: `C:\Ruby33-x64\bin`

### "Permission denied" when installing gem
**Solution:** Run PowerShell as Administrator:
- Right-click PowerShell → "Run as Administrator"
- Then: `gem install appydave-tools`

### JSON parsing errors
**Cause:** Single backslashes in paths
**Solution:** Use forward slashes: `"C:/path"` or double backslashes: `"C:\\path"`

### AWS S3 operations fail
**Cause:** AWS CLI not configured
**Solution:** Run `aws configure` and enter credentials

**See [WINDOWS-SETUP.md](./WINDOWS-SETUP.md#common-windows-issues) for complete troubleshooting guide**

---

## 📝 For Testing (After Setup Complete)

**Follow:** [dam/windows-testing-guide.md](./dam/windows-testing-guide.md)

**Test scenarios:**
1. ✅ Basic commands (10 tests)
2. ✅ Path handling (5 tests)
3. ✅ DAM commands (8 tests)
4. ✅ Error handling (6 tests)
5. ✅ Performance (2 tests)

**Report issues:** Include Windows version, Ruby version, and full error message

---

## 💬 Questions?

**Documentation:**
- [WINDOWS-SETUP.md](./WINDOWS-SETUP.md) - Complete setup guide
- [dam/windows-testing-guide.md](./dam/windows-testing-guide.md) - Testing scenarios
- [Main README](../README.md) - Tool overview

**GitHub Issues:**
- https://github.com/appydave/appydave-tools/issues
- Label with `platform: windows`

---

## 🎯 Success Criteria

You'll know setup is complete when:
- ✅ `ruby --version` shows Ruby 3.3+ or 3.4+
- ✅ `gem list appydave-tools` shows the gem is installed
- ✅ `dam help` shows help text without errors
- ✅ `gpt_context --help` works
- ✅ `ad_config -l` lists your configuration

**Then you're ready to test!** 🚀

---

**Last Updated:** 2025-11-10
**Ruby Versions Tested:** 3.3.x, 3.4.x
**Windows Versions:** Windows 10, Windows 11
**Status:** ✅ Ready for testing (SSL bug fixed!)
