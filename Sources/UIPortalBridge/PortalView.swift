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

// MARK: - PortalViewRepresentable

/// A SwiftUI wrapper for `UIPortalView` when you have a direct `UIView` reference.
///
/// ```swift
/// PortalViewRepresentable(
///     sourceView: myUIView,
///     hidesSourceView: false,
///     matchesAlpha: true
/// )
/// ```
public struct PortalViewRepresentable: UIViewRepresentable {
    let sourceView: UIView?
    var hidesSourceView: Bool
    var matchesAlpha: Bool
    var matchesTransform: Bool
    var matchesPosition: Bool
    
    public init(
        sourceView: UIView?,
        hidesSourceView: Bool = false,
        matchesAlpha: Bool = true,
        matchesTransform: Bool = true,
        matchesPosition: Bool = false
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

// MARK: - PortalSource

/// A reference object that captures a UIView for portal mirroring.
///
/// Create this as `@State` and share it between `PortalSourceView` and `PortalMirrorView`:
///
/// ```swift
/// struct ContentView: View {
///     @State private var source = PortalSource()
///
///     var body: some View {
///         VStack {
///             PortalSourceView(source) {
///                 Text("Hello, World!")
///                     .padding()
///                     .background(.blue)
///             }
///
///             PortalMirrorView(source)
///                 .frame(width: 100, height: 50)
///         }
///     }
/// }
/// ```
///
/// - Note: The `PortalSourceView` must appear before `PortalMirrorView` in the
///   view hierarchy for mirroring to work correctly.
@MainActor
public class PortalSource: ObservableObject {
    /// The captured UIView. Set automatically when the source view enters a window.
    public internal(set) var capturedView: UIView? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.isReady = self?.capturedView != nil
            }
        }
    }
    
    /// True when the source is ready to be mirrored
    @Published public internal(set) var isReady: Bool = false
    
    public init() {}
}

// MARK: - PortalSourceView

/// Displays SwiftUI content and captures it for portal mirroring.
///
/// The content is rendered normally and can be mirrored by any `PortalMirrorView`
/// that shares the same `PortalSource`.
///
/// ```swift
/// @State private var source = PortalSource()
///
/// PortalSourceView(source) {
///     MyComplexView()
/// }
/// ```
///
/// - Note: Must appear before `PortalMirrorView` in the view hierarchy.
public struct PortalSourceView<Content: View>: UIViewRepresentable {
    let source: PortalSource
    let content: Content
    
    public init(_ source: PortalSource, @ViewBuilder content: () -> Content) {
        self.source = source
        self.content = content()
    }
    
    public func makeUIView(context: Context) -> PortalSourceUIView<Content> {
        PortalSourceUIView(rootView: content, source: source)
    }
    
    public func updateUIView(_ uiView: PortalSourceUIView<Content>, context: Context) {
        uiView.updateContent(content)
    }
}

/// The UIView that hosts SwiftUI content and registers itself as the portal source.
public class PortalSourceUIView<Content: View>: UIView {
    private var hostingController: UIHostingController<Content>
    private weak var source: PortalSource?
    
    init(rootView: Content, source: PortalSource) {
        self.hostingController = UIHostingController(rootView: rootView)
        self.source = source
        super.init(frame: .zero)
        
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            source?.capturedView = self
        }
    }
    
    func updateContent(_ content: Content) {
        hostingController.rootView = content
    }
    
    public override var intrinsicContentSize: CGSize {
        hostingController.view.intrinsicContentSize
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

// MARK: - PortalMirrorView

/// Displays a live mirror of a `PortalSource`'s captured view.
///
/// The mirror updates in real-time as the source content changes.
///
/// ```swift
/// @State private var source = PortalSource()
///
/// VStack {
///     PortalSourceView(source) {
///         Text("Original")
///     }
///
///     // This mirrors the content above
///     PortalMirrorView(source)
///         .scaleEffect(0.5)
///         .blur(radius: 10)
/// }
/// ```
///
/// - Note: The `PortalSourceView` must appear before this view in the hierarchy.
public struct PortalMirrorView: View {
    @ObservedObject var source: PortalSource
    var hidesSource: Bool
    var matchesAlpha: Bool
    var matchesTransform: Bool
    var matchesPosition: Bool
    
    public init(
        _ source: PortalSource,
        hidesSource: Bool = false,
        matchesAlpha: Bool = true,
        matchesTransform: Bool = true,
        matchesPosition: Bool = false
    ) {
        self._source = ObservedObject(wrappedValue: source)
        self.hidesSource = hidesSource
        self.matchesAlpha = matchesAlpha
        self.matchesTransform = matchesTransform
        self.matchesPosition = matchesPosition
    }
    
    public var body: some View {
        if source.isReady, let captured = source.capturedView {
            PortalViewRepresentable(
                sourceView: captured,
                hidesSourceView: hidesSource,
                matchesAlpha: matchesAlpha,
                matchesTransform: matchesTransform,
                matchesPosition: matchesPosition
            )
        }
    }
}

// MARK: - Previews

#Preview("Basic Portal") {
    struct Example: View {
        @State private var source = PortalSource()
        
        var body: some View {
            VStack(spacing: 40) {
                Text("Source:")
                PortalSourceView(source) {
                    Text("Hello, World!")
                        .font(.title)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text("Mirror:")
                PortalMirrorView(source)
            }
        }
    }
    return Example()
}

#Preview("Multiple Mirrors") {
    struct Example: View {
        @State private var source = PortalSource()
        
        var body: some View {
            VStack(spacing: 20) {
                PortalSourceView(source) {
                    Text("Original")
                        .font(.headline)
                        .padding()
                        .background(.green)
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 20) {
                    PortalMirrorView(source)
                        .frame(width: 100, height: 50)
                    
                    PortalMirrorView(source)
                        .frame(width: 100, height: 50)
                        .scaleEffect(x: -1, y: 1)
                    
                    PortalMirrorView(source)
                        .frame(width: 100, height: 50)
                        .opacity(0.5)
                }
            }
        }
    }
    return Example()
}


#Preview("Literally Mirrors") {
    struct Example: View {
        @State private var sliderValue: Double = 0.5
        @State private var textValue: String = "Hello"
        @State private var toggleValue: Bool = true
        @State private var stepperValue: Int = 5
        @State private var pickerValue: Int = 0

        @State private var sliderSource = PortalSource()
        @State private var textFieldSource = PortalSource()
        @State private var toggleSource = PortalSource()
        @State private var stepperSource = PortalSource()
        @State private var pickerSource = PortalSource()
        @State private var buttonSource = PortalSource()

        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    // Slider
                    MirroredComponent(title: "Slider") {
                        PortalSourceView(sliderSource) {
                            Slider(value: $sliderValue)
                                .frame(width: 200)
                        }
                        .border(.red.opacity(0.4))
                        PortalMirrorView(sliderSource, matchesTransform: false)
                            .border(.purple.opacity(0.4))
                            .scaleEffect(y: -1)
                    }

                    // TextField
                    MirroredComponent(title: "TextField") {
                        PortalSourceView(textFieldSource) {
                            TextField("Type here...", text: $textValue)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        .border(.red.opacity(0.4))
                        PortalMirrorView(textFieldSource, matchesTransform: false)
                            .border(.purple.opacity(0.4))
                            .scaleEffect(y: -1)
                    }

                    // Toggle
                    MirroredComponent(title: "Toggle") {
                        PortalSourceView(toggleSource) {
                            Toggle("Enabled", isOn: $toggleValue)
                                .frame(width: 200)
                        }
                        .border(.red.opacity(0.4))
                        PortalMirrorView(toggleSource, matchesTransform: false)
                            .border(.purple.opacity(0.4))
                            .scaleEffect(y: -1)
                    }

                    // Stepper
                    MirroredComponent(title: "Stepper") {
                        PortalSourceView(stepperSource) {
                            Stepper("Value: \(stepperValue)", value: $stepperValue, in: 0...10)
                                .frame(width: 200)
                        }
                        .border(.red.opacity(0.4))
                        PortalMirrorView(stepperSource, matchesTransform: false)
                            .border(.purple.opacity(0.4))
                            .scaleEffect(y: -1)
                    }

                    // Segmented Picker
                    MirroredComponent(title: "Picker") {
                        PortalSourceView(pickerSource) {
                            Picker("Option", selection: $pickerValue) {
                                Text("One").tag(0)
                                Text("Two").tag(1)
                                Text("Three").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .border(.red.opacity(0.4))
                        PortalMirrorView(pickerSource, matchesTransform: false)
                            .border(.purple.opacity(0.4))
                            .scaleEffect(y: -1)
                    }

                    // Button
                    MirroredComponent(title: "Button") {
                        PortalSourceView(buttonSource) {
                            Button("Tap Me") {}
                                .buttonStyle(.borderedProminent)
                        }
                        .border(.red.opacity(0.4))
                        PortalMirrorView(buttonSource, matchesTransform: false)
                            .border(.purple.opacity(0.4))
                            .scaleEffect(y: -1)
                    }
                }
                .padding()
            }
        }
    }

    struct MirroredComponent<Content: View>: View {
        let title: String
        @ViewBuilder let content: Content

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    content
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    return Example()
}
