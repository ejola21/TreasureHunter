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

        // password 는 평문 전송 — 서버가 해싱.
        let dataSource = AppConfig.dataSource
        let registered = (try? await dataSource.register(email: email, password: password)) ?? false
        guard registered else {
            errorMessage = "Registration failed (이미 가입된 계정이거나 서버 오류)."
            return
        }
        // 자동 로그인 — REST 백엔드면 토큰 발급. Legacy 면 SUCCESS 여부만 확인.
        let loggedIn = (try? await dataSource.login(email: email, password: password)) ?? false
        if loggedIn {
            AppState.shared.userID = email
            dismiss()
        } else {
            errorMessage = "Auto-login failed. 직접 로그인해 주세요."
        }
    }
}

#if DEBUG
#Preview("Register") { RegisterView() }
#endif
