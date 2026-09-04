//
//  SurahManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/22/26.
//

import Foundation
import Combine


@MainActor
class SurahManager: ObservableObject {

    @Published var surahs: [Surah] = []

    @Published var isLoading = false


    func fetchSurahs() async {

        if !surahs.isEmpty {
            return
        }


        isLoading = true


        guard let url = URL(
            string: "https://api.quran.com/api/v4/chapters"
        ) else {

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

            print("Surah loading error:")
            print(error)

        }


        isLoading = false

    }

}
