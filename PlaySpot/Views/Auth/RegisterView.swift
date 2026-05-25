// Views/Auth/RegisterView.swift
// Phase 7 — Candy 보정. 로직 (register + auto login + nickname patch) 보존.
import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var nickname = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DuoKicker(text: "Sign Up · 회원가입")
                    Text("계정 만들기")
                        .font(.duoDisplay(size: 24))
                        .foregroundColor(.duoEel2)

                    VStack(spacing: 0) {
                        candyField("Email", text: $email,
                                   isSecure: false, keyboard: .emailAddress, autocap: .never, isLast: false)
                        rowDivider
                        candyField("Nickname · 닉네임", text: $nickname,
                                   isSecure: false, autocap: .never, isLast: false)
                        rowDivider
                        candyField("Password", text: $password, isSecure: true, isLast: false)
                        rowDivider
                        candyField("Confirm Password", text: $confirmPassword, isSecure: true, isLast: true)
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

                    Button("Register") { Task { await register() } }
                        .buttonStyle(.primary)
                        .disabled(!isValid || isLoading)
                        .opacity(isValid && !isLoading ? 1.0 : 0.5)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 24)
                }
                .padding(.vertical, 16)
            }
            .background(Color.duoSnow.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.duoMacaw)
                }
            }
            .loadingHUD(isPresented: isLoading)
        }
    }

    private var rowDivider: some View {
        Rectangle().fill(Color.duoSwan).frame(height: 1).padding(.leading, 14)
    }

    @ViewBuilder
    private func candyField(_ label: String,
                            text: Binding<String>,
                            isSecure: Bool = false,
                            keyboard: UIKeyboardType = .default,
                            autocap: TextInputAutocapitalization = .sentences,
                            isLast: Bool) -> some View {
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

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        email.contains("@") &&
        !trimmedNickname.isEmpty
    }

    private func register() async {
        isLoading = true
        defer { isLoading = false }

        let dataSource = AppConfig.dataSource
        let registered = (try? await dataSource.register(email: email, password: password)) ?? false
        guard registered else {
            errorMessage = "Registration failed (이미 가입된 계정이거나 서버 오류)."
            return
        }
        let loggedIn = (try? await dataSource.login(email: email, password: password)) ?? false
        guard loggedIn else {
            errorMessage = "Auto-login failed. 직접 로그인해 주세요."
            return
        }

        AppState.shared.userID = email
        let nick = trimmedNickname
        _ = try? await dataSource.updateUser(userID: email, patch: UserPatchReq(nickname: nick))
        AppState.shared.userNickname = nick
        dismiss()
    }
}

#if DEBUG
#Preview("Register") { RegisterView() }
#endif
