//
//  NotesViewController.swift
//  To-DoList
//

import UIKit
import CoreData

class NotesViewController: UIViewController
{
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var noteTextView: UITextView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var globalNote:Notes? = nil
    var globalNoteText:String? = nil
    var isNew = true
    
    var selectedCategory = Category()//Value passed from prev. View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUpdateNotes()
        setContent()
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        
        noteTextView.addGestureRecognizer(swipe)
    }
    
    func setContent() {
        titleTextView.text = selectedCategory.name
        if(globalNote != nil)
        {
            if let note = globalNote?.note
            {
                noteTextView.text = note
            }
        }
    }
    
    //MARK: - UIbutton functions
    
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        let newNote = Notes(context: self.context)
        
        if(isNew) {
            newNote.parentCategory = self.selectedCategory
            newNote.note = noteTextView.text
            isNew = false
            
            self.saveNotes()
        }
        else {
            loadUpdateNotes(isUpdate:true)
        }
    }
    
    @IBAction func btnCancelTapped(_ sender: UIButton) {
        noteTextView.text = globalNote?.note
    }
    
    @IBAction func btnDeleteTapped(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "", message: "Are you sure you want to delete the note", preferredStyle: .alert)

        let action = UIAlertAction(title: "Yes", style: .default) { (action) in
            
            //Delete the row from the data source
            if self.globalNote != nil
            {
                self.context.delete(self.globalNote!)
                self.saveNotes()
                self.noteTextView.text = nil
            }
        }
        
        let cancel = UIAlertAction(title: "No", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnExitTapped(_ sender: UIButton)
    {
        navigationController?.popViewController(animated: true)
    }
    //MARK: - Model Manipulation Methods
    
    func saveNotes()
    {
        if context.hasChanges
        {
            do
            {
                try context.save()
            }
            catch
            {
                print("Error saving notes:\(error)")
            }
        }
    }
    
    func loadUpdateNotes(with request: NSFetchRequest<Notes> = Notes.fetchRequest(), predicate: NSPredicate? = nil, isUpdate:Bool = false)
    {
        if(isUpdate == false)
        {
            request.predicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory.name!)
            do
            {
                let notes = try context.fetch(request)
                if(notes.count>0)
                {
                    isNew = false
                    globalNote = notes[0]
                }
            }
            catch
            {
                print("Error fetching data from context:\(error)")
            }
        }
        else
        {
            globalNote?.setValue(noteTextView.text, forKey: "note")
            saveNotes()
        }
    }
    
    //MARK: - Dismiss the keyboard
    
    @objc func DismissKeyboard()
    {
        //Causes the view to resign from the status of first responder.
        noteTextView.resignFirstResponder()
    }
}
