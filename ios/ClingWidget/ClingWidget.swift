import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), name: "Poornima 💕", battery: 100, mood: "💭", song: "Not playing")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func getEntry() -> SimpleEntry {
        let prefs = UserDefaults(suiteName: "group.com.cling.app")
        let name = prefs?.string(forKey: "partner_name") ?? "Poornima 💕"
        let battery = prefs?.integer(forKey: "battery_level") ?? 0
        let mood = prefs?.string(forKey: "partner_mood") ?? "💭"
        let song = prefs?.string(forKey: "partner_song") ?? "Not playing"
        
        return SimpleEntry(date: Date(), name: name, battery: battery, mood: mood, song: song)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let name: String
    let battery: Int
    let mood: String
    let song: String
}

struct ClingWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.1) // Deep dark blue/black background
            
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .bold()
                
                HStack(spacing: 12) {
                    // Battery
                    VStack {
                        Text("Battery")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text("\(entry.battery)%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.5))
                    }
                    .padding(8)
                    .background(Color(white: 0.15))
                    .cornerRadius(8)
                    
                    // Mood
                    VStack {
                        Text("Mood")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(entry.mood)
                            .font(.system(size: 16))
                    }
                    .padding(8)
                    .background(Color(white: 0.15))
                    .cornerRadius(8)
                }
                
                // Song
                VStack(alignment: .leading) {
                    Text("🎵 Listening to")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(entry.song)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.15))
                .cornerRadius(8)
            }
            .padding()
        }
    }
}

@main
struct ClingWidget: Widget {
    let kind: String = "ClingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Partner Stats")
        .description("Keep track of Poornima's battery, mood, and song.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
