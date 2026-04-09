//
//  SignUpView.swift
//  home_mart
//

import SwiftUI

struct SignUpView: View {
    @Binding var isShowingSignUp: Bool
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSubmitting = false
    @State private var signUpError: String?
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack {
                    authCard
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.never)
        }
    }

    private var authCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Create an account")
                    .font(.system(size: 28, weight: .bold))

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign in") { isShowingSignUp = false }
                        .foregroundStyle(Color(.systemBlue))
                }
                .font(.subheadline)
            }
            .padding(.bottom, 6)

            VStack(spacing: 12) {
                inputField(
                    systemImage: "person",
                    placeholder: "Full Name",
                    text: $name
                )
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

                inputField(
                    systemImage: "envelope",
                    placeholder: "Email Address",
                    text: $email
                )
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                passwordField(
                    placeholder: "Password",
                    text: $password,
                    isVisible: $isPasswordVisible,
                    contentType: .newPassword
                )

                passwordField(
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isVisible: $isConfirmPasswordVisible,
                    contentType: .newPassword
                )
            }

            if let err = signUpError, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }

            Button {
                Task {
                    signUpError = nil
                    isSubmitting = true
                    let ok = await AuthStore.shared.register(
                        name: name,
                        email: email,
                        password: password,
                        passwordConfirmation: confirmPassword
                    )
                    isSubmitting = false
                    if ok {
                        isShowingSignUp = false
                    } else {
                        signUpError = AuthStore.shared.lastError ?? "Could not create account."
                    }
                }
            } label: {
                Text(isSubmitting ? "Creating account…" : "Create account")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(.black), Color(.black).opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
            .padding(.top, 6)

            dividerOr
                .padding(.top, 4)

            Text("Join With Your Favorite Social Media Account")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            socialRow
                .padding(.top, 2)

            termsFooter
                .padding(.top, 10)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.black).opacity(0.06), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.35), lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    private func inputField(systemImage: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            TextField(placeholder, text: text)
                .foregroundStyle(.primary)
                .tint(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 1)
                )
        )
    }

    private func passwordField(
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        contentType: UITextContentType
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                        .textContentType(contentType)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: text)
                        .textContentType(contentType)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .foregroundStyle(.primary)
            .tint(.primary)

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16, weight: .regular))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible.wrappedValue ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 1)
                )
        )
    }

    private var dividerOr: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color(.separator).opacity(0.35))
                .frame(height: 1)
            Text("or")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color(.separator).opacity(0.35))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }

    private var socialRow: some View {
        HStack(spacing: 18) {
            Button { } label: {
                Image("GoogleG")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            socialIconButton(content: { facebookMark })
            socialIconButton(content: {
                Image(systemName: "apple.logo")
                    .foregroundStyle(.primary)
            })
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
    }

    private func socialIconButton(@ViewBuilder content: () -> some View) -> some View {
        Button { } label: {
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .overlay(
                        Circle().strokeBorder(Color(.separator).opacity(0.45), lineWidth: 1)
                    )
                    .frame(width: 44, height: 44)

                content()
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }

    private var facebookMark: some View {
        Text("f")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(Color(.systemBlue))
            .offset(y: -1)
    }

    private var termsFooter: some View {
        VStack(spacing: 2) {
            Text("By signing up, you agree to our")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack(spacing: 4) {
                Button("Terms of Service") { }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color(.systemBlue))
                Text("and")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Privacy Policy") { }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color(.systemBlue))
                Text(".")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
