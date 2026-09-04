import SwiftUI

/// Master prompt § 15 category grid. Only shows categories that actually
/// have something in them, plus "Document" as the always-present catch-all
/// — an empty grid of a dozen categories would just be noise.
struct VaultCategoryGrid: View {
    let counts: [DocumentCategory: Int]
    var onSelect: (DocumentCategory) -> Void

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: Metrics.spacingM)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Metrics.spacingM) {
            ForEach(nonEmptyCategories, id: \.self) { category in
                Button {
                    onSelect(category)
                } label: {
                    VStack(spacing: Metrics.spacingS) {
                        Image(systemName: category.symbolName)
                            .font(.system(size: 20))
                            .foregroundStyle(Palette.accent)
                        Text(category.displayName)
                            .font(AeriaFont.caption)
                            .foregroundStyle(Palette.textPrimary)
                        Text("\(counts[category] ?? 0)")
                            .font(AeriaFont.captionEmphasized)
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Metrics.spacingM)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var nonEmptyCategories: [DocumentCategory] {
        DocumentCategory.allCases.filter { (counts[$0] ?? 0) > 0 }
    }
}
