// Views/Auth/LoginView.swift
// Phase 7 — Candy 보정. 로직 (login/continueAsGuest) 은 보존.
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
            ScrollView {
                VStack(alignment: .center, spacing: 18) {
                    Image("Auth/loginbg_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240, maxHeight: 90)
                        .padding(.top, 20)

                    DuoKicker(text: "Sign In · 로그인")
                    Text("환영합니다!")
                        .font(.duoDisplay(size: 24))
                        .foregroundColor(.duoEel2)

                    VStack(spacing: 0) {
                        candyField(label: "Email", text: $email, isSecure: false,
                                   keyboard: .emailAddress, autocap: .never, isLast: false)
                        Rectangle().fill(Color.duoSwan).frame(height: 1).padding(.leading, 14)
                        candyField(label: "Password", text: $password, isSecure: true,
                                   keyboard: .default, autocap: .never, isLast: true)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
                    .padding(.horizontal, 16)

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.duoBody(size: 12, weight: .semibold))
                        .foregroundColor(.duoCardinalDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.duoCardinalBg))
                    }

                    Button("Login") { Task { await login() } }
                        .buttonStyle(.primary)
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        .opacity((email.isEmpty || password.isEmpty || isLoading) ? 0.5 : 1.0)
                        .padding(.horizontal, 16)

                    HStack(spacing: 6) {
                        Rectangle().fill(Color.duoSwan).frame(height: 1)
                        Text("OR")
                            .font(.duoDisplay(size: 10))
                            .kerning(0.66)
                            .foregroundColor(.duoHare)
                        Rectangle().fill(Color.duoSwan).frame(height: 1)
                    }
                    .padding(.horizontal, 16)

                    Button("Create Account · 회원가입") { showRegister = true }
                        .buttonStyle(.blue)
                        .padding(.horizontal, 16)

                    Button("Continue as Guest · 게스트로 시작") {
                        Task { await continueAsGuest() }
                    }
                    .font(.duoBody(size: 14, weight: .semibold))
                    .foregroundColor(.duoHare)
                    .disabled(isLoading)

                    Spacer(minLength: 24)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .background(Color.duoSnow.ignoresSafeArea())
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
            .loadingHUD(isPresented: isLoading)
        }
    }

    @ViewBuilder
    private func candyField(label: String, text: Binding<String>,
                            isSecure: Bool, keyboard: UIKeyboardType,
                            autocap: TextInputAutocapitalization, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            DuoKicker(text: label)
            Group {
                if isSecure {
                    SecureField(label, text: text)
                } else {
                    TextField(label, text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocap)
                }
            }
            .font(.duoBody(size: 15, weight: .semibold))
            .foregroundColor(.duoEel2)
        }
        .padding(14)
    }

    private func login() async {
        isLoading = true
        defer { isLoading = false }

        let dataSource = AppConfig.dataSource
        do {
            let success = try await dataSource.login(email: email, password: password)
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

    private func continueAsGuest() async {
        isLoading = true
        defer { isLoading = false }

        let guestID = AppState.shared.guestUserID
        AppState.shared.userID = guestID

        if AppConfig.backend == .rest {
            let guestPW = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let ds = AppConfig.dataSource
            _ = try? await ds.register(email: guestID, password: guestPW)
            let ok = (try? await ds.login(email: guestID, password: guestPW)) ?? false
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
