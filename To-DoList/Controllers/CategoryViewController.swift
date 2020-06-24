//
//  CategoryViewController.swift
//  To-DoList
//


import UIKit
import CoreData

class CategoryViewController: UITableViewController
{
    var categories = [Category]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressedTableView))
        
        tableView.addGestureRecognizer(longPressRecognizer)
        loadCategories()
    }
    
    //MARK: - LongPress methods
    @objc func longPressedTableView(sender:UILongPressGestureRecognizer)
    {
        if(sender.state == .began)
        {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint)
            {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                performSegue(withIdentifier: "goToNotes", sender: tableView)
            }
        }
    }
    
    //MARK: - TableView Datasource methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) //as? categoryTableViewCell
        
        cell.textLabel?.text = "Item: \(indexPath.row + 1)"
        cell.detailTextLabel?.text = categories[indexPath.row].name
        cell.accessoryType = categories[indexPath.row].done ? .checkmark : .none
        
        if(categories[indexPath.row].done) {
            cell.textLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            cell.detailTextLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        }
        else{
            cell.textLabel?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            cell.detailTextLabel?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        return cell
    }
    
    
    //MARK: - TableView Delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        if(!categories[indexPath.row].done) {
            categories[indexPath.row].done = true
            saveCategories()
            
            categories.append(categories.remove(at: indexPath.row))

            let selectedCell = tableView.cellForRow(at: indexPath)
            selectedCell?.textLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            selectedCell?.detailTextLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    //MARK: - Segue methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let notesVC = segue.destination as? NotesViewController
        {
            if let indexPath = tableView.indexPathForSelectedRow
            {
                notesVC.selectedCategory = categories[indexPath.row]
            }
        }
    }
    
    //MARK: - Data manipulation methods
    func saveCategories() {
        do {
            try context.save()
        }
        catch {
            print("Error saving task: \(error)")
        }
        tableView.reloadData()
    }
    
    func loadCategories(with request:NSFetchRequest<Category> = Category.fetchRequest(), predicate: NSPredicate? = nil) {
        request.predicate = predicate
        
        do {
            categories = try context.fetch(request)
        }
        catch {
            print("Error fetching data from context:\(error)")
        }
        tableView.reloadData()
    }
    
    //MARK: - Add New Categories

    fileprivate func createAddAlertAction() {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Task", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            let newCategory = Category(context: self.context)
            newCategory.name = textField.text!
            newCategory.done = false
            
            self.categories.insert(newCategory, at: 0)
            self.saveCategories()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        alert.addAction(cancel)
        
        alert.addTextField { (field) in
            textField = field
            textField.placeholder = "Create new task"
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func barButtonPressed(_ sender: UIBarButtonItem) {
        createAddAlertAction()
    }
    
    //MARK: - Cell Swipe Actions
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let categoryTitle = categories[indexPath.row].name
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (contextualAction, view, actionPerformed:@escaping (Bool)->() ) in
            
            let alert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this task: \(categoryTitle!)", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction) in
                actionPerformed(false)
            }))
        
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (alertAction) in
                
                self.deleteCategory(index: indexPath.row)
                tableView.reloadData()
                actionPerformed(true)
            }))
            self.present(alert, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let edit = UIContextualAction(style: .normal, title: "Edit") { (contextualAction, view, actionPerformed:@escaping (Bool)->Void)
            in
            
            let alert = UIAlertController(title: "Edit", message: "Are you sure you want to edit this task?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction) in
                actionPerformed(false)
            }))
            
            var textField =  UITextField()
            
            alert.addTextField(configurationHandler: { (field) in
                textField = field
                textField.text = self.categories[indexPath.row].name
            })
            
            alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (alertAction) in
                self.categories[indexPath.row].name = textField.text
                self.saveCategories()
                
                actionPerformed(true)
            }))
            
            self.present(alert, animated: true)
        }
        edit.backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
        return UISwipeActionsConfiguration(actions: [edit])
    }
    
    func deleteCategory(index:Int) {
        //Delete the row from the data source
        context.delete(categories[index])
        categories.remove(at: index)
        saveCategories()
    }
}

//MARK: - Extensions

extension CategoryViewController: UISearchBarDelegate {
    
    func createRequest(searchText:String)->(NSFetchRequest<Category>,NSPredicate) {
        
        let request : NSFetchRequest<Category> = Category.fetchRequest()
        
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (request,predicate)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let result = createRequest(searchText:searchBar.text!)
        loadCategories(with: result.0, predicate: result.1)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if(searchBar.text?.count == 0){
            loadCategories()
            DispatchQueue.main.async
            {
                searchBar.resignFirstResponder()
            }
        }
        else
        {
            let result = createRequest(searchText:searchBar.text!)
            loadCategories(with: result.0, predicate: result.1)
        }
    }
}


