import '../dao/task_dao.dart';
import '../models/task.dart';

class TaskService {
  final TaskDao _dao = TaskDao();

  Future<List<Task>> getAllTasks() {
    return _dao.getAllTasks();
  }

  Future<void> addTask(Task t) {
    return _dao.insertTask(t);
  }

  Future<void> updateTask(Task t) {
    return _dao.updateTask(t);
  }

  Future<void> deleteTask(int id) {
    return _dao.deleteTask(id);
  }

  Future<Task?> getTaskById(int id) {
    return _dao.getTaskById(id);
  }
}
