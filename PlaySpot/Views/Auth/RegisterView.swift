// Views/Auth/RegisterView.swift
import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.title.bold())

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("Register") {
                    Task { await register() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid || isLoading)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .loadingHUD(isPresented: isLoading)
        }
    }

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && password == confirmPassword && email.contains("@")
    }

    private func register() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        // Mock: 바로 로그인 성공 처리
        AppState.shared.userID = email
        dismiss()
        #else
        let md5Password = APIClient.md5(password)
        do {
            let client = APIClient.shared
            let response = try await client.request(.register(userID: email, passwordMD5: md5Password))
            if response.trimmingCharacters(in: .whitespacesAndNewlines) == "SUCCESS" {
                AppState.shared.userID = email
                dismiss()
            } else {
                errorMessage = "Registration failed."
            }
        } catch {
            errorMessage = "Connection error."
        }
        #endif
    }
}

#if DEBUG
#Preview("Register") { RegisterView() }
#endif
