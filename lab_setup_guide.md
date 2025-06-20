# 🔬 Zoom VDI Plugin Lab Environment Setup Guide

This guide will help you set up a complete testing environment to develop and validate the Zoom VDI plugin before production deployment.

## 🏗️ Lab Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Lab Network (192.168.1.0/24)            │
│                                                             │
│  ┌─────────────────────┐    ┌─────────────────────────────┐ │
│  │   Development Mac   │    │     Windows VM/Cloud PC     │ │
│  │   (192.168.1.100)  │    │     (192.168.1.101)        │ │
│  │                     │    │                             │ │
│  │ ┌─────────────────┐ │    │ ┌─────────────────────────┐ │ │
│  │ │ Plugin Dev Env  │ │    │ │ Zoom Client + VDI       │ │ │
│  │ │ - Xcode         │ │    │ │ - Windows 10/11         │ │ │
│  │ │ - Swift Tools   │ │    │ │ - Zoom VDI Client       │ │ │
│  │ │ - Test Dashboard│ │    │ │ - Test Applications     │ │ │
│  │ └─────────────────┘ │    │ └─────────────────────────┘ │ │
│  └─────────────────────┘    └─────────────────────────────┘ │
│            │                              │                 │
│            └──────────── Port 9001 ───────┘                 │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

### Hardware Requirements

**Mac (Development Machine)**
- Mac with Intel or Apple Silicon
- 8GB RAM minimum (16GB recommended)
- 50GB free disk space
- Built-in camera and microphone
- Ethernet or strong Wi-Fi connection

**Windows Environment (Choose one)**
- Option A: Local Windows VM (VMware Fusion/Parallels)
- Option B: Azure Virtual Desktop
- Option C: Windows 365 Cloud PC
- Option D: Physical Windows machine

### Software Requirements

**macOS Development Machine**
- macOS 10.15+ (Big Sur 11+ recommended)
- Xcode 12+ with Command Line Tools
- Zoom client (latest version)
- Git
- Network testing tools

**Windows Test Environment**
- Windows 10/11 (latest updates)
- Zoom client with VDI support
- Network utilities
- Test applications for A/V

## 🚀 Step-by-Step Setup

### Phase 1: Mac Development Environment

#### 1.1 Install Development Tools

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify Swift compiler
swift --version

# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install useful development tools
brew install git curl wget htop nmap wireshark
```

#### 1.2 Clone and Setup Plugin Project

```bash
# Create lab directory
mkdir ~/ZoomVDI-Lab
cd ~/ZoomVDI-Lab

# Clone the plugin project (or create from our artifacts)
git clone <your-repo-url> zoom-vdi-plugin
cd zoom-vdi-plugin

# Verify project structure
ls -la
# Should see: setup.sh, Makefile,