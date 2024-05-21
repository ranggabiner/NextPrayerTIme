import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = NextPrayerTimeLocationManager()
    @State private var prayerTime: String = "Loading..."
    @State private var nextPrayerName: String = "Loading..."
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text(nextPrayerName)
                .fontWeight(.semibold)
                .font(.system(size: 34))
                .foregroundStyle(Color(hex: 0xA2FC06))
            Text(prayerTime)
                .fontWeight(.semibold)
                .font(.system(size: 34))
                .foregroundStyle(Color(hex: 0xA2FC06))
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onReceive(locationManager.$province) { _ in
            updatePrayerTime()
        }
        .onReceive(locationManager.$city) { _ in
            updatePrayerTime()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updatePrayerTime()
        }
    }
    
    private func updatePrayerTime() {
        guard let location = locationManager.location else {
            print("Location not available")
            return
        }
        
        if let prayerTimes = loadPrayerTimes(for: Date(), province: locationManager.province, city: locationManager.city) {
            let nextPrayerInfo = getNextPrayerInfo(currentTime: Date(), prayerTimes: prayerTimes)
            prayerTime = nextPrayerInfo.time
            nextPrayerName = nextPrayerInfo.name
        } else {
            prayerTime = "Error loading prayer times"
            nextPrayerName = "Error"
        }
    }
    
    private func getNextPrayerInfo(currentTime: Date, prayerTimes: PrayerTimes) -> (name: String, time: String) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        func timeToComponents(_ time: String) -> DateComponents? {
            guard let date = dateFormatter.date(from: time) else { return nil }
            return calendar.dateComponents([.hour, .minute], from: date)
        }
        
        func createDate(components: DateComponents) -> Date? {
            return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: currentTime)
        }
        
        let prayerTimesList = [
            (name: "Fajr", time: prayerTimes.fajr),
            (name: "Sunrise", time: prayerTimes.sunrise),
            (name: "Dhuhr", time: prayerTimes.dhuhr),
            (name: "Asr", time: prayerTimes.asr),
            (name: "Maghrib", time: prayerTimes.maghrib),
            (name: "Isha", time: prayerTimes.isha)
        ]
        
        for prayer in prayerTimesList {
            if let components = timeToComponents(prayer.time), let date = createDate(components: components), date > currentTime {
                return (name: prayer.name, time: dateFormatter.string(from: date))
            }
        }
        
        // If the current time is past Isha, return the time for Fajr of the next day
        if let fajrComponents = timeToComponents(prayerTimes.fajr), let fajrDate = createDate(components: fajrComponents) {
            let nextDayFajrDate = calendar.date(byAdding: .day, value: 1, to: fajrDate)
            let nextPrayerTime = nextDayFajrDate != nil ? dateFormatter.string(from: nextDayFajrDate!) : "Error"
            return (name: "Fajr", time: nextPrayerTime)
        }
        
        return (name: "Error", time: "Error")
    }
}

#Preview {
    ContentView()
}
