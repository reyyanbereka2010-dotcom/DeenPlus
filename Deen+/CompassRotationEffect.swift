//
//  CompassRotationEffect.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/22/26.
//

import SwiftUI

struct CompassRotationEffect: GeometryEffect {

    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {

        let radians = CGFloat(angle * .pi / 180)

        let transform =
            CGAffineTransform(translationX: size.width / 2,
                              y: size.height / 2)
                .rotated(by: radians)
                .translatedBy(x: -size.width / 2,
                              y: -size.height / 2)

        return ProjectionTransform(transform)
    }
}
