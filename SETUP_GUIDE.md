# 📤 GitHub Setup Guide: Step-by-Step Instructions

## 🎯 Overview

This guide will walk you through uploading your defensive SQL query project to GitHub, from creating the repository to pushing all files.

---

## 📋 Prerequisites

Before starting, ensure you have:
- [ ] GitHub account created ([Sign up here](https://github.com/join))
- [ ] Git installed on your computer
- [ ] Basic command line knowledge

### Check if Git is installed:
```bash
git --version
```

If not installed, download from: https://git-scm.com/downloads

---

## 🚀 Step-by-Step Process

### Step 1: Create a New Repository on GitHub

1. **Go to GitHub** and log in to your account
2. **Click the "+" icon** in the top-right corner
3. **Select "New repository"**

4. **Fill in repository details:**
   - **Repository name:** `defensive-sql-collections-analysis` (or your preferred name)
   - **Description:** "Defensive SQL query using CTEs to prevent record multiplication in collections analytics"
   - **Visibility:** Choose "Public" (recommended for portfolio) or "Private"
   - **Initialize repository:** ⚠️ **DO NOT** check any boxes (we'll add files manually)

5. **Click "Create repository"**

You'll see a page with setup instructions. **Keep this page open** - we'll use it in Step 3.

---

### Step 2: Prepare Your Local Files

#### Option A: If you're on Windows

1. **Open Command Prompt or PowerShell**
2. **Navigate to your desired folder:**
   ```cmd
   cd C:\Users\YourUsername\Documents\Projects
   ```

3. **Create project folder:**
   ```cmd
   mkdir defensive-sql-collections
   cd defensive-sql-collections
   ```

4. **Copy the files** (you'll need to manually copy these files to this folder):
   - `defensive_collections_analysis.sql`
   - `README.md`
   - `TECHNICAL_DOCS.md`
   - `LICENSE`
   - `.gitignore`

#### Option B: If you're on Mac/Linux

1. **Open Terminal**
2. **Navigate to your desired folder:**
   ```bash
   cd ~/Documents/Projects
   ```

3. **Create project folder:**
   ```bash
   mkdir defensive-sql-collections
   cd defensive-sql-collections
   ```

4. **Copy the files** to this folder

---

### Step 3: Initialize Git and Push to GitHub

Now let's connect your local folder to GitHub:

#### 3.1: Initialize Git Repository

```bash
# Initialize git in your project folder
git init

# Check that files are present
ls -la  # Mac/Linux
dir     # Windows
```

You should see all 5 files listed.

#### 3.2: Configure Git (First Time Only)

If this is your first time using Git on this computer:

```bash
# Set your name
git config --global user.name "Your Name"

# Set your email (use your GitHub email)
git config --global user.email "your.email@example.com"
```

#### 3.3: Add Files to Git

```bash
# Add all files to staging area
git add .

# Verify files are staged
git status
```

You should see all 5 files listed in green as "Changes to be committed".

#### 3.4: Create First Commit

```bash
# Commit with descriptive message
git commit -m "Initial commit: Defensive SQL query with CTE architecture"
```

#### 3.5: Connect to GitHub Repository

Replace `YOUR_USERNAME` with your actual GitHub username:

```bash
# Add remote repository
git remote add origin https://github.com/YOUR_USERNAME/defensive-sql-collections-analysis.git

# Verify remote is added
git remote -v
```

#### 3.6: Push to GitHub

```bash
# Push to GitHub (first time)
git branch -M main
git push -u origin main
```

**You'll be prompted for credentials:**
- **Username:** Your GitHub username
- **Password:** Use a **Personal Access Token** (not your GitHub password)

---

### Step 4: Create Personal Access Token (if needed)

If GitHub rejects your password, you need a Personal Access Token:

1. **Go to GitHub Settings**
   - Click your profile picture → Settings
   - Scroll down to "Developer settings" (bottom of sidebar)
   - Click "Personal access tokens" → "Tokens (classic)"

2. **Generate New Token**
   - Click "Generate new token (classic)"
   - Name: "Git CLI Access"
   - Expiration: Choose your preference (90 days recommended)
   - Scopes: Check ✅ **repo** (this gives full repository access)

3. **Copy the token** (you won't see it again!)

4. **Use token as password** when Git asks for credentials

---

### Step 5: Verify Upload

1. **Go to your GitHub repository** in your web browser
2. **Refresh the page**
3. **You should see all 5 files:**
   - ✅ defensive_collections_analysis.sql
   - ✅ README.md
   - ✅ TECHNICAL_DOCS.md
   - ✅ LICENSE
   - ✅ .gitignore (may not be visible in file list, but it's there)

4. **Click on README.md** - GitHub will automatically display it as the repository homepage

---

## 🎨 Enhance Your Repository (Optional)

### Add Topics/Tags

1. Go to your repository on GitHub
2. Click the ⚙️ gear icon next to "About"
3. Add topics: `sql`, `postgresql`, `data-analysis`, `collections`, `cte`, `defensive-programming`
4. Save changes

### Add Repository Description

In the "About" section (⚙️ gear icon):
- **Description:** "Defensive SQL query using CTEs to prevent record multiplication in collections analytics"
- **Website:** (optional) Your portfolio or LinkedIn
- Check ✅ "Releases" and "Packages" if desired

### Pin Repository to Profile

If you want this to appear on your GitHub profile:
1. Go to your GitHub profile
2. Click "Customize your pins"
3. Select this repository

---

## 🔄 Making Updates Later

When you want to add or modify files:

```bash
# Navigate to project folder
cd path/to/defensive-sql-collections

# Make your changes to files...

# Check what changed
git status

# Add changed files
git add .

# Commit changes
git commit -m "Description of what you changed"

# Push to GitHub
git push
```

---

## 🛠️ Common Issues and Solutions

### Issue 1: "Permission denied (publickey)"

**Solution:** Use HTTPS instead of SSH, or set up SSH keys

```bash
# Switch to HTTPS
git remote set-url origin https://github.com/YOUR_USERNAME/your-repo.git
```

### Issue 2: "fatal: remote origin already exists"

**Solution:** Remove and re-add the remote

```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/your-repo.git
```

### Issue 3: "Your branch is behind 'origin/main'"

**Solution:** Pull changes first

```bash
git pull origin main
git push
```

### Issue 4: Files not showing on GitHub

**Solution:** Verify files are committed

```bash
# Check commit history
git log --oneline

# Check remote
git remote -v

# Force push (use carefully)
git push -f origin main
```

---

## 📱 Alternative: GitHub Desktop (GUI Option)

If you prefer a graphical interface:

1. **Download GitHub Desktop:** https://desktop.github.com/
2. **Install and sign in** with your GitHub account
3. **Click "Add" → "Create New Repository"**
4. **Choose folder** with your files
5. **Commit** your files with a message
6. **Click "Publish repository"** to upload to GitHub

---

## ✅ Final Checklist

After uploading, verify:
- [ ] All 5 files are visible on GitHub
- [ ] README.md displays correctly as homepage
- [ ] SQL file has syntax highlighting
- [ ] Repository is set to Public (if intended for portfolio)
- [ ] Repository description and topics are added
- [ ] Your name/email in commits are correct

---

## 🎯 Next Steps for Portfolio Building

1. **Add to LinkedIn:**
   - Go to your LinkedIn profile
   - Add to "Projects" section
   - Link to your GitHub repository

2. **Share in README:**
   - Create a separate "Portfolio" GitHub repository
   - List this project with description and link

3. **Write a Blog Post:**
   - Dev.to or Medium article explaining your defensive approach
   - Link back to this repository

4. **Create Visual Documentation:**
   - Add diagrams (use draw.io or Mermaid)
   - Consider adding a demo video

---

## 📧 Need Help?

- **GitHub Docs:** https://docs.github.com/
- **Git Basics:** https://git-scm.com/book/en/v2/Getting-Started-Git-Basics
- **Stack Overflow:** Search or ask Git/GitHub questions

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-29  
**Prepared for:** Iván A. Jarpa Manríquez
