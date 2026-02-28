# 🛡️ SRIT: Active Response & Threat Intelligence Lab

[![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=flat&logo=powershell&logoColor=white)](#)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](#)
[![MISP](https://img.shields.io/badge/MISP-Threat_Intelligence-e52020.svg)](#)
[![OpenCTI](https://img.shields.io/badge/OpenCTI-Platform-005fa7.svg)](#)

**SRIT (Security Response IT)** is an engineering thesis project focused on building a fully functional Threat Intelligence and Active Response ecosystem from scratch. 

It bridges the gap between Windows endpoints and central SIEM/TI platforms, featuring custom-built Blue Team agents that not only detect malicious behavior but actively neutralize threats in real-time.

## 🏗️ Architecture Under the Hood

The environment is strictly divided into an isolated execution endpoint and a containerized central intelligence stack.

* **Backend Stack (Docker):** * **OpenCTI & MISP** for threat intelligence gathering and event correlation.
  * **ELK Stack** (Elasticsearch), **Redis**, and **RabbitMQ** for high-performance data processing and messaging.
  * **MailHog** for real-time SMTP SOC alert simulations.
* **Endpoint Agents (Windows/Hyper-V):**
  * Custom **PowerShell** watchdogs and detectors running as background services.
  * Automated mapping of local events to **MITRE ATT&CK** techniques.

## ⚙️ Key Features & Detectors

The project includes several custom-built detection modules simulating a real-world Blue Team toolkit:

1. **C2 Network Monitor & Active Kill (T1571)**
   * Continually polls active TCP connections for suspicious outbound ports (e.g., 4444, 1337).
   * **Active Response:** Immediately terminates (`Stop-Process`) the offending process and pushes an alert to MISP.
2. **File Integrity Monitoring (FIM) - HOSTS (T1565.001)**
   * Monitors the Windows `HOSTS` file for unauthorized modifications (often used by banking trojans).
   * Computes diffs and quarantines the changes while generating an alert.
3. **Encoded Command Detection**
   * Detects and extracts Base64-encoded PowerShell payloads often used in fileless malware attacks.
4. **Malware Drop Watchdog**
   * Monitors specific directories for dropped executables and matches them against threat signatures.

## 🚀 How to Run the Red Team vs Blue Team Simulation

The repository includes a ready-to-use Red Team script to validate the Blue Team defenses.

1. **Start the Defenses (Admin):**
   Execute the detecors from the `SRIT` directory:
   ```powershell
   .\srit_detector_netconn_ports.ps1
   .\srit_detector_hosts_changes.ps1
Start the C2 Listener:
Open a secondary terminal to act as the attacker's server:

PowerShell
.\Fake_C2_Server.ps1
Launch the Attack (Student/User):
Run the simulation script to trigger the entire MITRE ATT&CK chain:

PowerShell
.\simulate_student_attack.ps1
Watch the agents intercept the network connection, kill the process, and automatically dispatch a high-priority email alert to the SOC via MISP.


👨‍💻 Author
Michał Andrychowski BSc in Computer Science / Cybersecurity Enthusiast
