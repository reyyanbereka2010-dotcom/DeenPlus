//
//  DuaManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/9/26.
//

import Foundation
import Network
import Combine

enum DuaCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All"
    case morningEvening = "Morn/Eve"
    case daily = "Daily"
    case prayer = "Prayer"
    case favorites = "Saved"

    var id: String { rawValue }
}

struct DuaItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let category: DuaCategory
    let title: String
    let arabic: String
    let transliteration: String
    let translation: String
    let reference: String
    let targetCount: Int
}

@MainActor
final class DuaManager: ObservableObject {
    static let shared = DuaManager()

    @Published private(set) var duas: [DuaItem] = []
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var isCellular: Bool = false
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncDate: Date? = nil

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.deenplus.networkMonitor")
    private let cacheFileName = "duas_offline_cache.json"

    init() {
        startNetworkMonitoring()
        loadLocalDuas()

        // If online on launch, perform background sync
        Task {
            if isConnected {
                await syncOnlineDuas()
            }
        }
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: - Network Connectivity Monitoring

    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let cellular = path.isExpensive || path.usesInterfaceType(.cellular)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isConnected = connected
                self.isCellular = cellular
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    // MARK: - Local Offline Storage

    private var cacheFileURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("DeenDuas", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(cacheFileName)
    }

    func loadLocalDuas() {
        // 1. Try to load from offline disk cache first
        if let data = try? Data(contentsOf: cacheFileURL),
           let cached = try? JSONDecoder().decode([DuaItem].self, from: data),
           !cached.isEmpty {
            self.duas = cached
            return
        }

        // 2. Fall back to comprehensive built-in offline repository
        self.duas = defaultBuiltinDuas
        saveDuasToCache(defaultBuiltinDuas)
    }

    private func saveDuasToCache(_ items: [DuaItem]) {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: cacheFileURL, options: .atomic)
        }
    }

    // MARK: - Online Syncing (Wi-Fi or Cellular)

    func syncOnlineDuas() async {
        guard isConnected else { return }
        isSyncing = true
        defer { isSyncing = false }

        // Attempt to fetch from online API endpoint with timeout
        guard let url = URL(string: "https://raw.githubusercontent.com/deenplus-app/resources/main/duas_v1.json") else {
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6.0
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let onlineItems = try JSONDecoder().decode([DuaItem].self, from: data)
                if !onlineItems.isEmpty {
                    // Merge online items with default items, preserving user additions
                    var existingMap = Dictionary(uniqueKeysWithValues: self.duas.map { ($0.id, $0) })
                    for item in onlineItems {
                        existingMap[item.id] = item
                    }
                    let merged = Array(existingMap.values)
                    self.duas = merged
                    saveDuasToCache(merged)
                    self.lastSyncDate = Date()
                }
            }
        } catch {
            // Offline or network error: gracefully keep using local cache without interruption
        }
    }

    // MARK: - Built-in Offline Duas

    private var defaultBuiltinDuas: [DuaItem] {
        [
            // Morning & Evening
            DuaItem(
                id: "morning_remembrance",
                category: .morningEvening,
                title: "Morning Remembrance",
                arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ",
                transliteration: "Asbahna wa-asbahal-mulku lillah, wal-hamdulillahi, la ilaha illallahu wahdahu la shareeka lah",
                translation: "We have reached the morning and the dominion belongs to Allah, all praise is due to Allah, none has the right to be worshipped except Allah alone without partner.",
                reference: "Sahih Muslim",
                targetCount: 1
            ),
            DuaItem(
                id: "seeking_protection",
                category: .morningEvening,
                title: "Seeking Protection",
                arabic: "بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
                transliteration: "Bismillāhilladhī lā yadurru ma'as-mihī shay'un fil-ardi walā fis-samā'i wa huwas-Samī'ul-'Alīm",
                translation: "In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, All-Knowing.",
                reference: "Abu Dawud & At-Tirmidhi (3x)",
                targetCount: 3
            ),
            DuaItem(
                id: "sayyid_al_istighfar",
                category: .morningEvening,
                title: "Sayyid al-Istighfar (Chief of Forgiveness)",
                arabic: "اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ",
                transliteration: "Allahumma Anta Rabbi, la ilaha illa Anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u bidhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa Anta",
                translation: "O Allah, You are my Lord, there is none worthy of worship except You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favors upon me and I confess my sins, so forgive me, for none forgives sins except You.",
                reference: "Sahih al-Bukhari",
                targetCount: 1
            ),
            DuaItem(
                id: "relief_from_anxiety",
                category: .morningEvening,
                title: "Relief from Anxiety & Distress",
                arabic: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ",
                transliteration: "Allahumma inni a'udhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-bukhli wal-jubn, wa dala'id-dayni wa ghalabatir-rijal",
                translation: "O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from stinginess and cowardice, from the burden of debt and from being overpowered by men.",
                reference: "Sahih al-Bukhari",
                targetCount: 1
            ),

            // Daily Life
            DuaItem(
                id: "before_sleeping",
                category: .daily,
                title: "Before Sleeping",
                arabic: "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ",
                transliteration: "Bismika Rabbi wada'tu janbi wa bika arfa'uh, fa in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin",
                translation: "In Your name my Lord, I lie down and in Your name I rise. If You take my soul, have mercy upon it, and if You release it, protect it as You protect Your righteous servants.",
                reference: "Sahih al-Bukhari & Muslim",
                targetCount: 1
            ),
            DuaItem(
                id: "waking_up",
                category: .daily,
                title: "Upon Waking Up",
                arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
                transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushoor",
                translation: "Praise is to Allah Who gave us life after having given us death, and unto Him is the resurrection.",
                reference: "Sahih al-Bukhari",
                targetCount: 1
            ),
            DuaItem(
                id: "leaving_house",
                category: .daily,
                title: "Leaving the House",
                arabic: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ",
                transliteration: "Bismillahi tawakkaltu 'alallahi, la hawla wa la quwwata illa billah",
                translation: "In the name of Allah, I place my trust in Allah. There is no might nor power except with Allah.",
                reference: "Abu Dawud & At-Tirmidhi",
                targetCount: 1
            ),
            DuaItem(
                id: "entering_house",
                category: .daily,
                title: "Entering the House",
                arabic: "بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا",
                transliteration: "Bismillahi walajna, wa bismillahi kharajna, wa 'ala Rabbina tawakkalna",
                translation: "In the name of Allah we enter, and in the name of Allah we leave, and upon our Lord we rely.",
                reference: "Sunan Abu Dawud",
                targetCount: 1
            ),
            DuaItem(
                id: "before_eating",
                category: .daily,
                title: "Before Eating",
                arabic: "بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ",
                transliteration: "Bismillahi wa 'ala barakatillah",
                translation: "In the name of Allah and with the blessings of Allah.",
                reference: "Al-Hakim",
                targetCount: 1
            ),
            DuaItem(
                id: "after_eating",
                category: .daily,
                title: "After Eating",
                arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلاَ قُوَّةٍ",
                transliteration: "Al-hamdu lillahil-ladhi at'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah",
                translation: "Praise belongs to Allah Who has fed me this and provided it for me without any power or might on my part.",
                reference: "Sunan Abu Dawud & At-Tirmidhi",
                targetCount: 1
            ),
            DuaItem(
                id: "traveling_dua",
                category: .daily,
                title: "Dua for Traveling",
                arabic: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنقَلِبُونَ",
                transliteration: "Subhanalladhi sakh-khara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqaliboon",
                translation: "Glory to Him who has subjected this to us, and we could never have that by our effort. And verily, unto our Lord we shall return.",
                reference: "Sahih Muslim",
                targetCount: 1
            ),

            // Prayer & Forgiveness
            DuaItem(
                id: "ayat_al_kursi",
                category: .prayer,
                title: "Ayat al-Kursi (2:255)",
                arabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ",
                transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum, la ta'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-ard...",
                translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep.",
                reference: "Quran (2:255)",
                targetCount: 1
            ),
            DuaItem(
                id: "dua_parents",
                category: .prayer,
                title: "Dua for Parents (17:24)",
                arabic: "رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا",
                transliteration: "Rabbi irhamhuma kama rabbayani sagheera",
                translation: "My Lord, have mercy upon them as they brought me up when I was small.",
                reference: "Quran (17:24)",
                targetCount: 3
            ),
            DuaItem(
                id: "dua_good_in_life_and_next",
                category: .prayer,
                title: "Good in this Life & Next (2:201)",
                arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
                transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
                translation: "Our Lord, give us in this world that which is good and in the Hereafter that which is good, and save us from the torment of the Fire.",
                reference: "Quran (2:201)",
                targetCount: 3
            ),
            DuaItem(
                id: "dua_sujood",
                category: .prayer,
                title: "Supplication in Sujood",
                arabic: "سُبْحَانَ رَبِّيَ الأَعْلَى وَبِحَمْدِهِ",
                transliteration: "Subhana Rabbiyal-A'la wa bihamdih",
                translation: "Glory be to my Lord, the Most High, and praise be to Him.",
                reference: "Sunan Abu Dawud (3x)",
                targetCount: 3
            ),
            DuaItem(
                id: "dua_forgiveness_yunus",
                category: .prayer,
                title: "Dua of Prophet Yunus (21:87)",
                arabic: "لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ",
                transliteration: "La ilaha illa Anta subhanaka inni kuntu minaz-zalimeen",
                translation: "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.",
                reference: "Quran (21:87)",
                targetCount: 3
            )
        ]
    }
}
