
import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    var todoItems: Results<Item>?
    let realm = try! Realm()
    @IBOutlet weak var searchBar: UISearchBar!
    
    var selectedCategory : Category? {
        didSet {
//        загрузка элементов из памяти
            loadItems()
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let colourHex = selectedCategory?.colour {
            
            title = selectedCategory!.name
            
            guard let navBar = navigationController?.navigationBar else {fatalError("Контроллер навигации не существует!")}
            
            if let navBarColour = UIColor(hexString: colourHex) {
                
                navBar.backgroundColor = navBarColour
                
                navBar.tintColor = ContrastColorOf(navBarColour, returnFlat: true)
                
                navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColour, returnFlat: true)]
                
                searchBar.barTintColor = navBarColour
            }
            
            
        }
    }
    
    //MARK: - Tableview Datasourse Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row] {
            
            cell.textLabel?.text = item.title
//            градиент ячеек                                    в зависимости от их количества
            if let colour = UIColor(hexString: selectedCategory!.colour)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(todoItems!.count)) {
                cell.backgroundColor = colour
//                контрастный текст
                cell.textLabel?.textColor = ContrastColorOf(colour, returnFlat: true)
            }
            
//        ставить и убирать галочку при нажатии на задачу
//      проверка условия: если это true, то ставится это, если нет, то это
            cell.accessoryType = item.done ? .checkmark : .none
        } else {
            cell.textLabel?.text = "Нет добавленных элементов"
        }
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        

        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
//        удаление элементов по нажатию
//                    realm.delete(item)
//        значение для галочки поставлена или нет
                    item.done = !item.done
                }
            } catch {
                print("Ошибка сохранения статуса выполнения \(error)")
            }
        }
        
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Добавить новую задачу", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Добавить элемент", style: .default) { action in
//            Новая задача добавится в массив с задачами и сохранится
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                } catch {
                    print("Ошибка сохранения новых элементов \(error)")
                }
            }
            self.tableView.reloadData()
        }
        //        создание нового элемента
        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Создать новый элемент"
            textField = alertTextField
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
    }
    
    //MARK: - Model Manupulation Methods
    
     func loadItems() {
         
         todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
       
        tableView.reloadData()
    }
    
    //MARK: - Delete Data Frome Swipe
    
    override func updateModel(at indexPath: IndexPath) {
        
        if let itemForDeletion = todoItems?[indexPath.row] {
            
            do {
                try realm.write {
                    realm.delete(itemForDeletion)
                }
            } catch {
                print("Ошибка удаления категории: \(error.localizedDescription)")
            }
        }
    }
     
}

//MARK: - Search Bar Methods

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
//        проверяет запрос поиска         результат включает запрос              сортировка         по дате      в алфавитном порядке
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated"/*"title"*/, ascending: true)
        tableView.reloadData()
        
        
    }
//    начинает поиск с каждым введённым символом
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
//            скрывает клавиатуру и убирает курсор со строки поиска
                searchBar.resignFirstResponder()
            }
        }
    }
}
