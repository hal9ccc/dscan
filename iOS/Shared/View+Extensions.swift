//
//  View+Extensions.swift
//  
//
//  Created by Enes Karaosman on 27.11.2020.
//

import SwiftUI

internal extension View {
    
    func embedInAnyView() -> AnyView {
        AnyView(self)
    }
    
}

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension View {

    func conditionalModifier<M1: ViewModifier, M2: ViewModifier>
        (on condition: Bool, trueCase: M1, falseCase: M2) -> some View {
        Group {
            if condition {
                self.modifier(trueCase)
            } else {
                self.modifier(falseCase)
            }
        }
    }

    func conditionalModifier<M: ViewModifier>
        (on condition: Bool, trueCase: M) -> some View {
        Group {
            if condition {
                self.modifier(trueCase)
            }
        }
    }
    
    typealias ContentTransform<Content: View> = (Self) -> Content
    @ViewBuilder func conditionalModifier<TrueContent: View, FalseContent: View>( _ condition: Bool, _ ifTrue: ContentTransform<TrueContent>, _ ifFalse: ContentTransform<FalseContent>) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
}
