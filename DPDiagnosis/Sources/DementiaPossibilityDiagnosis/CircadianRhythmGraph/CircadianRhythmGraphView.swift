import SwiftUI
import Charts
import Combine

struct CircadianRhythmGraphView: View {
    @ObservedObject var viewModel: CircadianRhythmViewModel
    let input: Input

    init(input: Input) {
        self.viewModel = CircadianRhythmViewModel()
        self.input = input
        bind(input: input)
    }

    private func bind(input: Input) {
        viewModel.transform(input: .init(
            selectedDate: input.datePublisher
        ))
    }

    var body: some View {
        CircadianRhythmChartView(graphData: $viewModel.graphData)
            .frame(width: .infinity, height: 300, alignment: .center)
    }
}

struct CircadianRhythmGraphView_Previews: PreviewProvider {
    static var previews: some View {
        CircadianRhythmGraphView(input: .init(datePublisher: Empty<Date, Never>().eraseToAnyPublisher()))
    }
}

extension CircadianRhythmGraphView {
    struct Input {
        let datePublisher: AnyPublisher<Date, Never>
    }
}

extension CircadianRhythmGraphView {
    struct CircadianRhythmChartView: View {
        @Binding var graphData: [GraphData]

        var body: some View {
            Group {
                if let graphData = graphData.first {
                    CircadianRhythmChart(graphData: graphData)
                } else {
                    Text("")
                }
            }
        }
    }

    struct CircadianRhythmChart : UIViewRepresentable {
        var graphData: GraphData

        func makeUIView(context: Context) -> LineChartView {
            let chartView = LineChartView()

            guard let estimatedCircadianRhythm = graphData.estimatedCircadianRhythm,
                  !graphData.heartRateData.isEmpty else {
                return chartView
            }

            setData(chartView: chartView, graphData: graphData, estimatedCircadianRhythm: estimatedCircadianRhythm)

            return chartView
        }

        func updateUIView(_ chartView: LineChartView, context: Context) {
            guard let estimatedCircadianRhythm = graphData.estimatedCircadianRhythm,
                  !graphData.heartRateData.isEmpty else {
                return
            }

            setData(chartView: chartView, graphData: graphData, estimatedCircadianRhythm: estimatedCircadianRhythm)
        }

        private func setData(chartView: LineChartView, graphData: GraphData, estimatedCircadianRhythm: EstimatedCircadianRhythm) {
            let xAxis = chartView.xAxis
            xAxis.labelPosition = .bottom
            xAxis.drawLabelsEnabled = true
            xAxis.drawLimitLinesBehindDataEnabled = true
            xAxis.avoidFirstLastClippingEnabled = true

            // Set the x values date formatter
             let xValuesNumberFormatter = ChartXAxisFormatter()
            let formatter: DateFormatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = "HH:mm"
            xValuesNumberFormatter.dateFormatter = formatter
            xAxis.valueFormatter = xValuesNumberFormatter

            let lineChartData = LineChartData()

            // 概日リズム
            let circadianRhythmChartEntry : [ChartDataEntry] = estimatedCircadianRhythm.plots
                .map { plot -> ChartDataEntry in
                    .init(x: Double(plot.time.timeIntervalSince1970), y: plot.estimatedHeartRate)
                }
            let circadianRhythmDataSet = LineChartDataSet(entries: circadianRhythmChartEntry)
            circadianRhythmDataSet.mode = .cubicBezier
            circadianRhythmDataSet.drawValuesEnabled = false
            circadianRhythmDataSet.drawCirclesEnabled = false
            circadianRhythmDataSet.lineWidth = 3
            circadianRhythmDataSet.label = "概日リズム"
            circadianRhythmDataSet.colors = [.orange]
            lineChartData.addDataSet(circadianRhythmDataSet)

            // 心拍数
            let heartRateChartEntry : [ChartDataEntry] = graphData.heartRateData
                .map { heartRate -> ChartDataEntry in
                .init(x: Double(heartRate.startDatetime.timeIntervalSince1970), y: heartRate.value)
                }
            let heartRateDataSet = LineChartDataSet(entries: heartRateChartEntry)
            heartRateDataSet.mode = .cubicBezier
            heartRateDataSet.drawValuesEnabled = true
            heartRateDataSet.drawCirclesEnabled = true
            heartRateDataSet.lineWidth = 0
            heartRateDataSet.circleRadius = 4
            heartRateDataSet.label = "心拍数"
            heartRateDataSet.colors = [.black]
            heartRateDataSet.circleColors = [.black]
            lineChartData.addDataSet(heartRateDataSet)

            // データセットを作ってチャートに反映
            chartView.data = lineChartData

            chartView.animate(xAxisDuration: 0.5) // 左から右にグラフをアニメーションで表示する
        }
    }

}

class ChartXAxisFormatter: NSObject {
    var dateFormatter: DateFormatter?
}

extension ChartXAxisFormatter: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if let dateFormatter = dateFormatter {

            let date = Date(timeIntervalSince1970: value)
            return dateFormatter.string(from: date)
        }

        return ""
    }
}
