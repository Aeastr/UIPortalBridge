//
//  PortalView.swift
//  UIPortalBridge
//
//  Created by Aether, 2025.
//
//  Copyright © 2025 Aether. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI
import UIKit

// MARK: - UIViewRepresentable Wrapper

/// A SwiftUI wrapper for `UIPortalView`.
///
/// Use this to embed a portal view directly in SwiftUI when you have a `UIView` reference.
///
/// ```swift
/// PortalViewRepresentable(
///     sourceView: myUIView,
///     hidesSourceView: false,
///     matchesAlpha: true
/// )
/// ```
public struct PortalViewRepresentable: UIViewRepresentable {
    let sourceView: UIView
    var hidesSourceView: Bool = false
    var matchesAlpha: Bool = true
    var matchesTransform: Bool = true
    var matchesPosition: Bool = true

    public init(
        sourceView: UIView,
        hidesSourceView: Bool = false,
        matchesAlpha: Bool = true,
        matchesTransform: Bool = true,
        matchesPosition: Bool = true
    ) {
        self.sourceView = sourceView
        self.hidesSourceView = hidesSourceView
        self.matchesAlpha = matchesAlpha
        self.matchesTransform = matchesTransform
        self.matchesPosition = matchesPosition
    }

    public func makeUIView(context: Context) -> UIPortalView {
        let portal = UIPortalView()
        portal.sourceView = sourceView
        portal.hidesSourceView = hidesSourceView
        portal.matchesAlpha = matchesAlpha
        portal.matchesTransform = matchesTransform
        portal.matchesPosition = matchesPosition
        return portal
    }

    public func updateUIView(_ uiView: UIPortalView, context: Context) {
        uiView.sourceView = sourceView
        uiView.hidesSourceView = hidesSourceView
        uiView.matchesAlpha = matchesAlpha
        uiView.matchesTransform = matchesTransform
        uiView.matchesPosition = matchesPosition
    }
}

// MARK: - Source View Container

/// A container that holds a SwiftUI view in a `UIHostingController` and exposes
/// the underlying `UIView` for portaling.
///
/// Use this when you want to portal a SwiftUI view:
///
/// ```swift
/// let container = SourceViewContainer {
///     Text("Hello, World!")
/// }
///
/// // The container.view can now be used as a portal source
/// let portal = UIPortalView()
/// portal.sourceView = container.view
/// ```
@MainActor
public class SourceViewContainer<Content: View> {
    let hostingController: UIHostingController<Content>

    /// The underlying `UIView` that can be used as a portal source.
    public var view: UIView {
        hostingController.view
    }

    public init(@ViewBuilder content: () -> Content) {
        self.hostingController = UIHostingController(rootView: content())
        self.hostingController.view.backgroundColor = .clear
        self.hostingController.sizingOptions = .preferredContentSize
        hostingController.view.setNeedsLayout()
    }

    public init(content: Content) {
        self.hostingController = UIHostingController(rootView: content)
        self.hostingController.view.backgroundColor = .clear
        self.hostingController.sizingOptions = .preferredContentSize
        hostingController.view.setNeedsLayout()
    }

    /// Updates the content of the container.
    public func update(content: Content) {
        hostingController.rootView = content
        hostingController.view.setNeedsLayout()
    }
}

// MARK: - Source View Wrapper

/// A `UIView` subclass that wraps another view with proper intrinsic sizing.
public class SourceViewWrapper: UIView {
    let sourceView: UIView

    public init(sourceView: UIView) {
        self.sourceView = sourceView
        super.init(frame: .zero)

        sourceView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sourceView)
        NSLayoutConstraint.activate([
            sourceView.topAnchor.constraint(equalTo: topAnchor),
            sourceView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sourceView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sourceView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        if sourceView.bounds.size.width > 0 && sourceView.bounds.size.height > 0 {
            return sourceView.bounds.size
        }
        return sourceView.intrinsicContentSize
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

// MARK: - Source View Representable

/// A `UIViewRepresentable` that displays the source view from a `SourceViewContainer`.
public struct SourceViewRepresentable<Content: View>: UIViewRepresentable {
    let container: SourceViewContainer<Content>
    let content: Content

    public init(container: SourceViewContainer<Content>, content: Content) {
        self.container = container
        self.content = content
    }

    public func makeUIView(context: Context) -> SourceViewWrapper {
        SourceViewWrapper(sourceView: container.view)
    }

    public func updateUIView(_ uiView: SourceViewWrapper, context: Context) {
        container.update(content: content)
        uiView.invalidateIntrinsicContentSize()
    }
}

// MARK: - Portal View (SwiftUI)

/// A SwiftUI view that displays a live mirror of a `SourceViewContainer`'s content.
///
/// This is the primary SwiftUI API for creating portals:
///
/// ```swift
/// struct ContentView: View {
///     @State private var container = SourceViewContainer {
///         Text("Original Content")
///     }
///
///     var body: some View {
///         VStack {
///             // Original view
///             SourceViewRepresentable(container: container, content: Text("Original Content"))
///
///             // Portal (live mirror)
///             PortalView(source: container)
///         }
///     }
/// }
/// ```
public struct PortalView<Content: View>: View {
    let source: SourceViewContainer<Content>
    var hidesSource: Bool
    var matchesAlpha: Bool
    var matchesTransform: Bool
    var matchesPosition: Bool

    public init(
        source: SourceViewContainer<Content>,
        hidesSource: Bool = false,
        matchesAlpha: Bool = true,
        matchesTransform: Bool = true,
        matchesPosition: Bool = true
    ) {
        self.source = source
        self.hidesSource = hidesSource
        self.matchesAlpha = matchesAlpha
        self.matchesTransform = matchesTransform
        self.matchesPosition = matchesPosition
    }

    public var body: some View {
        PortalViewRepresentable(
            sourceView: source.view,
            hidesSourceView: hidesSource,
            matchesAlpha: matchesAlpha,
            matchesTransform: matchesTransform,
            matchesPosition: matchesPosition
        )
    }
}
