import SwiftUI

/// Master prompt § 40 small widget: "2 things need attention." Deliberately
/// just a number and a phrase — a small widget has no room for a list, and
/// shouldn't try to have one.
struct SmallWidgetView: View {
    let snapshot: TodaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer()
            if snapshot.openLooseEndCount == 0 {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.positive)
                Text("All clear")
                    .font(AeriaFont.headline)
                    .foregroundStyle(Palette.textPrimary)
            } else {
                Text("\(snapshot.openLooseEndCount)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                Text(snapshot.openLooseEndCount == 1 ? "thing needs\nattention" : "things need\nattention")
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }
}
