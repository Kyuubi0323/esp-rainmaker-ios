// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  NodeDetailsViewController.swift
//  ESPRainMaker
//

import Toast_Swift
import UIKit

class NodeDetailsViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingIndicator: SpinnerView!
    @IBOutlet var loadingLabel: UILabel!

    var currentNode: Node!

    var dataSource: [[String]] = [[]]
    var collapsed = [false, false, false]
    var pendingRequests: [SharingRequest] = []

    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "NodeDetailsHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "nodeDetailsHV")
        tableView.register(UINib(nibName: "AddMemberTableViewCell", bundle: nil), forCellReuseIdentifier: "addMemberTVC")
        tableView.register(UINib(nibName: "MembersInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "membersInfoTVC")
        tableView.register(UINib(nibName: "NewMemberTableViewCell", bundle: nil), forCellReuseIdentifier: "newMemberTVC")
        tableView.register(UINib(nibName: "SharingTableViewCell", bundle: nil), forCellReuseIdentifier: "sharingTVC")

        tableView.estimatedRowHeight = 70.0
        tableView.tableFooterView = UIView()
        tableView.showsVerticalScrollIndicator = false

        createDataSource()

        // Add gesture to hide keyoboard on tapping anywhere on screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    // MARK: - IB Actions

    @IBAction func deleteNode(_: Any) {
        // Display message based on number of devices in the nodes.
        var title = "Are you sure?"
        var message = ""
        if currentNode.devices!.count > 1 {
            title = "Are you sure?"
            message = "By removing a node, all the associated devices will also be removed"
        }

        // Display a confirmation pop up on action of delete node.
        let confirmAction = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            Utility.showLoader(message: "Deleting node", view: self.view)
            let parameters = ["user_id": User.shared.userInfo.userID, "node_id": self.currentNode.node_id!, "secret_key": "", "operation": "remove"]
            // Call method to dissociate node from user
            NetworkManager.shared.addDeviceToUser(parameter: parameters) { _, error in
                if error == nil {
                    User.shared.associatedNodeList?.removeAll(where: { node -> Bool in
                        node.node_id == self.currentNode.node_id
                    })
                }
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    guard let removeNodeError = error else {
                        User.shared.updateDeviceList = true
                        self.navigationController?.popToRootViewController(animated: false)
                        return
                    }
                    if !ESPNetworkMonitor.shared.isConnectedToNetwork {
                        Utility.showToastMessage(view: self.view, message: "Unable to remove node. Please check your internet connection.")
                    } else {
                        Utility.showToastMessage(view: self.view, message: removeNodeError.description)
                    }
                }
            }
        }
        let noAction = UIAlertAction(title: "No", style: .default, handler: nil)
        confirmAction.addAction(yesAction)
        confirmAction.addAction(noAction)
        present(confirmAction, animated: true, completion: nil)
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    // Method to create data source for table view based on user role, sharing details and node information.
    func createDataSource() {
        var index = 0
        dataSource = [[]]
        dataSource[index].append("Node ID")
        dataSource[index].append("Node ID:\(currentNode.node_id ?? "")")

        if Configuration.shared.appConfiguration.supportSharing {
            index += 1
            dataSource.append([])
            dataSource[index].append("Sharing")
            if let primaryUsers = currentNode.primary {
                if primaryUsers.contains(User.shared.userInfo.email) {
                    // If user is primary displayed information about the user currently this node is shared with.
                    dataSource[index][0] = "Shared With"
                    if let secondaryUsers = currentNode.secondary {
                        dataSource[index].append(contentsOf: secondaryUsers)
                    }
                    // Provided option to add new members.
                    dataSource[index].append("Add Member")
                    loadingIndicator.isHidden = false
                    loadingIndicator.animate()
                    loadingLabel.isHidden = false
                    getSharingRequests()
                } else {
                    // If user is secondary displayed information about the primary user.
                    dataSource[index][0] = "Shared by"
                    dataSource[index].append(contentsOf: primaryUsers)
                }
            } else {
                // No sharing information is available
                dataSource[index].append("Not Available")
            }
        }

        index += 1
        dataSource.append([])
        dataSource[index].append("Node Information")
        dataSource[index].append("Name:\(currentNode.info?.name ?? "")")
        dataSource[index].append("Type:\(currentNode.info?.type ?? "")")
        dataSource[index].append("Firmware version:\(currentNode.info?.fw_version ?? "")")
        dataSource[index].append("Config Version:\(currentNode.config_version ?? "")")
        if let attributes = currentNode.attributes {
            for attribute in attributes {
                dataSource[index].append("\(attribute.name ?? ""):\(attribute.value ?? "")")
            }
        }
    }

    // MARK: - Private Methods

    // Method to update sharing data based on number of pending requests.
    private func updateSharingData() {
        if pendingRequests.count < 1 {
            dataSource[1].removeLast()
        }
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
        }
    }

    // Method to get all pending sharing request raised for this node.
    private func getSharingRequests() {
        NodeSharingManager.shared.getSharingRequests(primaryUser: true) { requests, error in
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = true
                self.loadingLabel.isHidden = true
            }
            guard let apiError = error else {
                self.pendingRequests.removeAll()

                if let sharingRequests = requests {
                    for request in sharingRequests {
                        // Filter pending request for current node.
                        if request.request_status?.lowercased() == "pending" {
                            if let nodeIDs = request.node_ids, nodeIDs.contains(self.currentNode.node_id ?? "") {
                                self.pendingRequests.append(request)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        // If pending request count is non zero, show these requests in a separate section.
                        if self.pendingRequests.count > 0 {
                            self.dataSource[1].append("Pending for acceptance")
                            self.tableView.reloadData()
                        }
                    }
                }
                return
            }
            Utility.showToastMessage(view: self.view, message: apiError.description, duration: 5.0)
        }
    }

    // Method to return appropriate table view cell for sharing feature.
    private func getTableViewCellForNewMember(forIndexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newMemberTVC", for: forIndexPath) as! NewMemberTableViewCell
        cell.memberEmailTextField.text = ""
        cell.memberEmailTextField.becomeFirstResponder()
        cell.memberEmailTextField.delegate = self
        cell.cancelButtonAction = {
            if self.pendingRequests.count > 0 {
                self.dataSource[1][self.dataSource[1].count - 2] = "Add Member"
            } else {
                self.dataSource[1][self.dataSource[1].count - 1] = "Add Member"
            }
            self.tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
        }
        cell.saveButtonAction = {
            Utility.showLoader(message: "Sharing in progress..", view: self.view)
            NodeSharingManager.shared.createSharingRequest(userName: cell.memberEmailTextField.text ?? "", node: self.currentNode) { request, error in
                Utility.hideLoader(view: self.view)
                guard let apiError = error else {
                    DispatchQueue.main.async {
                        if self.pendingRequests.count < 1 {
                            self.dataSource[1][self.dataSource[1].count - 1] = "Add Member"
                            self.dataSource[1].append("Pending for acceptance")
                        } else {
                            self.dataSource[1][self.dataSource[1].count - 2] = "Add Member"
                        }
                        self.pendingRequests.append(request!)
                        self.tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.view.makeToast("Failed to share node with error: \(apiError.description)", duration: 5.0, position: ToastManager.shared.position, title: nil, image: nil, style: ToastManager.shared.style, completion: nil)
                    if self.pendingRequests.count > 0 {
                        self.dataSource[1][self.dataSource[1].count - 2] = "Add Member"
                    } else {
                        self.dataSource[1][self.dataSource[1].count - 1] = "Add Member"
                    }
                    self.tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
                }
            }
        }
        return cell
    }

    // Method to get table view cell with Add Member option
    private func getTableViewCellForAddMember(forIndexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addMemberTVC", for: forIndexPath) as! AddMemberTableViewCell
        view.endEditing(true)
        cell.addMemberButtonAction = {
            if self.pendingRequests.count > 0 {
                self.dataSource[1][self.dataSource[1].count - 2] = "New Member"
            } else {
                self.dataSource[1][self.dataSource[1].count - 1] = "New Member"
            }
            self.tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
        }
        return cell
    }

    // Method to get table view cell for pending requests.
    private func getTableViewCellForPendingRequest(forIndexPath: IndexPath) -> UITableViewCell {
        let request = pendingRequests[forIndexPath.row + 1 - dataSource[1].count]
        let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: forIndexPath) as! MembersInfoTableViewCell
        cell.removeMemberButton.isHidden = false
        cell.removeButtonAction = {
            Utility.showLoader(message: "Removing request..", view: self.view)
            NodeSharingManager.shared.deleteSharingRequest(request: request) { _, error in
                Utility.hideLoader(view: self.view)
                guard let apiError = error else {
                    self.pendingRequests.remove(at: forIndexPath.row + 1 - self.dataSource[1].count)
                    self.updateSharingData()
                    return
                }
                DispatchQueue.main.async {
                    Utility.showToastMessage(view: self.view, message: "Failed to delete node sharing request with error: \(apiError.description)")
                }
            }
        }
        cell.secondaryUserLabel.text = request.user_name
        if let timestamp = request.request_timestamp {
            let expirationDate = Date(timeIntervalSince1970: timestamp)
            let days = Date().days(from: expirationDate)
            var expiringText = "Expires today"
            let daysLeft = 7 - days
            if daysLeft > 1 {
                expiringText = "Expires in \(daysLeft) days"
            } else if daysLeft == 1 {
                expiringText = "Expires in 1 day"
            } else {
                expiringText = "Expires today"
            }
            cell.timeStampLabel.isHidden = false
            cell.timeStampLabel.text = expiringText
        }
        return cell
    }
}

extension NodeDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView()
        }
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "nodeDetailsHV") as! NodeDetailsHeaderView
        headerView.headerLabel.text = dataSource[section][0]
        headerView.tintColor = .clear
        headerView.headerTappedAction = {
            self.collapsed[section] = !self.collapsed[section]
            self.tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
        }
        if collapsed[section] {
            headerView.arrowImageView.image = UIImage(named: "right_arrow_icon")
        } else {
            headerView.arrowImageView.image = UIImage(named: "down_arrow_icon")
        }
        return headerView
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 50.0
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if pendingRequests.count > 0 {
            if indexPath.section == 1, indexPath.row + 1 == dataSource[1].count - 1 {
                if dataSource[1][indexPath.row + 1] == "Pending for acceptance" {
                    return 40.0
                }
            }
        }
        return 55.0
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 16.0
    }

    func tableView(_: UITableView, willDisplayFooterView view: UIView, forSection _: Int) {
        view.tintColor = .clear
    }
}

extension NodeDetailsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if collapsed[section] {
            return 0
        }
        if section == 1 {
            return dataSource[section].count - 1 + pendingRequests.count
        }
        return dataSource[section].count - 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if Configuration.shared.appConfiguration.supportSharing {
            if indexPath.section == 1 {
                let header = dataSource[1][0]
                if indexPath.row + 1 >= dataSource[1].count {
                    return getTableViewCellForPendingRequest(forIndexPath: indexPath)
                }
                var rowValue = dataSource[1][indexPath.row + 1]
                switch header {
                case "Shared With":
                    switch rowValue {
                    case "Add Member":
                        return getTableViewCellForAddMember(forIndexPath: indexPath)
                    case "New Member":
                        return getTableViewCellForNewMember(forIndexPath: indexPath)
                    case "Pending for acceptance":
                        let cell = tableView.dequeueReusableCell(withIdentifier: "sharingTVC", for: indexPath) as! SharingTableViewCell
                        return cell
                    default:
                        let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                        cell.timeStampLabel.isHidden = true
                        cell.removeMemberButton.isHidden = false
                        cell.removeButtonAction = {
                            Utility.showLoader(message: "Removing user..", view: self.view)
                            NodeSharingManager.shared.deleteSharing(forNode: self.currentNode, email: cell.secondaryUserLabel.text ?? "") { success, error in
                                Utility.hideLoader(view: self.view)
                                guard let apiError = error else {
                                    if success {
                                        if let index = self.currentNode.secondary!.firstIndex(of: cell.secondaryUserLabel.text ?? "") {
                                            self.currentNode.secondary!.remove(at: index)
                                        }
                                        self.dataSource[1].remove(at: indexPath.row + 1)
                                        DispatchQueue.main.async {
                                            self.tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            Utility.showToastMessage(view: self.view, message: "Failed to delete node sharing with error: Unknown error.")
                                        }
                                    }
                                    return
                                }
                                DispatchQueue.main.async {
                                    Utility.showToastMessage(view: self.view, message: "Failed to delete node sharing with error: \(apiError.description)")
                                }
                            }
                        }
                        cell.secondaryUserLabel.text = rowValue
                        return cell
                    }
                case "Shared by":
                    rowValue = dataSource[1][indexPath.row + 1]
                    let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                    cell.removeMemberButton.isHidden = true
                    cell.secondaryUserLabel.text = rowValue
                    return cell
                default:
                    rowValue = "Not Available"
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                cell.removeMemberButton.isHidden = true
                cell.secondaryUserLabel.text = rowValue
                return cell
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeDetailsTVC", for: indexPath) as! NodeDetailsTableViewCell
        let value = dataSource[indexPath.section][indexPath.row + 1]
        if let firstIndex = value.firstIndex(of: ":") {
            let title = String(value[..<firstIndex])
            cell.titleLabel.text = title
            cell.detailLabel.text = String(value.dropFirst(title.count + 1))
        }
        return cell
    }
}

extension NodeDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
