//
//  SignUpView.swift
//  home_mart
//

import SwiftUI
import UIKit

struct SignUpView: View {
    @Binding var isShowingSignUp: Bool
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSubmitting = false
    @State private var signUpError: String?

    var body: some View {
        VStack(spacing: 16) {
                HomeMartAuthLogo()
                    .padding(.top, 6)

                Text("Create an account").font(.title2).bold()
                Text("Enter your details below to create your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Full name").font(.subheadline).foregroundStyle(.primary)
                    TextField(
                        "",
                        text: $name,
                        prompt: Text("Your name").foregroundStyle(Color(uiColor: .placeholderText))
                    )
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Full name")
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email").font(.subheadline).foregroundStyle(.primary)
                    TextField("email@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email")
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Password").font(.subheadline)
                        Spacer()
                    }
                    SecureField(
                        "Password",
                        text: $password,
                        prompt: Text("Password").foregroundStyle(Color(uiColor: .placeholderText))
                    )
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .tint(.primary)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confirm password").font(.subheadline)
                        Spacer()
                    }
                    ConfirmPasswordField(text: $confirmPassword, placeholder: "Confirm password")
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                }
                .padding(.horizontal)

                if let err = signUpError, !err.isEmpty {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .disabled(isSubmitting)

                HStack(spacing: 4) {
                    Text("Already have an account?").foregroundStyle(.secondary)
                    Button("Log in") { isShowingSignUp = false }
                }
                .font(.subheadline)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.bottom, 8)
    }
}
