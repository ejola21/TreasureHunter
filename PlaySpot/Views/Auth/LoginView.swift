// Views/Auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    private let dataSource: MissionDataSource = AppConfig.dataSource

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("Auth/loginbg_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 100)
                    .padding(.top, 20)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("Login") {
                    Task { await login() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button("Create Account") {
                    showRegister = true
                }
                .foregroundColor(.blue)

                Button("Continue as Guest") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
            .loadingHUD(isPresented: isLoading)
        }
    }

    private func login() async {
        isLoading = true
        defer { isLoading = false }

        let md5Password = APIClient.md5(password)
        do {
            let success = try await dataSource.login(email: email, passwordMD5: md5Password)
            if success {
                AppState.shared.userID = email
                dismiss()
            } else {
                errorMessage = "Login failed. Please check your credentials."
            }
        } catch {
            errorMessage = "Connection error. Please try again."
        }
    }
}

#if DEBUG
#Preview("Login") { LoginView() }
#endif
