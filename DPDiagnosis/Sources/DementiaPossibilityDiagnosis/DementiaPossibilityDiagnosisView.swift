import Combine
import SwiftUI
import FSCalendar

struct DementiaPossibilityDiagnosisView: View {
    @ObservedObject var viewModel = DementiaPossibilityDiagnosisViewModel()

    private let selectedDatePass = CurrentValueSubject<Date, Never>(Date())

    private var cancellables: [AnyCancellable] = []

    init() {
        bind()

        //DEBUG
    }

    private func bind() {
        viewModel.transform(input: .init(
            selectedDatePublisher: selectedDatePass
        ))
    }

    var body: some View {
        List {
            Section () {
                VStack(alignment: .center) {
                    HStack {
                        Text("あなたの\n認知症可能性")
                            .font(.largeTitle)
                        Spacer()
                        Image("dementia_rate_01")
                            .resizable()
                            .frame(width: 140, height: 140, alignment: .trailing)
                    }
                    HStack {
                        Text("簡易的な認知症判定をベースにしています\n認知症の有無を確定するものではございません")
                            .font(.footnote)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }

                }
            }
            Section (header: Text(DateUtils.stringFromDate(date: viewModel.currentDate, format: "M/d") + "の記録").font(.title)) {
                VStack(alignment: .center) {
                    HStack {
                        Text("概日リズム")
                            .font(.title2)
                        Button(action: {
                            }){
                                Image("info_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .foregroundColor(.blue)
                            }
                        Spacer()
                    }
                    HStack(alignment: .lastTextBaseline) {
                        Text("100")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("/100")
                            .font(.headline)
                            .fontWeight(.medium)
                        Text("非常に安定している")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        CircadianRhythmGraphView(input: .init(datePublisher: viewModel.selectedDatePublisher))
                            .frame(width: .infinity, height: 300, alignment: .center)
                    }
                    HStack {
                        Text("記録したデータ")
                            .font(.title2)
                        Spacer()
                    }
                    HStack {
                        CalendarTestView(selectedDate: selectedDatePass, existDataDate: $viewModel.existDataDate)
                            .frame(height: 400)
                    }
                }
            }
        }
    }
}

extension DementiaPossibilityDiagnosisView {
    struct CalendarTestView: UIViewRepresentable {
        let selectedDate: CurrentValueSubject<Date, Never>
        @Binding var existDataDate: [Date]

        func makeUIView(context: Context) -> UIView {
            typealias UIViewType = FSCalendar

            let fsCalendar = FSCalendar()

            fsCalendar.delegate = context.coordinator
            fsCalendar.dataSource = context.coordinator
            //カスタマイズ
            //表示
            fsCalendar.scrollDirection = .vertical //スクロールの方向
            fsCalendar.scope = .month //表示の単位（週単位 or 月単位）
            fsCalendar.locale = Locale(identifier: "en") //表示の言語の設置（日本語表示の場合は"ja"）
            //ヘッダー
            fsCalendar.appearance.headerTitleFont = UIFont.systemFont(ofSize: 16) //ヘッダーテキストサイズ
            fsCalendar.appearance.headerDateFormat = "yyyy/MM" //ヘッダー表示のフォーマット
            fsCalendar.appearance.headerTitleColor = UIColor.label //ヘッダーテキストカラー
            fsCalendar.appearance.headerMinimumDissolvedAlpha = 0 //前月、翌月表示のアルファ量（0で非表示）
            //曜日表示
            fsCalendar.appearance.weekdayFont = UIFont.systemFont(ofSize: 10) //曜日表示のテキストサイズ
            fsCalendar.appearance.weekdayTextColor = .darkGray //曜日表示のテキストカラー
            fsCalendar.appearance.titleWeekendColor = .red //週末（土、日曜の日付表示カラー）
            //カレンダー日付表示
            fsCalendar.appearance.titleFont = UIFont.systemFont(ofSize: 16) //日付のテキストサイズ
            fsCalendar.appearance.titleFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.bold) //日付のテキスト、ウェイトサイズ
            fsCalendar.appearance.todayColor = .clear //本日の選択カラー
            fsCalendar.appearance.titleTodayColor = .orange //本日のテキストカラー

            fsCalendar.appearance.selectionColor = .clear //選択した日付のカラー
            fsCalendar.appearance.borderSelectionColor = .blue //選択した日付のボーダーカラー
            fsCalendar.appearance.titleSelectionColor = .black //選択した日付のテキストカラー

            fsCalendar.appearance.borderRadius = 0 //本日・選択日の塗りつぶし角丸量

            fsCalendar.appearance.eventDefaultColor

            return fsCalendar
        }

        func updateUIView(_ uiView: UIView, context: Context) {
        }

        func makeCoordinator() -> Coordinator{
            return Coordinator(self)
        }

        class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
            var parent:CalendarTestView

            let dateFormatter = DateFormatter()

            init(_ parent:CalendarTestView){
                self.parent = parent
            }

            func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
                dateFormatter.dateFormat = "MMM dd, yyyy"
                for eventDate in parent.existDataDate {
                    guard let eventDate = dateFormatter.date(from: dateFormatYMD(date: eventDate)) else { return 0 }
                    if date.compare(eventDate) == .orderedSame{
                        return 1
                    }
                }
                return 0
            }

            func dateFormatYMD(date: Date) -> String {
                let df = DateFormatter()
                df.dateStyle = .long
                df.timeStyle = .none

                return df.string(from: date)
            }

            func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
                parent.selectedDate.send(date)
            }
        }
    }
}

struct DementiaPossibilityDiagnosisView_Previews: PreviewProvider {
    static var previews: some View {
        DementiaPossibilityDiagnosisView()
    }
}
