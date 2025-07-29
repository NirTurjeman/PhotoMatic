import UIKit
import DGCharts

class AnalyzeStorageViewController: UIViewController {

    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var chartTypeLBL: UILabel!
    @IBOutlet weak var chartContainer: UIView!
    var history: [CompressionResult] = CompressionHistoryManager.shared.load()
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    let pieChartView = PieChartView()
    let barChartView = BarChartView()
    var totalStorageGB: Double?
    var imageStorageGB: Double?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupChartContainer()
        setupSegmentedControl()

        segment.selectedSegmentIndex = 0
        segmentChanged(segment)
    }

    private func setupChartContainer() {
        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chartContainer)

        NSLayoutConstraint.activate([
            chartContainer.topAnchor.constraint(equalTo: segment.bottomAnchor, constant: 20),
            chartContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chartContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chartContainer.heightAnchor.constraint(equalToConstant: 340)
        ])
    }

    private func setupSegmentedControl() {
        segment.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        chartContainer.subviews.forEach { $0.removeFromSuperview() }

        switch sender.selectedSegmentIndex {
        case 0:
            chartTypeLBL.text = "Total storage used"
            showStorageUsageChart()
        case 1:
            chartTypeLBL.text = "חיסכון ממוצע מדחיסה"
            history = CompressionHistoryManager.shared.load()
            var totalSaved: Double = 0
            for session in history {
                let original = Double(session.totalOriginalSize) / 1_073_741_824.0
                let compressed = Double(session.totalCompressedSize) / 1_073_741_824.0
                totalSaved += original/compressed
            }
            showCompressionSavingsChart(savedPercent: totalSaved)
        default:
            break
        }
    }

    private func showStorageUsageChart() {
        let totalStorageGB = calcHardCodedTotalGB(totalGB: totalStorageGB ?? 0.0)
        let imageStorageGB: Double = imageStorageGB ?? 0.0
       
        let otherStorageGB = totalStorageGB - imageStorageGB

        let entry1 = PieChartDataEntry(value: imageStorageGB, label: "Photos & Videos")
        let entry2 = PieChartDataEntry(value: otherStorageGB, label: "Other storage")

        let dataSet = PieChartDataSet(entries: [entry1, entry2], label: "")
        dataSet.colors = [UIColor.systemBlue, UIColor.systemGray3]
        dataSet.entryLabelColor = .label

        let data = PieChartData(dataSet: dataSet)
        data.setValueTextColor(.label)
        data.setValueFont(.systemFont(ofSize: 14, weight: .medium))

        pieChartView.data = data
        pieChartView.centerText = "Storage usage"
        pieChartView.translatesAutoresizingMaskIntoConstraints = false

        chartContainer.addSubview(pieChartView)

        NSLayoutConstraint.activate([
            pieChartView.topAnchor.constraint(equalTo: chartContainer.topAnchor),
            pieChartView.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor),
            pieChartView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            pieChartView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor)
        ])
    }
    func showCompressionSavingsChart(savedPercent: Double) {
        chartContainer.subviews.forEach { $0.removeFromSuperview() }

        let entry = BarChartDataEntry(x: 0, y: savedPercent)
        let dataSet = BarChartDataSet(entries: [entry], label: "Compressed Saved")
        dataSet.setColor(.systemGreen)

        let data = BarChartData(dataSet: dataSet)
        data.setValueFont(.systemFont(ofSize: 14, weight: .medium))
        data.barWidth = 0.5

        let chart = BarChartView()
        chart.data = data
        chart.translatesAutoresizingMaskIntoConstraints = false

        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Saved Space(GB)"])
        chart.xAxis.granularity = 1

        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.axisMaximum = 100
        chart.rightAxis.enabled = false
        chart.legend.enabled = false

        chartContainer.addSubview(chart)

        NSLayoutConstraint.activate([
            chart.topAnchor.constraint(equalTo: chartContainer.topAnchor),
            chart.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor),
            chart.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            chart.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor)
        ])
    }

    func calcHardCodedTotalGB(totalGB: Double) -> Double {
        switch totalGB {
        case 0...128: return 128.0
        case 129...512: return 512.0
        case 513...1024: return 1024.0
        default: return totalGB
        }
    }
}
