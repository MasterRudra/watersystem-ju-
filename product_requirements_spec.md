# Product Requirements Specification (PRS) - Water System Control App

## 1. Introduction
### 1.1 Purpose
The purpose of this document is to define the functional and non-functional requirements for the Water System Control mobile application. This app is designed to monitor and control water quality parameters (specifically Oxygen levels) and manage water pumps via a Bluetooth connection with an ESP32 microcontroller.

### 1.2 Scope
The application provides a user-friendly interface for:
- Scanning and connecting to Bluetooth Classic devices.
- Visualizing real-time sensor data (Oxygen levels).
- Controlling actuators (Pumps).
- Emergency system shutdown.
- Logging system events.

## 2. System Overview
### 2.1 Technology Stack
- **Framework:** Flutter (Dark Mode UI).
- **State Management:** Provider.
- **Connectivity:** `flutter_bluetooth_serial` (Bluetooth Classic).
- **Visualization:** `fl_chart` for graphs.

### 2.2 System Architecture
- **Mobile App:** Client interface handling UI, user input, and data visualization.
- **Embedded System (ESP32):** Server sending sensor data and executing control commands.
- **Communication Protocol:** Serial over Bluetooth (SPP), ASCII text-based.

## 3. Functional Requirements

### 3.1 Connectivity
- **FR-01 Device Scanning:** The app shall scan for available Bluetooth Classic devices.
- **FR-02 Pairing/Connecting:** The app shall allow users to select a device to establish a serial connection.
- **FR-03 Connection Status:** The app shall visually indicate whether the device is Online or Offline.
- **FR-04 Auto-Disconnect:** Use of "Emergency Stop" or manual disconnect shall safely close the connection.

### 3.2 Real-Time Monitoring
- **FR-05 Live Oxygen Data:** The app shall display the current Oxygen level in mg/L.
- **FR-06 Data Graph:** The app shall plot the last 50 data points of Oxygen levels on a real-time line chart.
    - *Update Rate:* As fast as data is received (real-time).
    - *Data Range:* 0.0 to 15.0 mg/L (typical).
- **FR-07 Data Parsing:** The app shall support the following incoming data formats:
    - JSON: `{"oxygen": 8.5, "pump1": true}`
    - Key-Value: `O:8.5 F:0` or `Oxygen:8.5`
    - Raw Number: `8.5`

### 3.3 System Control
- **FR-08 Pump Control:** The user shall be able to toggle Pump 1 and Pump 2 ON/OFF individually.
    - *Command Sent:* `PUMP1:ON` / `PUMP1:OFF`
- **FR-09 Pump Renaming:** The user shall be able to rename pumps via a long-press dialog (persisted in memory for session).
- **FR-10 Emergency Stop:** A dedicated red button shall send an `EMERGENCY_STOP` command and turn off all UI switches immediately.

### 3.4 Logging & Diagnostics
- **FR-11 Event Log:** The app shall display a scrollable list of recent events (Connections, Disconnections, Motor Status changes).
- **FR-12 Debugging:** The app shall handle simulation mode when disconnected (fluctuating values for UI testing).

## 4. Non-Functional Requirements
- **NFR-01 UI/UX:** The interface must use a modern "Cyber/Dark" aesthetic with neon accents (Cyan `#00D2FF`) and simplified glassmorphism.
- **NFR-02 Responsive:** The layout must adapt to standard mobile screen sizes.
- **NFR-03 Resilience:** The app must not crash on malformed data packets; it should discard them and log the error.

## 5. Interface Specifications (Protocol)
### 5.1 App to ESP32 (Tx)
| Command | Description |
| :--- | :--- |
| `PUMP1:ON` | Turn Pump 1 ON |
| `PUMP1:OFF` | Turn Pump 1 OFF |
| `PUMP2:ON` | Turn Pump 2 ON |
| `PUMP2:OFF` | Turn Pump 2 OFF |
| `EMERGENCY_STOP` | Shutdown all actuators |

### 5.2 ESP32 to App (Rx)
The system accepts space-separated key:value pairs.
**Example:** `O:8.5 F:0`
- `O` / `Oxygen`: Oxygen value (float).
- `F`: Flow rate or other metric (ignored currently but parsed).
- `pump1` / `pump2`: Boolean status updates (if using JSON).
