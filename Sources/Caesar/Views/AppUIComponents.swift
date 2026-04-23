import CaesarCore
import SwiftUI

// MARK: - Glass panel

struct CaesarPanel<Content: View>: View {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = AppTheme.cornerRadius
    var interactive: Bool = false
    @ViewBuilder var content: Content

    @State private var hovered = false

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppTheme.surface.opacity(0.92))

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.88),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.plusLighter)
                        .opacity(0.7)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.stroke, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowContact, radius: 2, x: 0, y: 1)
            .shadow(
                color: AppTheme.shadowLift.opacity(interactive && hovered ? 1.4 : 1.0),
                radius: interactive && hovered ? 34 : 24,
                x: 0,
                y: interactive && hovered ? 18 : 12
            )
            .offset(y: interactive && hovered ? -2 : 0)
            .onHover { hovering in
                guard interactive else { return }
                withAnimation(AppMotion.selection) { hovered = hovering }
            }
    }
}

// MARK: - Metric card

struct MetricCard: View {
    var title: String
    var value: String
    var subtitle: String
    var tone: Color = AppTheme.accent
    var delta: String? = nil
    var deltaPositive: Bool = true
    var compact: Bool = false

    var body: some View {
        CaesarPanel(padding: compact ? 14 : 18) {
            VStack(alignment: .leading, spacing: compact ? 8 : 12) {
                HStack(alignment: .center) {
                    Text(title.uppercased())
                        .font(compact ? AppTypography.body(size: 10, weight: .semibold) : AppTypography.eyebrow)
                        .tracking(compact ? 1.0 : 1.2)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    if let delta {
                        DeltaBadge(text: delta, positive: deltaPositive)
                    }
                }
                Text(value)
                    .font(compact ? AppTypography.display(size: 24, weight: .bold) : AppTypography.metricValue)
                    .foregroundStyle(tone)
                    .lineLimit(1)
                    .minimumScaleFactor(compact ? 0.52 : 0.7)
                Text(subtitle)
                    .font(compact ? AppTypography.body(size: 11, weight: .regular) : AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DeltaBadge: View {
    var text: String
    var positive: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(AppTypography.eyebrow)
        }
        .foregroundStyle(positive ? AppTheme.success : AppTheme.danger)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule().fill((positive ? AppTheme.success : AppTheme.danger).opacity(0.10))
        )
    }
}

// MARK: - Status pill

struct StatusPill: View {
    var text: String
    var tone: Color = AppTheme.accent
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(AppTypography.body(size: 12, weight: .semibold))
            .foregroundStyle(filled ? AppTheme.surface : tone)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(filled ? tone : tone.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(tone.opacity(filled ? 0 : 0.22), lineWidth: 1)
            )
    }
}

// MARK: - Buttons

struct PrimaryGlassButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    @State private var hovered = false
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(AppTypography.body(size: 13, weight: .semibold))
            }
            .foregroundStyle(AppTheme.surface)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(AppTheme.accent.opacity(hovered ? 0.88 : 1.0))
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
            .shadow(color: AppTheme.shadowLift.opacity(hovered ? 0.8 : 0.4), radius: hovered ? 14 : 6, x: 0, y: hovered ? 8 : 3)
        }
        .buttonStyle(PressCaptureStyle(pressed: $pressed))
        .onHover { hovering in
            withAnimation(AppMotion.selection) { hovered = hovering }
        }
    }
}

struct SecondaryGlassButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    @State private var hovered = false
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(title)
                    .font(AppTypography.body(size: 13, weight: .medium))
            }
            .foregroundStyle(AppTheme.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(hovered ? AppTheme.elevated : AppTheme.surface.opacity(0.9))
            )
            .overlay(
                Capsule().stroke(hovered ? AppTheme.text.opacity(0.25) : AppTheme.stroke, lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(PressCaptureStyle(pressed: $pressed))
        .onHover { hovering in
            withAnimation(AppMotion.selection) { hovered = hovering }
        }
    }
}

struct InlineActionButton: View {
    var title: String
    var systemImage: String
    var role: ButtonRole?
    var action: () -> Void

    @State private var hovered = false
    @State private var pressed = false

    init(_ title: String, systemImage: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(AppTypography.body(size: 12, weight: .medium))
            }
            .foregroundStyle(role == .destructive ? AppTheme.danger : AppTheme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(hovered ? AppTheme.elevated : AppTheme.surface)
            )
            .overlay(
                Capsule().stroke(AppTheme.stroke, lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(PressCaptureStyle(pressed: $pressed))
        .onHover { hovering in
            withAnimation(AppMotion.selection) { hovered = hovering }
        }
    }
}

// Captures the pressed state so the host view can animate scale / shadow.
private struct PressCaptureStyle: ButtonStyle {
    @Binding var pressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                withAnimation(AppMotion.selection) { pressed = isPressed }
            }
    }
}

// MARK: - Search field (glass)

struct GlassSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search matters, contacts..."

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(AppTypography.body(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(AppTheme.elevated)
        )
        .overlay(
            Capsule().stroke(AppTheme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Empty state

struct EmptyModuleState: View {
    var title: String
    var subtitle: String
    var systemImage: String = "sparkles"

    var body: some View {
        CaesarPanel {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppTheme.text)
                Text(subtitle)
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Module scroll shell

struct ModuleScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 36)
                .padding(.top, 16)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.visible)
        .background(AppTheme.background)
    }
}

// MARK: - Mini bar (fluxo)

struct MiniBar: View {
    var value: Double
    var maxValue: Double
    var tone: Color = AppTheme.accent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.stroke.opacity(0.5))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tone.opacity(0.95), tone.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, proxy.size.width * CGFloat(maxValue <= 0 ? 0 : min(1, value / maxValue))))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Row shell (list rows)

struct RowShell<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            content
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                .fill(AppTheme.surface.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                .stroke(AppTheme.stroke.opacity(0.28), lineWidth: 1)
        )
    }
}

// MARK: - Page title

extension View {
    func caesarPageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.pageTitle)
                .foregroundStyle(AppTheme.text)
            Text(subtitle)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}

// MARK: - Pillars strip

struct PillarsStrip: View {
    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(AppBrand.pillars.enumerated()), id: \.offset) { index, pillar in
                if index > 0 {
                    Circle()
                        .frame(width: 3, height: 3)
                        .font(.system(size: 8))
                        .foregroundStyle(AppTheme.mutedText)
                }
                Text(pillar.uppercased())
                    .font(AppTypography.eyebrow)
                    .tracking(2.4)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    var eyebrow: String
    var title: String
    var trailing: AnyView? = nil

    init(eyebrow: String, title: String) {
        self.eyebrow = eyebrow
        self.title = title
        self.trailing = nil
    }

    init<T: View>(eyebrow: String, title: String, @ViewBuilder trailing: () -> T) {
        self.eyebrow = eyebrow
        self.title = title
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                if !eyebrow.isEmpty {
                    Text(eyebrow)
                        .font(AppTypography.body(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppTheme.text)
            }
            Spacer()
            trailing
        }
    }
}
