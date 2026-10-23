//
//  NetworkGraphPinch.swift
//  ReCIT_iOS
//
//  A pinch on the Réseau graph while the fingers are down: how far it has magnified, and where on
//  screen it started — the point `GraphViewport` keeps under the fingers (Q33).
//

import CoreGraphics

struct NetworkGraphPinch: Equatable {
    let magnification: CGFloat
    let anchor: CGPoint
}
