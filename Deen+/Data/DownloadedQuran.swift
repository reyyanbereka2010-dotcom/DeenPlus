//
//  DownloadedQuran.swift
//  Deen+
//

import Foundation

struct DownloadedQuran: Codable, Identifiable {

    let id: Int
    let name: String
    let verses: [QuranVerse]

}
