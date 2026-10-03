//
//  SurahManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import Foundation
import Combine

@MainActor
class SurahManager: ObservableObject {

    @Published var surahs: [Surah] = []
    @Published var isLoading = false

    func fetchSurahs() async {

        guard surahs.isEmpty else { return }

        isLoading = true

        let urlString = "https://api.quran.com/api/v4/chapters?language=en"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        do {

            let (data, _) = try await URLSession.shared.data(
                from: url
            )

            let response = try JSONDecoder().decode(
                SurahResponse.self,
                from: data
            )

            self.surahs = response.chapters

        } catch {
            #if DEBUG
            print("Surah loading error:", error)
            #endif
        }

        isLoading = false
    }
}
