//
//  AyahPositionPrefrenceKey.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/29/26.
//

import SwiftUI

struct AyahPositionPreferenceKey: PreferenceKey {

    static var defaultValue: [Int: CGFloat] = [:]


    static func reduce(
        value: inout [Int: CGFloat],
        nextValue: () -> [Int: CGFloat]
    ) {

        value.merge(
            nextValue(),
            uniquingKeysWith: { $1 }
        )
    }
}
