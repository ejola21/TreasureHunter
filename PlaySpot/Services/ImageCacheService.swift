// Services/ImageCacheService.swift
import UIKit

actor ImageCacheService {
    static let shared = ImageCacheService()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private nonisolated var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("badges")
    }

    init() {
        let dir = cacheDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    /// 기존 ImageManager.loadBadgeImg: — 로컬 캐시 → 서버 다운로드 → empty02 폴백
    func loadBadgeImage(missionID: String) async -> UIImage {
        let key = NSString(string: missionID)

        // 1. 메모리 캐시 확인
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // 2. 디스크 캐시 확인
        let filePath = cacheDirectory.appendingPathComponent("\(missionID).png")
        if let data = try? Data(contentsOf: filePath),
           let image = UIImage(data: data) {
            cache.setObject(image, forKey: key)
            return image
        }

        // 3. 서버에서 다운로드
        let urlString = "\(APIEndpoint.badgeBaseURL)\(missionID).png"
        if let url = URL(string: urlString) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    cache.setObject(image, forKey: key)
                    try? data.write(to: filePath)
                    return image
                }
            } catch {}
        }

        // 4. 폴백 이미지
        return UIImage(named: "empty02") ?? UIImage()
    }

    /// 기존 ImageManager.imageUpload: — multipart/form-data 업로드
    func uploadImage(imageID: String, image: UIImage) async throws {
        guard let imageData = image.pngData(),
              let url = URL(string: "http://nexapp.co.kr/playspot/image_save.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "treasurehunter"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userfile\"; filename=\"\(imageID)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        let _ = try await URLSession.shared.data(for: request)
    }
}
