//
//  TaskTableViewController.swift
//  iOS Todo
//
//  Created by Lucas Popp on 1/7/18.
//  Copyright © 2018 Lucas Popp. All rights reserved.
//

import UIKit

class TaskTableViewController: UITableViewController, UITextViewDelegate, CommitmentPickerDelegate {
    
    var task: Task!
    
    private var checkbox: UICheckbox!
    private var titleView: UITextView!
    private var descriptionView: UITextView!
    
    private var dueDateLabel: UILabel!
    private var nextConvenientDateButton: UIButton!
    private var dueDateTypeControl: UISegmentedControl!
    private var specificDueDatePicker: BetterDatePicker!
    
    private var commitmentLabel: UILabel!
    
    private var priorityControl: PriorityControl!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DataManager.shared.update(task.record)
    }
    
    private func updateDueDateText() {
        switch task.dueDate {
            
        case .asap:
            dueDateLabel.text = "ASAP"
            break
            
        case .eventually:
            dueDateLabel.text = "Eventually"
            break
            
        case .specificDay(let specificDay):
            if let specificDate = specificDay.dateValue {
                dueDateLabel.text = BetterDateFormatter.autoFormatDate(specificDate)
            } else {
                dueDateLabel.text = "Invalid date"
            }
            
            break
            
        default: break
            
        }
    }
    
    @IBAction func dueDateTypeChanged(_ sender: UISegmentedControl) {
        tableView.beginUpdates()
        
        if sender.selectedSegmentIndex == 0 {
            task.dueDate = DueDate.specificDay(day: specificDueDatePicker.calendarDay)
        } else if sender.selectedSegmentIndex == 1 {
            task.dueDate = DueDate.asap
        } else if sender.selectedSegmentIndex == 2 {
            task.dueDate = DueDate.eventually
        }
        
        tableView.endUpdates()
        
        updateDueDateText()
    }
    
    @IBAction func specificDueDatePicked(_ sender: BetterDatePicker) {
        task.dueDate = DueDate.specificDay(day: sender.calendarDay)
        
        updateDueDateText()
    }
    
    @IBAction func makeDueToday() {
        specificDueDatePicker.calendarDay = CalendarDay(date: Date())
        task.dueDate = DueDate.specificDay(day: specificDueDatePicker.calendarDay)
        updateDueDateText()
    }
    
    @IBAction func makeDueNextConvenientDate() {
        var nextClassFound: Bool = false
        
        // TO DO: Add support for Extracurriculars
        if let course = task.commitment as? Course, course.classes.count > 0 {
            var runnerDate = Date().addingTimeInterval(24 * 60 * 60)
            var lastClassDate: CalendarDay = CalendarDay(date: runnerDate)
            
            for courseClass in course.classes {
                if lastClassDate < courseClass.endDate {
                    lastClassDate = courseClass.endDate
                }
            }
            
            var earliestDateFound: CalendarDay?
            
            var runnerDay = CalendarDay(date: runnerDate)
            while runnerDay <= lastClassDate {
                for courseClass in course.classes {
                    if courseClass.startDate <= runnerDay && runnerDay <= courseClass.endDate && courseClass.daysOfWeek.contains(DayOfWeek.forDate(runnerDate)) {
                        if earliestDateFound == nil {
                            earliestDateFound = runnerDay
                        }
                    }
                }
                
                if earliestDateFound != nil {
                    nextClassFound = true
                    break
                }
                
                runnerDate = runnerDate.addingTimeInterval(24 * 60 * 60)
                runnerDay = CalendarDay(date: runnerDate)
            }
            
            if let nextClassDate = earliestDateFound {
                specificDueDatePicker.calendarDay = CalendarDay(date: nextClassDate.dateValue!.addingTimeInterval(-24 * 60 * 60))
                task.dueDate = DueDate.specificDay(day: specificDueDatePicker.calendarDay)
                updateDueDateText()
            }
        }
        
        if !nextClassFound {
            specificDueDatePicker.calendarDay = CalendarDay(date: Date().addingTimeInterval(24 * 60 * 60))
            task.dueDate = DueDate.specificDay(day: specificDueDatePicker.calendarDay)
            updateDueDateText()
        }
    }
    
    @IBAction func priorityChanged(_ sender: UISegmentedControl) {
        task.priority = priorityControl.priority
        checkbox.priority = task.priority
    }
    
    // MARK: - Text view delegate
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.isEqual(titleView) {
            task.title = titleView.text
        } else if textView.isEqual(descriptionView) {
            task.userDescription = descriptionView.text
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if task.relatedAssignment != nil {
            return 3
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 3
        } else if section == 2 {
            return 1
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Name", for: indexPath)
                
                if let checkbox = cell.viewWithTag(1) as? UICheckbox {
                    self.checkbox = checkbox
                    checkbox.isOn = task.completed
                    checkbox.priority = task.priority
                    checkbox.tintColor = (task.relatedAssignment?.commitment ?? task.commitment)?.color ?? UICheckbox.defaultBorderColor
                }
                
                if let textView = cell.viewWithTag(2) as? UITextView {
                    titleView = textView
                    titleView.text = task.title
                }
                
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Description", for: indexPath)
                
                if let textView = cell.viewWithTag(1) as? UITextView {
                    descriptionView = textView
                    descriptionView.text = task.userDescription
                }
                
                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "Due Date", for: indexPath) as? TaskDueDatePickerTableViewCell {
                    dueDateLabel = cell.displayLabel
                    dueDateTypeControl = cell.segmentedControl
                    nextConvenientDateButton = cell.nextConvenientDateButton
                    specificDueDatePicker = cell.datePicker
                    
                    if task.commitment == nil {
                        nextConvenientDateButton.setTitle("Tomorrow", for: UIControlState.normal)
                    } else {
                        nextConvenientDateButton.setTitle("Before next class", for: UIControlState.normal)
                    }
                    
                    updateDueDateText()
                    
                    switch task.dueDate {
                        
                    case .specificDay(let day):
                        dueDateTypeControl.selectedSegmentIndex = 0
                        specificDueDatePicker.calendarDay = day
                        break
                        
                    case .asap:
                        dueDateTypeControl.selectedSegmentIndex = 1
                        break
                        
                    case .eventually:
                        dueDateTypeControl.selectedSegmentIndex = 2
                        break
                        
                    default: break
                        
                    }
                    
                    return cell
                }
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Priority", for: indexPath)
                
                if let picker = cell.viewWithTag(1) as? PriorityControl {
                    priorityControl = picker
                    priorityControl.priority = task.priority
                }
                
                return cell
            } else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Commitment", for: indexPath)
                
                if task.relatedAssignment != nil {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                    cell.selectionStyle = UITableViewCellSelectionStyle.none
                }
                
                if let label = cell.viewWithTag(1) as? UILabel {
                    commitmentLabel = label
                    
                    commitmentLabel.text = (task.relatedAssignment?.commitment ?? task.commitment ?? nil)?.longerName ?? "None"
                    commitmentLabel.textColor = (task.relatedAssignment?.commitment ?? task.commitment ?? nil)?.color ?? UIColor.black.withAlphaComponent(0.5)
                }
                
                return cell
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "Related Assignment", for: indexPath) as? AssignmentTableViewCell {
                    cell.assignment = task.relatedAssignment
                    cell.configureCell()
                    
                    return cell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            if let cell = tableView.cellForRow(at: indexPath) as? TaskDueDatePickerTableViewCell {
                return cell.fittingHeight
            }
        }
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 {
            return "Related Assignment"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            tableView.endEditing(true)
        }
        
        if indexPath.section == 1 && indexPath.row == 0 {
            tableView.beginUpdates()
            tableView.endUpdates()
            
            if let pickerCell = tableView.cellForRow(at: indexPath) as? TaskDueDatePickerTableViewCell {
                if pickerCell.pickerOpen {
                    tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
                }
            }
        } else if indexPath.section == 1 && indexPath.row == 2 {
            if task.relatedAssignment == nil {
                self.performSegue(withIdentifier: "Open Commitment Picker", sender: self)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Commitment picker delegate
    
    func selectedCommitment(_ commitment: Commitment?, in picker: CommitmentPickerTableViewController) {
        guard let commitment = commitment as? (Commitment & CKEnabled)? else { return }
        
        task.commitment = commitment
        checkbox.tintColor = (task.relatedAssignment?.commitment ?? task.commitment)?.color ?? UICheckbox.defaultBorderColor
        commitmentLabel.text = (task.relatedAssignment?.commitment ?? task.commitment)?.longerName ?? "None"
        commitmentLabel.textColor = (task.relatedAssignment?.commitment ?? task.commitment)?.color ?? UIColor.black.withAlphaComponent(0.5)
        
        if commitment == nil {
            nextConvenientDateButton.setTitle("Tomorrow", for: UIControlState.normal)
        } else {
            nextConvenientDateButton.setTitle("Before next class", for: UIControlState.normal)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let commitmentPicker = segue.destination as? CommitmentPickerTableViewController {
            commitmentPicker.commitment = task.commitment
            commitmentPicker.delegate = self
            commitmentPicker.updateData()
            commitmentPicker.tableView.reloadData()
        } else if let assignmentController = segue.destination as? AssignmentTableViewController {
            assignmentController.assignment = task.relatedAssignment
            assignmentController.title = "Related Assignment"
        }
    }

}
