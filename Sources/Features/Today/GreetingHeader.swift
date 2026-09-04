import SwiftUI

/// Master prompt § 6: greeting, date, and a quiet weather chip when
/// available. Confident and calm — never "Good morning! ☀️ Let's crush the
/// day!"
struct GreetingHeader: View {
    let greeting: String
    let date: Date
    let weather: WeatherSnapshot?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(AeriaFont.display)
                    .foregroundStyle(Palette.textPrimary)
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(AeriaFont.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            if let weather {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: weather.symbolName)
                        .font(.system(size: 20))
                        .symbolRenderingMode(.hierarchical)
                    Text("\(Int(weather.temperatureCelsius.rounded()))°")
                        .font(AeriaFont.headline)
                }
                .foregroundStyle(Palette.textPrimary)
            }
        }
    }
}
