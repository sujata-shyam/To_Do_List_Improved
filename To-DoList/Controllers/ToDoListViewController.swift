//
//  ViewController.swift
//  To-DoList
//
//  Created by Sujata on 19/11/19.
//  Copyright © 2019 Sujata. All rights reserved.
//

import UIKit
import CoreData

class ToDoListViewController: UITableViewController
{
    var itemArray = [Item]()
    var selectedCategory:Category? {
        didSet
        {
            loadItems()
        }
    }
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        //self.navigationItem.rightBarButtonItem = self.editButtonItem

    }

    //MARK: - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return itemArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        
        let item = itemArray[indexPath.row]
        
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add Items
    
    
    @IBAction func barButtonPressed(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add new item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            
        
            let newItem = Item(context: self.context)
            newItem.title = textField.text!
            newItem.done = false
            newItem.parentCategory = self.selectedCategory
            
            self.itemArray.append(newItem)
            self.saveItems()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Model Manipulation Methods
    
    func saveItems()
    {
        do
        {
            try context.save()
        }
        catch
        {
            print("Error saving context:\(error)")
        }
        
        tableView.reloadData()
    }
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil)
    {
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate
        {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        }
        else
        {
            request.predicate = categoryPredicate
        }
   
        do
        {
            itemArray = try context.fetch(request)
        }
        catch
        {
            print("Error fetching data from context:\(error)")
        }
        tableView.reloadData()
    }
    
    //Override to support conditional editing of the table view.

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        //Return false if you do not want the specified item to be editable.
        return true
    }

    //Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            //Delete the row from the data source
            context.delete(itemArray[indexPath.row])
            itemArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveItems()

        }
    }
    
//    //Actions in response to swipe action on a row
//    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
//    {
//        let item = itemArray[indexPath.row]
//
//        let editAction = UITableViewRowAction(style: .default, title: "Edit") { (action, indexpath) in
//        self.updateAction(item: item, indexPath: indexPath)
//        }
//
//        let deleteAction = UITableViewRowAction
//    }
//
//    func updateAction(item:Item, indexPath:IndexPath)
//    {
//
//    }
//
//    func deleteAction()
//    {}
    
    // Override to support conditional rearranging of the table view.
//    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
//    {
//        // Return false if you do not want the item to be re-orderable.
//        return true
//    }
//
//    // Override to support rearranging the table view.
//    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath)
//    {
//        let itemToMove = itemArray[fromIndexPath.row]
//        itemArray.remove(at: fromIndexPath.row)
//        itemArray.insert(itemToMove, at: to.row)
//    }
}

//MARK: - Search Bar Methods

extension ToDoListViewController: UISearchBarDelegate
{
    func createRequest(searchText:String)->(NSFetchRequest<Item>,NSPredicate)
    {
        let request : NSFetchRequest<Item> = Item.fetchRequest()
        
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
        
        
        
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return (request,predicate)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
//        let request : NSFetchRequest<Item> = Item.fetchRequest()
//        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
//        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
//        loadItems(with: request)
        let result = createRequest(searchText:searchBar.text!)
        loadItems(with: result.0, predicate: result.1)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        if(searchBar.text?.count == 0)
        {
            loadItems()
            DispatchQueue.main.async
            {
                searchBar.resignFirstResponder()
            }
        }
        else
        {
            let result = createRequest(searchText:searchBar.text!)
            loadItems(with: result.0, predicate: result.1)
        }
    }
}
