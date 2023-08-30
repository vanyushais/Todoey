
import UIKit
import RealmSwift
import ChameleonFramework

class CategoryViewController: SwipeTableViewController {
    
    let realm = try! Realm()

    var categories: Results<Category>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        загрузка категорий из памяти
        loadCategories()
        tableView.separatorStyle = .none
        
        }
    
    override func viewWillAppear(_ animated: Bool) {

        guard let navBar = navigationController?.navigationBar else {fatalError("Контроллер навигации не существует!")}

        navBar.backgroundColor = UIColor(hexString: "#1D9BF6")
    }
    
    //MARK: - TableView Datasourse Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//             Nill Coalescing Operator
        return categories?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        cell.textLabel?.text = categories?[indexPath.row].name ?? "Нет добавленных категорий"
        
        if let category = categories?[indexPath.row] {
            
            guard let categoryColour = UIColor(hexString: category.colour) else {fatalError()}
            
            //        меняем цвет заднего фона              у каждой ячейки которая существует иначе дефолтный цвет приложения
            cell.backgroundColor = categoryColour
            cell.textLabel?.textColor = ContrastColorOf(categoryColour, returnFlat: true)
        }
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToItems", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categories?[indexPath.row]
        }
    }
    
    //MARK: - Data Manipulation Methods
    
    func save(category: Category) {
        
        do {
            try realm.write {
                realm.add(category)
            }
        } catch {
           print("Ошибка сохранения категории: \(error)")
        }
        
        self.tableView.reloadData()
    }
    
    func loadCategories() {
        
        categories = realm.objects(Category.self)
        
        tableView.reloadData()
    }
    
    //MARK: - Delete Data Frome Swipe
    
    override func updateModel(at indexPath: IndexPath) {
        
        if let categoryForDeletion = self.categories?[indexPath.row] {
            
            do{
                try self.realm.write {
                    self.realm.delete(categoryForDeletion)
                }
            } catch {
                print("Ошибка удаления категории: \(error.localizedDescription)")
            }
        }
    }
    
   
    //MARK: - Add New Categories
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Добавить новую категорию", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Добавить", style: .default) { action in
            
            let newCategory = Category()
            newCategory.name = textField.text!
            newCategory.colour = UIColor.randomFlat().hexValue()
//            сохранение новых элементов в память
            self.save(category: newCategory)
            
        }
        
//        создание новой категории
        alert.addAction(action)
        alert.addTextField { field in
            textField = field
            textField.placeholder = "Название новой категории"
        }
        present(alert, animated: true, completion: nil)
    }
}
