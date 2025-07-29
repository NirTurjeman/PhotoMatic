import UIKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: – State
    private var fullName: String = ""
    private var profileImage: UIImage? = UIImage(named: "user")

    private let languages = ["Hebrew", "English"]
    private var selectedLanguage: String = {
        let code = Locale.current.language.languageCode?.identifier
        return (code == "he" ? "Hebrew" : "English")
    }()

    private var hasChanges: Bool = false {
        didSet {
               updateSaveButtonAppearance()
           }
    }

    // MARK: – UI Elements
    private var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private var headerImageView = UIImageView()
    private var nameLabel = UILabel()
    private var nameTextField = UITextField()
    private lazy var saveButton: UIButton = {
        let btn: UIButton
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = NSLocalizedString("save_button", tableName: "Profile", comment: "Save")
            config.baseBackgroundColor = .systemGray
            config.baseForegroundColor = .white
            config.cornerStyle = .medium
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            btn = UIButton(configuration: config)
        } else {
            btn = UIButton(type: .system)
            btn.setTitle(NSLocalizedString("save_button", tableName: "Profile", comment: "Save"), for: .normal)
            btn.backgroundColor = .systemGray
            btn.setTitleColor(.white, for: .normal)
            btn.layer.cornerRadius = 8
            btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        }
        btn.isEnabled = false
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(onSaveTapped), for: .touchUpInside)
        return btn
    }()
    private func updateSaveButtonAppearance() {
        if #available(iOS 15.0, *) {
            var config = saveButton.configuration ?? UIButton.Configuration.filled()
            config.baseBackgroundColor = hasChanges ? .systemBlue : .systemGray
            saveButton.configuration = config
        } else {
            saveButton.backgroundColor = hasChanges ? .systemBlue : .systemGray
        }
        saveButton.isEnabled = hasChanges
    }

    private var loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("profile_title", tableName: "Profile", comment: "")
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")

        loadSettings()
        setupTableHeader()
        setupTableFooter()
    }

    // MARK: – Load & Save
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(fullName, forKey: "profile_fullName")
        defaults.set(selectedLanguage, forKey: "profile_Language")
        if let image = profileImage, let data = image.pngData() {
            defaults.set(data, forKey: "profile_ImageData")
        }
    }
    public func loadSettings() {
        let defaults = UserDefaults.standard
        if let name = defaults.string(forKey: "profile_fullName") {
            fullName = name
        }
        if let lang = defaults.string(forKey: "profile_Language") {
            selectedLanguage = lang
            LocalizationManager.shared.setLanguage(selectedLanguage)
        }
        if let imageData = defaults.data(forKey: "profile_ImageData"), let img = UIImage(data: imageData) {
            profileImage = img
        }
    }

    // MARK: – Header (Image + Editable Name)
    private func setupTableHeader() {
        let headerHeight: CGFloat = 220
        let imageSize: CGFloat   = 80

        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight))
        header.backgroundColor = .clear

        headerImageView = UIImageView(image: profileImage ?? UIImage(systemName: "person.circle.fill"))
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode        = .scaleAspectFill
        headerImageView.clipsToBounds      = true
        headerImageView.layer.cornerRadius = imageSize / 2
        headerImageView.layer.borderWidth  = 2
        headerImageView.layer.borderColor  = UIColor.white.cgColor
        headerImageView.isUserInteractionEnabled = true
        headerImageView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(onTapProfileImage)
        ))
        header.addSubview(headerImageView)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        headerImageView.addSubview(loadingIndicator)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textAlignment = .center
        nameLabel.font          = UIFont.systemFont(ofSize: 18, weight: .medium)
        nameLabel.textColor     = .label
        nameLabel.text          = fullName.isEmpty ? NSLocalizedString("full_name_placeholder", tableName: "Profile", comment: "Enter your name") : fullName
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(toggleNameEditing)
        ))
        header.addSubview(nameLabel)

        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.textAlignment = .center
        nameTextField.font          = UIFont.systemFont(ofSize: 18, weight: .medium)
        nameTextField.textColor     = .label
        nameTextField.placeholder   = NSLocalizedString("full_name_placeholder", tableName: "Profile", comment: "Enter your name")
        nameTextField.text          = fullName
        nameTextField.borderStyle   = .roundedRect
        nameTextField.alpha = fullName.isEmpty ? 1 : 0
        nameTextField.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
        header.addSubview(nameTextField)

        NSLayoutConstraint.activate([
            headerImageView.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            headerImageView.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            headerImageView.widthAnchor.constraint(equalToConstant: imageSize),
            headerImageView.heightAnchor.constraint(equalToConstant: imageSize),

            loadingIndicator.centerXAnchor.constraint(equalTo: headerImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: headerImageView.centerYAnchor),

            nameLabel.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),

            nameTextField.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 16),
            nameTextField.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16)
        ])

        tableView.tableHeaderView = header
    }
    // MARK: – Footer (Save Button)
       private func setupTableFooter() {
           let footer = UIView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: tableView.bounds.width,
                                             height: 60))
           saveButton.translatesAutoresizingMaskIntoConstraints = false
           footer.addSubview(saveButton)
           NSLayoutConstraint.activate([
               saveButton.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
               saveButton.centerYAnchor.constraint(equalTo: footer.centerYAnchor)
           ])
           tableView.tableFooterView = footer
       }

    // MARK: – Table Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.text = NSLocalizedString("language_label", tableName: "Profile", comment: "")
        let segmented = UISegmentedControl(items: languages)
        segmented.selectedSegmentIndex = (selectedLanguage == "English" ? 1 : 0)
        segmented.addTarget(self, action: #selector(languageChanged(_:)), for: .valueChanged)
        cell.accessoryView = segmented
        return cell
    }

    // MARK: – Actions
    @objc private func nameChanged(_ sender: UITextField) {
        fullName = sender.text ?? ""
        hasChanges = true
    }

    @objc private func toggleNameEditing() {
        loadingIndicator.startAnimating()
        let editing = nameTextField.alpha == 0
        UIView.animate(withDuration: 0.25, animations: {
            self.nameLabel.alpha = editing ? 0 : 1
            self.nameTextField.alpha = editing ? 1 : 0
        }) { _ in
            if editing {
                self.nameTextField.becomeFirstResponder()
            }
            self.loadingIndicator.stopAnimating()
        }
    }

    @objc private func languageChanged(_ sender: UISegmentedControl) {
        selectedLanguage = languages[sender.selectedSegmentIndex]
        hasChanges = true
    }
    
    @objc private func onSaveTapped() {
        saveSettings()
        LocalizationManager.shared.setLanguage(selectedLanguage)
        hasChanges = false
        self.navigationController?.popToRootViewController(animated: true)
    }

    // MARK: – Image Picker Delegate
    @objc private func onTapProfileImage() {
        loadingIndicator.startAnimating()
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let img = info[.originalImage] as? UIImage {
            profileImage = img
            headerImageView.image = img
            hasChanges = true
        }
        dismiss(animated: true)
    }
}
