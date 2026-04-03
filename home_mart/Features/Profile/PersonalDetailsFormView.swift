//
//  PersonalDetailsFormView.swift
//  home_mart
//

import PhotosUI
import SwiftUI

/// Personal details + profile photo (Me → avatar + pencil). Follows **system** Light/Dark (including automatic).
struct PersonalDetailsFormView: View {
    @Bindable private var auth = AuthStore.shared
    @Bindable private var profileAvatar = ProfileAvatarStore.shared
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var nameText = ""
    @State private var emailText = ""
    @State private var phoneText = ""
    @State private var addressText = ""
    @State private var regionText = "Singapore (S$)"
    @State private var isLoadingUser = true
    @State private var showSaveNotice = false

    private var mintSave: Color { Color(red: 0.52, green: 0.88, blue: 0.78) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                profilePhotoSection
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Personal details")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Update your name, email, phone and address")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if isLoadingUser {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    profileField(title: "Name", text: $nameText, placeholder: "Name")
                    profileField(title: "Email address", text: $emailText, placeholder: "Email address", contentType: .email)
                    profileField(title: "Phone number", text: $phoneText, placeholder: "Phone number", contentType: .phone)
                    profileField(title: "Address", text: $addressText, placeholder: "Address")
                    profileField(title: "Region (listing currency)", text: $regionText, placeholder: "Region")

                    Button {
                        showSaveNotice = true
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(mintSave, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.hidden)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await loadUser()
        }
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let jpeg = ProfileAvatarStore.compressImageData(data) {
                    await MainActor.run {
                        profileAvatar.setPhotoJPEGData(jpeg)
                    }
                }
                await MainActor.run { photoPickerItem = nil }
            }
        }
        .alert("Profile", isPresented: $showSaveNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Saving to the server is not wired yet. Your edits stay on this screen until a profile update API is added.")
        }
    }

    @MainActor
    private var profilePhotoSection: some View {
        let avatarImage = profileAvatar.uiImage
        return VStack(spacing: 14) {
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let img = avatarImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.tertiary)
                                .padding(18)
                        }
                    }
                    .frame(width: 104, height: 104)
                    .clipShape(Circle())
                    .background(
                        Circle()
                            .fill(Color(.secondarySystemFill))
                    )

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 30))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color(red: 0.23, green: 0.51, blue: 0.96))
                        .background(
                            Circle()
                                .fill(Color(.systemGroupedBackground))
                                .frame(width: 28, height: 28)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Choose profile photo")

            if avatarImage != nil {
                Button("Remove profile photo", role: .destructive) {
                    profileAvatar.setPhotoJPEGData(nil)
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private enum FieldKind {
        case plain
        case email
        case phone
    }

    private func profileField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        contentType: FieldKind = .plain
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .font(.body)
                .foregroundStyle(.primary)
                .modifier(FieldInputModifiers(kind: contentType))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                )
        }
    }

    private struct FieldInputModifiers: ViewModifier {
        let kind: FieldKind

        func body(content: Content) -> some View {
            switch kind {
            case .plain:
                content
            case .email:
                content
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            case .phone:
                content
                    .keyboardType(.phonePad)
            }
        }
    }

    @MainActor
    private func loadUser() async {
        isLoadingUser = true
        defer { isLoadingUser = false }
        guard let u = await auth.fetchCurrentUser() else { return }
        if let n = u.name, !n.isEmpty { nameText = n }
        if let e = u.email, !e.isEmpty { emailText = e }
        if let p = u.phone, !p.isEmpty { phoneText = p }
        if let a = u.address, !a.isEmpty { addressText = a }
        if let r = u.region, !r.isEmpty { regionText = r }
    }
}

#Preview("Light") {
    NavigationStack {
        PersonalDetailsFormView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        PersonalDetailsFormView()
    }
    .preferredColorScheme(.dark)
}
