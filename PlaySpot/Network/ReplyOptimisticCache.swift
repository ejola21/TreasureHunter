// Network/ReplyOptimisticCache.swift
// 사용자가 방금 작성한 후기를 서버 GET /replies 응답이 보강될 때까지(api_designer.md R6.1)
// 메모리에 보관 — 닉네임/일시가 즉시 화면에 보이도록 한다.
//
// 라이프타임: 프로세스 메모리. 앱 재실행 시 사라진다 (서버 권위 응답으로 자동 대체).
import Foundation

@MainActor
final class ReplyOptimisticCache {
    static let shared = ReplyOptimisticCache()
    private init() {}

    private var byMission: [String: [MissionReply]] = [:]

    /// 새 후기 1개 추가. 같은 미션 다중 작성 시 누적.
    func append(missionID: String, reply: MissionReply) {
        byMission[missionID, default: []].append(reply)
    }

    /// 서버 응답 리스트에 옵티미스틱 항목을 합쳐 반환.
    /// **캐시 우선 정책**: 같은 텍스트의 서버 엔트리는 캐시(닉네임/별점/일시 포함) 로 교체.
    /// 서버 GET /replies 가 현재 `MReply` 만 반환하므로(api_designer.md R6.1) — 단순 텍스트 dedupe 로
    /// 서버 버전을 우선하면 본인이 방금 남긴 별점이 사라져 보이게 됨.
    func merged(missionID: String, with server: [MissionReply]) -> [MissionReply] {
        let cached = byMission[missionID] ?? []
        guard !cached.isEmpty else { return server }
        var cachedByText: [String: MissionReply] = [:]
        for c in cached { cachedByText[c.text] = c }
        var merged: [MissionReply] = []
        merged.reserveCapacity(server.count + cached.count)
        for srv in server {
            // 캐시에 같은 텍스트 있으면 캐시 엔트리(메타 포함) 사용, 캐시에서 제거 (중복 방지)
            if let hit = cachedByText.removeValue(forKey: srv.text) {
                merged.append(hit)
            } else {
                merged.append(srv)
            }
        }
        // 서버 응답에 아직 없는 캐시 항목(POST 직후 GET race) 은 뒤에 추가
        merged.append(contentsOf: cachedByText.values)
        return merged
    }

    func clear(missionID: String) {
        byMission.removeValue(forKey: missionID)
    }
}
