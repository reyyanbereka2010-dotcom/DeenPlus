//
//  DownloadedQuran.swift
//  Deen+
//

import Foundation

nonisolated struct DownloadedQuran: Codable, Identifiable, Sendable {

    let id: Int
    let name: String
    let verses: [QuranVerse]

}
