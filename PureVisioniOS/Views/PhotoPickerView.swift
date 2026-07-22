import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var photoManager = PhotoLibraryManager()

    @State private var selectedItem: PhotosPickerItem?
    @State private var showSaveAlert = false
    @State private var savedSuccessfully = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let selectedImage = photoManager.selectedImage {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .cornerRadius(12)

                        if let censored = photoManager.censoredImage {
                            Image(uiImage: censored)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        } else {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        }

                        if photoManager.isProcessing {
                            VStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Processing...")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 24) {
                        Button(action: {
                            selectedItem = nil
                            photoManager.selectedImage = nil
                            photoManager.censoredImage = nil
                        }) {
                            Label("Clear", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            processImage()
                        }) {
                            Label("Censor", systemImage: "eye.slash.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(photoManager.isProcessing)

                        Button(action: {
                            if let image = photoManager.censoredImage {
                                photoManager.saveToLibrary(image)
                                savedSuccessfully = true
                                showSaveAlert = true
                            }
                        }) {
                            Label("Save", systemImage: "square.and.arrow.down.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(photoManager.censoredImage == nil)
                    }
                    .padding(.horizontal)

                } else {
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(.blue.opacity(0.6))

                        Text("Select a Photo")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Choose a photo to automatically detect and censor faces and bodies.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Browse Photos", systemImage: "photo.stack")
                                .frame(maxWidth: 280)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Photo Censor")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { _, newItem in
                loadPhoto(from: newItem)
            }
            .alert(savedSuccessfully ? "Saved!" : "Error", isPresented: $showSaveAlert) {
                Button("OK") {}
            } message: {
                Text(savedSuccessfully ? "Censored photo saved to your library." : "Failed to save photo.")
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let data, let uiImage = UIImage(data: data) {
                    photoManager.selectedImage = uiImage
                    photoManager.censoredImage = nil
                }
            }
        }
    }

    private func processImage() {
        guard let image = photoManager.selectedImage else { return }

        photoManager.processImage(
            image,
            target: appState.detectionTarget,
            censorType: appState.censorType,
            intensity: appState.censorIntensity
        ) { _ in }
    }
}
