// Views/Auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

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
                    Task { await continueAsGuest() }
                }
                .foregroundColor(.secondary)
                .disabled(isLoading)
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
        let dataSource = AppConfig.dataSource  // 토글 반영 위해 task 시점에 조회
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

    /// Guest 자동 가입+로그인.
    /// REST 백엔드: register → login 사이클로 JWT 발급. 자격증명은 AuthSession 에 영속.
    /// Legacy 백엔드: 단순 게스트 ID 만 발급하고 dismiss.
    private func continueAsGuest() async {
        isLoading = true
        defer { isLoading = false }

        let guestID = AppState.shared.guestUserID
        AppState.shared.userID = guestID

        if AppConfig.backend == .rest {
            // 임의 비밀번호 생성 → MD5 → register → login.
            let rawPW = UUID().uuidString
            let md5PW = APIClient.md5(rawPW)
            let ds = AppConfig.dataSource
            _ = try? await ds.register(email: guestID, passwordMD5: md5PW)
            let ok = (try? await ds.login(email: guestID, passwordMD5: md5PW)) ?? false
            if !ok {
                errorMessage = "Guest session setup failed."
                return
            }
        }
        dismiss()
    }
}

#if DEBUG
#Preview("Login") { LoginView() }
#endif
