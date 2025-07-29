import UIKit

class CleanHistoryViewController: UITableViewController {
    var history: [CompressionResult] = []
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("clean_history_title",tableName: "CleanHistory", comment: "Clean History")
        tableView.register(CleanHistoryCell.self, forCellReuseIdentifier: "HistoryCell")
        if history.isEmpty {
            CompressionHistoryManager.shared.loadFromFirestore { results in
                    DispatchQueue.main.async {
                        self.history = results
                        self.tableView.reloadData()
                        self.tableView.backgroundColor = .systemBackground
                        self.tableView.separatorColor = UIColor { trait in
                            trait.userInterfaceStyle == .dark ? UIColor.white : UIColor.separator
                        }
                        print("📥 Loaded \(results.count) sessions from Firestore.")
                    }
                }
        }else{
            showNoHistoryAlert()

        }
    }

    private func showNoHistoryAlert() {
        let message = NSLocalizedString("no_clean_history_message", tableName: "CleanHistory", comment: "No compression history found")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", tableName: "CleanHistory", comment: "OK"),
            style: .default,
            handler: { _ in
                self.navigationController?.popToRootViewController(animated: true)
            }
        ))

        present(alert, animated: true)
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = history[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! CleanHistoryCell
        cell.configure(with: result, formatter: dateFormatter)
        return cell
    }
}
