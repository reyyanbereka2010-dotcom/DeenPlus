//
//  RecentlyReadManager.swift
//  Deen+
//

import Foundation


struct RecentlyRead: Codable {

    let surah: Int
    let surahName: String
    let verse: Int
}



final class RecentlyReadManager {


    static let shared = RecentlyReadManager()


    private init() {}



    private let key = "recently_read_quran"



    func save(
        surah: Int,
        surahName: String,
        verse: Int
    ) {


        let item = RecentlyRead(
            surah: surah,
            surahName: surahName,
            verse: verse
        )


        do {
            let data = try JSONEncoder().encode(item)
            // Save encoded data to UserDefaults
            UserDefaults.standard.set(
                data,
                forKey: key
            )
            
            #if DEBUG
            print(
                "SAVED CONTINUE READING:",
                "Surah:",
                surah,
                "Ayah:",
                verse
            )
            #endif
        } catch {
            // Log encoding error in debug builds
            #if DEBUG
            print("Failed to encode RecentlyRead item:", error)
            #endif
        }
    }




    func load() -> RecentlyRead? {


        guard let data =
                UserDefaults.standard.data(
                    forKey: key
                )
        else {

            return nil
        }

        do {
            // Attempt to decode data
            return try JSONDecoder()
                .decode(
                    RecentlyRead.self,
                    from: data
                )
        } catch {
            // Log decoding error in debug builds
            #if DEBUG
            print("Failed to decode RecentlyRead item:", error)
            #endif
            return nil
        }
    }



    func clear() {

        UserDefaults.standard.removeObject(
            forKey: key
        )
    }
}

