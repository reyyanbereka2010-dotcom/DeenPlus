//
//  SurahMetadata.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/28/26.
//
//
//  SurahMetadata.swift
//  Deen+
//

import Foundation

struct SurahInfo {
    let englishName: String
    let englishTranslation: String
    let revelationPlace: String // "Meccan" or "Medinan"
    let totalAyahs: Int
}

struct SurahMetadata {
    static let info: [Int: SurahInfo] = [
        1: SurahInfo(englishName: "Al-Fatihah", englishTranslation: "The Opening", revelationPlace: "Meccan", totalAyahs: 7),
        2: SurahInfo(englishName: "Al-Baqarah", englishTranslation: "The Cow", revelationPlace: "Medinan", totalAyahs: 286),
        3: SurahInfo(englishName: "Ali 'Imran", englishTranslation: "Family of Imran", revelationPlace: "Medinan", totalAyahs: 200),
        4: SurahInfo(englishName: "An-Nisa'", englishTranslation: "The Women", revelationPlace: "Medinan", totalAyahs: 176),
        5: SurahInfo(englishName: "Al-Ma'idah", englishTranslation: "The Table Spread", revelationPlace: "Medinan", totalAyahs: 120),
        6: SurahInfo(englishName: "Al-An'am", englishTranslation: "The Cattle", revelationPlace: "Meccan", totalAyahs: 165),
        7: SurahInfo(englishName: "Al-A'raf", englishTranslation: "The Heights", revelationPlace: "Meccan", totalAyahs: 206),
        8: SurahInfo(englishName: "Al-Anfal", englishTranslation: "The Spoils of War", revelationPlace: "Medinan", totalAyahs: 75),
        9: SurahInfo(englishName: "At-Tawbah", englishTranslation: "The Repentance", revelationPlace: "Medinan", totalAyahs: 129),
        10: SurahInfo(englishName: "Yunus", englishTranslation: "Jonah", revelationPlace: "Meccan", totalAyahs: 109),
        11: SurahInfo(englishName: "Hud", englishTranslation: "Hud", revelationPlace: "Meccan", totalAyahs: 123),
        12: SurahInfo(englishName: "Yusuf", englishTranslation: "Joseph", revelationPlace: "Meccan", totalAyahs: 111),
        13: SurahInfo(englishName: "Ar-Ra'd", englishTranslation: "The Thunder", revelationPlace: "Medinan", totalAyahs: 43),
        14: SurahInfo(englishName: "Ibrahim", englishTranslation: "Abraham", revelationPlace: "Meccan", totalAyahs: 52),
        15: SurahInfo(englishName: "Al-Hijr", englishTranslation: "The Rocky Tract", revelationPlace: "Meccan", totalAyahs: 99),
        16: SurahInfo(englishName: "An-Nahl", englishTranslation: "The Bee", revelationPlace: "Meccan", totalAyahs: 128),
        17: SurahInfo(englishName: "Al-Isra", englishTranslation: "The Night Journey", revelationPlace: "Meccan", totalAyahs: 111),
        18: SurahInfo(englishName: "Al-Kahf", englishTranslation: "The Cave", revelationPlace: "Meccan", totalAyahs: 110),
        19: SurahInfo(englishName: "Maryam", englishTranslation: "Mary", revelationPlace: "Meccan", totalAyahs: 98),
        20: SurahInfo(englishName: "Taha", englishTranslation: "Taha", revelationPlace: "Meccan", totalAyahs: 135),
        21: SurahInfo(englishName: "Al-Anbiya", englishTranslation: "The Prophets", revelationPlace: "Meccan", totalAyahs: 112),
        22: SurahInfo(englishName: "Al-Hajj", englishTranslation: "The Pilgrimage", revelationPlace: "Medinan", totalAyahs: 78),
        23: SurahInfo(englishName: "Al-Mu'minun", englishTranslation: "The Believers", revelationPlace: "Meccan", totalAyahs: 118),
        24: SurahInfo(englishName: "An-Nur", englishTranslation: "The Light", revelationPlace: "Medinan", totalAyahs: 64),
        25: SurahInfo(englishName: "Al-Furqan", englishTranslation: "The Criterion", revelationPlace: "Meccan", totalAyahs: 77),
        26: SurahInfo(englishName: "Ash-Shu'ara", englishTranslation: "The Poets", revelationPlace: "Meccan", totalAyahs: 227),
        27: SurahInfo(englishName: "An-Naml", englishTranslation: "The Ant", revelationPlace: "Meccan", totalAyahs: 93),
        28: SurahInfo(englishName: "Al-Qasas", englishTranslation: "The Stories", revelationPlace: "Meccan", totalAyahs: 88),
        29: SurahInfo(englishName: "Al-Ankabut", englishTranslation: "The Spider", revelationPlace: "Meccan", totalAyahs: 69),
        30: SurahInfo(englishName: "Ar-Rum", englishTranslation: "The Romans", revelationPlace: "Meccan", totalAyahs: 60),
        31: SurahInfo(englishName: "Luqman", englishTranslation: "Luqman", revelationPlace: "Meccan", totalAyahs: 34),
        32: SurahInfo(englishName: "As-Sajdah", englishTranslation: "The Prostration", revelationPlace: "Meccan", totalAyahs: 30),
        33: SurahInfo(englishName: "Al-Ahzab", englishTranslation: "The Combined Forces", revelationPlace: "Medinan", totalAyahs: 73),
        34: SurahInfo(englishName: "Saba", englishTranslation: "Sheba", revelationPlace: "Meccan", totalAyahs: 54),
        35: SurahInfo(englishName: "Fatir", englishTranslation: "Originator", revelationPlace: "Meccan", totalAyahs: 45),
        36: SurahInfo(englishName: "Ya-Sin", englishTranslation: "Ya-Sin", revelationPlace: "Meccan", totalAyahs: 83),
        37: SurahInfo(englishName: "As-Saffat", englishTranslation: "Those Ranged in Ranks", revelationPlace: "Meccan", totalAyahs: 182),
        38: SurahInfo(englishName: "Sad", englishTranslation: "The Letter Sad", revelationPlace: "Meccan", totalAyahs: 88),
        39: SurahInfo(englishName: "Az-Zumar", englishTranslation: "The Troops", revelationPlace: "Meccan", totalAyahs: 75),
        40: SurahInfo(englishName: "Ghafir", englishTranslation: "The Forgiver", revelationPlace: "Meccan", totalAyahs: 85),
        41: SurahInfo(englishName: "Fussilat", englishTranslation: "Explained in Detail", revelationPlace: "Meccan", totalAyahs: 54),
        42: SurahInfo(englishName: "Ash-Shuraa", englishTranslation: "The Consultation", revelationPlace: "Meccan", totalAyahs: 53),
        43: SurahInfo(englishName: "Az-Zukhruf", englishTranslation: "The Gold Adornments", revelationPlace: "Meccan", totalAyahs: 89),
        44: SurahInfo(englishName: "Ad-Dukhan", englishTranslation: "The Smoke", revelationPlace: "Meccan", totalAyahs: 59),
        45: SurahInfo(englishName: "Al-Jathiyah", englishTranslation: "The Kneeling", revelationPlace: "Meccan", totalAyahs: 37),
        46: SurahInfo(englishName: "Al-Ahqaf", englishTranslation: "The Curved Sand-hills", revelationPlace: "Meccan", totalAyahs: 35),
        47: SurahInfo(englishName: "Muhammad", englishTranslation: "Muhammad", revelationPlace: "Medinan", totalAyahs: 38),
        48: SurahInfo(englishName: "Al-Fath", englishTranslation: "The Victory", revelationPlace: "Medinan", totalAyahs: 29),
        49: SurahInfo(englishName: "Al-Hujurat", englishTranslation: "The Dwellings", revelationPlace: "Medinan", totalAyahs: 18),
        50: SurahInfo(englishName: "Qaf", englishTranslation: "The Letter Qaf", revelationPlace: "Meccan", totalAyahs: 45),
        51: SurahInfo(englishName: "Adh-Dhariyat", englishTranslation: "The Scattering Winds", revelationPlace: "Meccan", totalAyahs: 60),
        52: SurahInfo(englishName: "At-Tur", englishTranslation: "The Mount", revelationPlace: "Meccan", totalAyahs: 49),
        53: SurahInfo(englishName: "An-Najm", englishTranslation: "The Star", revelationPlace: "Meccan", totalAyahs: 62),
        54: SurahInfo(englishName: "Al-Qamar", englishTranslation: "The Moon", revelationPlace: "Meccan", totalAyahs: 55),
        55: SurahInfo(englishName: "Ar-Rahman", englishTranslation: "The Beneficent", revelationPlace: "Medinan", totalAyahs: 78),
        56: SurahInfo(englishName: "Al-Waqi'ah", englishTranslation: "The Inevitable", revelationPlace: "Meccan", totalAyahs: 96),
        57: SurahInfo(englishName: "Al-Hadid", englishTranslation: "The Iron", revelationPlace: "Medinan", totalAyahs: 29),
        58: SurahInfo(englishName: "Al-Mujadila", englishTranslation: "The Pleading Woman", revelationPlace: "Medinan", totalAyahs: 22),
        59: SurahInfo(englishName: "Al-Hashr", englishTranslation: "The Gathering", revelationPlace: "Medinan", totalAyahs: 24),
        60: SurahInfo(englishName: "Al-Mumtahanah", englishTranslation: "The Examined One", revelationPlace: "Medinan", totalAyahs: 13),
        61: SurahInfo(englishName: "As-Saf", englishTranslation: "The Ranks", revelationPlace: "Medinan", totalAyahs: 14),
        62: SurahInfo(englishName: "Al-Jumu'ah", englishTranslation: "Friday", revelationPlace: "Medinan", totalAyahs: 11),
        63: SurahInfo(englishName: "Al-Munafiqun", englishTranslation: "The Hypocrites", revelationPlace: "Medinan", totalAyahs: 11),
        64: SurahInfo(englishName: "At-Taghabun", englishTranslation: "The Mutual Loss & Gain", revelationPlace: "Medinan", totalAyahs: 18),
        65: SurahInfo(englishName: "At-Talaq", englishTranslation: "The Divorce", revelationPlace: "Medinan", totalAyahs: 12),
        66: SurahInfo(englishName: "At-Tahrim", englishTranslation: "The Prohibition", revelationPlace: "Medinan", totalAyahs: 12),
        67: SurahInfo(englishName: "Al-Mulk", englishTranslation: "The Dominion", revelationPlace: "Meccan", totalAyahs: 30),
        68: SurahInfo(englishName: "Al-Qalam", englishTranslation: "The Pen", revelationPlace: "Meccan", totalAyahs: 52),
        69: SurahInfo(englishName: "Al-Haqqah", englishTranslation: "The Reality", revelationPlace: "Meccan", totalAyahs: 52),
        70: SurahInfo(englishName: "Al-Ma'arij", englishTranslation: "The Ways of Ascent", revelationPlace: "Meccan", totalAyahs: 44),
        71: SurahInfo(englishName: "Nuh", englishTranslation: "Noah", revelationPlace: "Meccan", totalAyahs: 28),
        72: SurahInfo(englishName: "Al-Jinn", englishTranslation: "The Jinn", revelationPlace: "Meccan", totalAyahs: 28),
        73: SurahInfo(englishName: "Al-Muzzammil", englishTranslation: "The Bundled Up", revelationPlace: "Meccan", totalAyahs: 20),
        74: SurahInfo(englishName: "Al-Muddaththir", englishTranslation: "The Cloaked One", revelationPlace: "Meccan", totalAyahs: 56),
        75: SurahInfo(englishName: "Al-Qiyamah", englishTranslation: "The Resurrection", revelationPlace: "Meccan", totalAyahs: 40),
        76: SurahInfo(englishName: "Al-Insan", englishTranslation: "The Man", revelationPlace: "Medinan", totalAyahs: 31),
        77: SurahInfo(englishName: "Al-Mursalat", englishTranslation: "Those Sent Forth", revelationPlace: "Meccan", totalAyahs: 50),
        78: SurahInfo(englishName: "An-Naba", englishTranslation: "The Great News", revelationPlace: "Meccan", totalAyahs: 40),
        79: SurahInfo(englishName: "An-Nazi'at", englishTranslation: "Those Who Pull Out", revelationPlace: "Meccan", totalAyahs: 46),
        80: SurahInfo(englishName: "Abasa", englishTranslation: "He Frowned", revelationPlace: "Meccan", totalAyahs: 42),
        81: SurahInfo(englishName: "At-Takwir", englishTranslation: "The Overthrowing", revelationPlace: "Meccan", totalAyahs: 29),
        82: SurahInfo(englishName: "Al-Infitar", englishTranslation: "The Cleaving", revelationPlace: "Meccan", totalAyahs: 19),
        83: SurahInfo(englishName: "Al-Mutaffifin", englishTranslation: "The Defrauders", revelationPlace: "Meccan", totalAyahs: 36),
        84: SurahInfo(englishName: "Al-Inshiqaq", englishTranslation: "The Splitting Asunder", revelationPlace: "Meccan", totalAyahs: 25),
        85: SurahInfo(englishName: "Al-Buruj", englishTranslation: "The Big Stars", revelationPlace: "Meccan", totalAyahs: 22),
        86: SurahInfo(englishName: "At-Tariq", englishTranslation: "The Nightcomer", revelationPlace: "Meccan", totalAyahs: 17),
        87: SurahInfo(englishName: "Al-A'la", englishTranslation: "The Most High", revelationPlace: "Meccan", totalAyahs: 19),
        88: SurahInfo(englishName: "Al-Ghashiyah", englishTranslation: "The Overwhelming", revelationPlace: "Meccan", totalAyahs: 26),
        89: SurahInfo(englishName: "Al-Fajr", englishTranslation: "The Dawn", revelationPlace: "Meccan", totalAyahs: 30),
        90: SurahInfo(englishName: "Al-Balad", englishTranslation: "The City", revelationPlace: "Meccan", totalAyahs: 20),
        91: SurahInfo(englishName: "Ash-Shams", englishTranslation: "The Sun", revelationPlace: "Meccan", totalAyahs: 15),
        92: SurahInfo(englishName: "Al-Lail", englishTranslation: "The Night", revelationPlace: "Meccan", totalAyahs: 21),
        93: SurahInfo(englishName: "Ad-Duha", englishTranslation: "The Forenoon", revelationPlace: "Meccan", totalAyahs: 11),
        94: SurahInfo(englishName: "Ash-Sharh", englishTranslation: "The Opening Forth", revelationPlace: "Meccan", totalAyahs: 8),
        95: SurahInfo(englishName: "At-Tin", englishTranslation: "The Fig", revelationPlace: "Meccan", totalAyahs: 8),
        96: SurahInfo(englishName: "Al-Alaq", englishTranslation: "The Clot", revelationPlace: "Meccan", totalAyahs: 19),
        97: SurahInfo(englishName: "Al-Qadr", englishTranslation: "The Night of Decree", revelationPlace: "Meccan", totalAyahs: 5),
        98: SurahInfo(englishName: "Al-Bayyinah", englishTranslation: "The Clear Proof", revelationPlace: "Medinan", totalAyahs: 8),
        99: SurahInfo(englishName: "Az-Zalzalah", englishTranslation: "The Earthquake", revelationPlace: "Medinan", totalAyahs: 8),
        100: SurahInfo(englishName: "Al-Adiyat", englishTranslation: "The Racers", revelationPlace: "Meccan", totalAyahs: 11),
        101: SurahInfo(englishName: "Al-Qari'ah", englishTranslation: "The Striking Hour", revelationPlace: "Meccan", totalAyahs: 11),
        102: SurahInfo(englishName: "At-Takathur", englishTranslation: "The Piling Up", revelationPlace: "Meccan", totalAyahs: 8),
        103: SurahInfo(englishName: "Al-Asr", englishTranslation: "The Time", revelationPlace: "Meccan", totalAyahs: 3),
        104: SurahInfo(englishName: "Al-Humazah", englishTranslation: "The Slanderer", revelationPlace: "Meccan", totalAyahs: 9),
        105: SurahInfo(englishName: "Al-Fil", englishTranslation: "The Elephant", revelationPlace: "Meccan", totalAyahs: 5),
        106: SurahInfo(englishName: "Quraysh", englishTranslation: "Quraysh", revelationPlace: "Meccan", totalAyahs: 4),
        107: SurahInfo(englishName: "Al-Ma'un", englishTranslation: "The Small Kindnesses", revelationPlace: "Meccan", totalAyahs: 7),
        108: SurahInfo(englishName: "Al-Kawthar", englishTranslation: "The Abundance", revelationPlace: "Meccan", totalAyahs: 3),
        109: SurahInfo(englishName: "Al-Kafirun", englishTranslation: "The Disbelievers", revelationPlace: "Meccan", totalAyahs: 6),
        110: SurahInfo(englishName: "An-Nasr", englishTranslation: "The Help", revelationPlace: "Medinan", totalAyahs: 3),
        111: SurahInfo(englishName: "Al-Masad", englishTranslation: "The Palm Fiber", revelationPlace: "Meccan", totalAyahs: 5),
        112: SurahInfo(englishName: "Al-Ikhlas", englishTranslation: "The Sincerity", revelationPlace: "Meccan", totalAyahs: 4),
        113: SurahInfo(englishName: "Al-Falaq", englishTranslation: "The Daybreak", revelationPlace: "Meccan", totalAyahs: 5),
        114: SurahInfo(englishName: "An-Nas", englishTranslation: "Mankind", revelationPlace: "Meccan", totalAyahs: 6)
    ]

    static func get(_ surah: Int) -> SurahInfo {
        return info[surah] ?? SurahInfo(englishName: "Surah \(surah)", englishTranslation: "", revelationPlace: "Meccan", totalAyahs: 0)
    }
}
