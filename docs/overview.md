# Overview

## Introduction

**XCSP Launcher** is a lightweight yet powerful tool designed to **simplify the installation, configuration, and execution** of constraint solvers compatible with the [XCSP3 format](https://xcsp.org).  
It can be used **from the command line** or **as a Python library**, making it ideal for both experimentation and integration into larger CP workflows.

Use XCSP Launcher to:

- 🧩 Install solvers from config files, GitHub, or GitLab
- ⚙️ Build and manage multiple solver versions
- ⚡ Run solvers on XCSP3 instances
- 📦 Analyze performance and capture results programmatically

---

## 📦 Installation

### 🐧 Linux

#### Install via `.deb` package

Download the latest `.deb` file from the [GitHub Releases](https://github.com/CPToolset/xcsp-launcher/releases) page.

```bash
sudo dpkg -i xcsp-launcher_<version>.deb
```

> You may need to run `sudo apt --fix-broken install` if dependencies are missing.

### 🍏 macOS

Install via [Homebrew](https://brew.sh):

```bash
brew tap CPToolset/homebrew-xcsp-launcher
brew install xcsp
```

> This provides the `xcsp` command directly in your terminal.

---

### 🪟 Windows

Download the latest windows binary from [github releases](https://github.com/CPToolset/XCSP-Launcher/releases/). 

---

## Next Step

After installing, you can install the default solvers with:

```bash
xcsp --bootstrap
```

Then start solving your first XCSP3 instance:

```bash
xcsp solver --name ace --instance example.xml
```