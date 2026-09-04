//
//  QuranSettingsManager.swift
//  Deen+
//

import Foundation
import Combine


final class QuranSettingsManager: ObservableObject {

    static let shared = QuranSettingsManager()


    private init() {

        load()

    }



    private let arabicSizeKey = "quran_arabic_size"
    private let translationKey = "quran_show_translation"



    @Published var arabicSize: Double = 40 {

        didSet {

            UserDefaults.standard.set(
                arabicSize,
                forKey: arabicSizeKey
            )

        }

    }




    @Published var showTranslation: Bool = true {

        didSet {

            UserDefaults.standard.set(
                showTranslation,
                forKey: translationKey
            )

        }

    }




    private func load() {


        let savedSize =
        UserDefaults.standard.double(
            forKey: arabicSizeKey
        )



        if savedSize != 0 {

            arabicSize = savedSize

        }




        if UserDefaults.standard.object(
            forKey: translationKey
        ) != nil {


            showTranslation =
            UserDefaults.standard.bool(
                forKey: translationKey
            )


        }


    }


}
