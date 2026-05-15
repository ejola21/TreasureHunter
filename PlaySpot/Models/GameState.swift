// Models/GameState.swift
import Foundation

enum MissionStatus: Int, Codable {
    case designing = 0      // DESIGNING
    case tested = 1         // TESTED
    case serverUpload = 2   // SERVER_UPLOAD
    case firstDesign = 3    // FIRST_DESIGN
}

enum PlayMode: Int, Codable {
    case real = 0           // REAL_MODE
    case virtual = 1        // VIRTUAL_MODE
}

enum MandatoryFlag: Int, Codable {
    case optional = 0       // MANDATORY_N
    case mandatory = 1      // MANDATORY_Y
}
