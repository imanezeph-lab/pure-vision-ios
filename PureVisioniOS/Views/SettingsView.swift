import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Detection") {
                    Picker("Detection Target", selection: $appState.detectionTarget) {
                        ForEach(DetectionTarget.allCases) { target in
                            Text(target.rawValue).tag(target)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Real-time Processing", isOn: $appState.isEnabled)
                }

                Section("Censor Style") {
                    Picker("Censor Type", selection: $appState.censorType) {
                        ForEach(CensorType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Intensity")
                            Spacer()
                            Text(String(format: "%.0f%%", appState.censorIntensity * 100))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $appState.censorIntensity, in: 0.1...2.0, step: 0.1)
                    }
                }

                Section("Display") {
                    Toggle("Show Confidence Scores", isOn: $appState.showConfidence)
                    Toggle("Auto-save Censored Photos", isOn: $appState.saveCensored)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/pureify/pure-vision-ios")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
